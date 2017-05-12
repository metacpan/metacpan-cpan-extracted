package App::cdnget::Worker;
use Object::Base;
use v5.14;
use bytes;
use IO::Handle;
use FileHandle;
use Time::HiRes qw(sleep usleep);
use Thread::Semaphore;
use FCGI;
use Digest::MD5;

use App::cdnget;
use App::cdnget::Exception;
use App::cdnget::Downloader;


BEGIN
{
	our $VERSION     = '0.05';
}


my $maxCount;
my $spareCount;
my $addr = 0;
my $cachePath;

my $terminating :shared = 0;
my $terminated :shared = 0;
my $workerSemaphore :shared;
my $spareSemaphore :shared;
my $accepterSemaphore :shared;
my $accepterCount :shared = 0;
my $socket = 0;


attributes qw(:shared tid);


sub init
{
	my ($_spareCount, $_maxCount, $_cachePath, $_addr) = @_;
	$spareCount = $_spareCount;
	$maxCount = $_maxCount;
	$cachePath = $_cachePath;
	$cachePath = substr($cachePath, 0, length($cachePath)-1) while $cachePath and substr($cachePath, -1) eq "/";
	$addr = $_addr;
	$workerSemaphore = Thread::Semaphore->new($maxCount) or App::cdnget::Exception->throw($!);
	$spareSemaphore = Thread::Semaphore->new($spareCount) or App::cdnget::Exception->throw($!);
	$accepterSemaphore = Thread::Semaphore->new($spareCount) or App::cdnget::Exception->throw($!);
	$socket = FCGI::OpenSocket($addr, $maxCount) or App::cdnget::Exception->throw($!) if $addr;
	return 1;
}

sub final
{
	FCGI::CloseSocket($socket) if $socket;
	$socket = 0;
	return 1;
}

sub terminate
{
	do
	{
		lock($terminating);
		return 0 if $terminating;
		$terminating = 1;
	};
	App::cdnget::log_info("Workers terminating...");
	my $gracefully = 0;
	while (not $gracefully and not $App::cdnget::terminating_force)
	{
		$gracefully = $workerSemaphore->down_timed(3, $maxCount);
	}
	lock($terminated);
	$terminated = 1;
	App::cdnget::log_info("Workers terminated".($gracefully? " gracefully": "").".");
	return 1;
}

sub terminating
{
	lock($terminating);
	return $terminating;
}

sub terminated
{
	if (@_ > 0)
	{
		my $self = shift;
		lock($self);
		return defined($self->tid)? 0: 1;
	}
	lock($terminated);
	return $terminated;
}

sub new
{
	my $class = shift;
	while (not $spareSemaphore->down_timed(1))
	{
		if (terminating())
		{
			return;
		}
	}
	while (not $workerSemaphore->down_timed(1))
	{
		if (terminating())
		{
			$spareSemaphore->up();
			return;
		}
	}
	if (terminating())
	{
		$spareSemaphore->up();
		$workerSemaphore->up();
		return;
	}
	my $self = $class->SUPER();
	$self->tid = undef;
	do
	{
		lock($self);
		my $thr = threads->create(\&run, $self) or $self->throw($!);
		cond_wait($self);
		unless (defined($self->tid))
		{
			App::cdnget::Exception->throw($thr->join());
		}
		$thr->detach();
	};
	return $self;
}

sub DESTROY
{
	my $self = shift;
	$self->SUPER::DESTROY;
}

sub throw
{
	my $self = shift;
	my ($msg) = @_;
	unless (ref($msg))
	{
		$msg = "Unknown" unless $msg;
		$msg = "Worker ".
			$msg;
	}
	App::cdnget::Exception->throw($msg, 1);
}

sub worker
{
	my $self = shift;
	my ($req) = @_;
	my ($in, $out, $err) = $req->GetHandles();
	my $env = $req->GetEnvironment();

	my $id = $env->{CDNGET_ID};
	$self->throw("Invalid ID") unless defined($id);
	$id = ($id =~ /^(.*)/)[0];
	$id =~ s/^\s+|\s+$//g;
	$self->throw("Invalid ID") unless $id =~ /^\w+$/i;

	my $origin = $env->{CDNGET_ORIGIN};
	$self->throw("Invalid origin") unless defined($origin);
	$origin = ($origin =~ /^(.*)/)[0];
	$origin =~ s/^\s+|\s+$//g;
	$origin = URI->new($origin);
	$self->throw("Invalid origin scheme") unless $origin->scheme =~ /^http|https$/i;
	$origin->path(substr($origin->path, 0, length($origin->path)-1)) while $origin->path and substr($origin->path, -1) eq "/";

	my $uri = $env->{CDNGET_URI};
	$self->throw("Invalid URI") unless defined($uri);
	$uri = ($uri =~ /^(.*)/)[0];
	$uri =~ s/^\s+|\s+$//g;
	$uri = "/$uri" unless $uri and substr($uri, 0, 1) eq "/";

	my $hook = $env->{CDNGET_HOOK};
	$hook = "" unless defined($hook);
	$hook = ($hook =~ /^(.*)/)[0];
	$hook =~ s/^\s+|\s+$//g;

	my $url = $origin->scheme."://".$origin->host_port.$origin->path.$uri;
	my $digest = Digest::MD5::md5_hex("$url $hook");
	my $uid = "$id/$digest";
	my $path = "$cachePath/$id";
	mkdir($path);
	my @dirs = $digest =~ /(..)(.)$/;
	my $file = $digest;
	for (reverse @dirs)
	{
		$path .= "/$_";
		mkdir($path);
	}
	$self->throw("Cache directory not exists") unless -d $path;
	$path .= "/$file";

	my $fh;
	my $downloader;
	do
	{
		lock(%App::cdnget::Downloader::uids);
		$fh = FileHandle->new($path, "<");
		unless ($fh)
		{
			return unless App::cdnget::Downloader->new($uid, $path, $url, $hook);
			$fh = FileHandle->new($path, "<") or $self->throw($!);
		}
		$downloader = $App::cdnget::Downloader::uids{$uid};
	};
	$fh->binmode(":bytes") or $self->throw($!);

	do
	{
		local ($/, $\) = ("\r\n")x2;
		my $line;
		my $buf;
		my $empty = 1;
		while (not $self->terminating)
		{
			threads->yield();
			my $downloaderTerminated = ! $downloader || $downloader->terminated;
			$line = $fh->getline;
			unless (defined($line))
			{
				$self->throw($!) if $fh->error;
				return if $downloaderTerminated;
				my $pos = $fh->tell;
				usleep(1*1000);
				$fh->seek($pos, 0) or $self->throw($!);
				next;
			}
			chomp $line;
			unless ($line =~ /^(Client\-)/i)
			{
				if (not $out->print("$line\r\n"))
				{
					not $! or $!{EPIPE} or $!{ECONNRESET} or $!{EPROTOTYPE} or $self->throw($!);
					return;
				}
				$empty = 0;
			}
			last unless $line;
		}
		while (not $self->terminating)
		{
			threads->yield();
			my $downloaderTerminated = ! $downloader || $downloader->terminated;
			my $len = $fh->read($buf, $App::cdnget::CHUNK_SIZE);
			$self->throw($!) unless defined($len);
			if ($len == 0)
			{
				return if $downloaderTerminated;
				my $pos = $fh->tell;
				usleep(1*1000);
				$fh->seek($pos, 0) or $self->throw($!);
				next;
			}
			if (not $out->write($buf, $len))
			{
				not $! or $!{EPIPE} or $!{ECONNRESET} or $!{EPROTOTYPE} or $self->throw($!);
				return;
			}
			$empty = 0;
		}
		if ($empty)
		{
			if (not $out->print("Status: 404\r\n"))
			{
				not $! or $!{EPIPE} or $!{ECONNRESET} or $!{EPROTOTYPE} or $self->throw($!);
				return;
			}
		}
	};
	return;
}

sub run
{
	my $self = shift;
	my $tid = threads->tid();

	$self->tid = $tid;
	do
	{
		lock($self);
		cond_signal($self);
	};

	my $spare = 1;
	my $accepting = 0;
	eval
	{
		my ($in, $out, $err) = (IO::Handle->new(), IO::Handle->new(), IO::Handle->new());
		my $env = {};
		my $req = FCGI::Request($in, $out, $err, $env, $socket, FCGI::FAIL_ACCEPT_ON_INTR) or $self->throw($!);

		wait_accept:
		while (not $self->terminating)
		{
			$accepterSemaphore->down_timed(1);
			do
			{
				lock($accepterCount);
				last wait_accept unless $accepterCount >= $spareCount;
			};
		}
		$spareSemaphore->up();
		$spare = 0;

		accepter_loop:
		while (not $self->terminating)
		{
			threads->yield();
			$workerSemaphore->up();
			$accepting = 1;
			my $accept;
			do
			{
				lock($accepterCount);
				$accepterCount++;
			};
			eval { $accept = $req->Accept() };
			do
			{
				lock($accepterCount);
				$accepterCount--;
			};
			$accepterSemaphore->up();
			last unless $accept >= 0;
			if ($self->terminating)
			{
				$req->Finish();
				last;
			}
			$workerSemaphore->down();
			$accepting = 0;
			eval
			{
				$self->worker($req);
			};
			do
			{
				local $@;
				$req->Finish();
			};
			if ($@)
			{
				die $@;
			}
			do
			{
				lock($accepterCount);
				last accepter_loop if $accepterCount >= $spareCount;
			};
		}
	};
	do
	{
		local $@;
		$workerSemaphore->up() unless $accepting;
		$spareSemaphore->up() if $spare;
		usleep(10*1000); #cond_wait bug
		lock($self);
		$self->tid = undef;
	};
	if ($@)
	{
		warn $@;
	}
	return;
}


1;
__END__
=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/p5-cdnget>

B<CPAN> L<https://metacpan.org/release/App-cdnget>

=head1 AUTHOR

Orkun Karaduman <orkunkaraduman@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
