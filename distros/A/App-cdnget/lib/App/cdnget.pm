package App::cdnget;
=head1 NAME

App::cdnget - CDN Reverse Proxy

=head1 VERSION

version 0.06

=head1 ABSTRACT

CDN Reverse Proxy

=head1 DESCRIPTION

p5-cdnget is a FastCGI application that flexible pull-mode Content Delivery Network reverse proxy.

B<This is ALPHA version>

=cut
### TODO: css, js minifier.
BEGIN
{
	require Config;
	if ($Config::Config{'useithreads'})
	{
		require threads;
		threads->import();
		require threads::shared;
		threads::shared->import();
	} else
	{
		require forks;
		forks->import();
		require forks::shared;
		forks::shared->import();
	}
}
use strict;
use warnings;
use v5.14;
use utf8;
use Time::HiRes qw(sleep usleep);
use DateTime;
use Lazy::Utils;

use App::cdnget::Exception;
use App::cdnget::Worker;
use App::cdnget::Downloader;


BEGIN
{
	require Exporter;
	our $VERSION     = '0.06';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw(main run);
	our @EXPORT_OK   = qw();
}


our $DTF_RFC822 = "%a, %d %b %Y %T %Z";
our $DTF_RFC822_GMT = "%a, %d %b %Y %T GMT";
our $DTF_YMDHMS = "%F %T";
our $DTF_YMDHMS_Z = "%F %T %z";
our $DTF_SYSLOG = "%b %e %T";
our $CHUNK_SIZE = 256*1024;

my $terminating :shared = 0;
my $terminating_force :shared = 0;


sub log_info
{
	my ($msg) = @_;
	$msg = "Unknown" unless $msg;
	my $dts = DateTime->now(time_zone => POSIX::strftime("%z", localtime), locale => "en")->strftime('%x %T %z');
	$msg = "[$dts] $msg";
	say $msg;
}

sub main
{
	log_info "Starting p5-cdnget/${App::cdnget::VERSION}";
	eval
	{
		my $cmdargs = commandArgs({ valuableArgs => 1, noCommand => 1 }, @_);
		my $spares = $cmdargs->{"--spares"};
		$spares = 1 unless defined($spares) and $spares >= 1;
		my $maxWorkers = $cmdargs->{"--max-workers"};
		$maxWorkers = $spares+1 unless defined($maxWorkers) and $maxWorkers > $spares;
		my $cachePath = $cmdargs->{"--cache-path"};
		$cachePath = "/tmp/cdnget" unless defined($cachePath);
		my $addr = $cmdargs->{"--addr"};
		$addr = "" unless defined($addr);
		App::cdnget::Worker::init($spares, $maxWorkers, $cachePath, $addr);
		App::cdnget::Downloader::init($maxWorkers*10);
		$SIG{INT} = $SIG{TERM} = sub
		{
			terminate();
		};
		log_info "Started ".
			"spares=$spares ".
			"max-workers=$maxWorkers ".
			"cache-path=\"".shellmeta($cachePath)."\" ".
			"addr=\"".shellmeta($addr)."\"";
		while (not App::cdnget::Worker::terminated() or not App::cdnget::Downloader::terminated())
		{
			eval { App::cdnget::Worker->new() };
			warn $@ if $@;
		}
		App::cdnget::Worker::final();
		App::cdnget::Downloader::final();
	};
	if ($@)
	{
		warn $@;
	}
	usleep(100*1000);
	log_info "Terminated p5-cdnget/${App::cdnget::VERSION}";
	return 0;
}

sub run
{
	return main(@ARGV);
}

sub terminate
{
	do
	{
		lock($terminating);
		if ($terminating)
		{
			log_info "Terminating...";
			lock($terminating_force);
			$terminating_force = 1;
			return 0;
		}
		$terminating = 1;
	};
	log_info "Terminating gracefully...";
	async { App::cdnget::Worker::terminate() }->detach();
	async { App::cdnget::Downloader::terminate() }->detach();
	return 1;
}


1;
__END__
=head1 INSTALLATION

To install this module type the following

	perl Makefile.PL
	make
	make test
	make install

from CPAN

	cpan -i App::cdnget

=head1 DEPENDENCIES

This module requires these other modules and libraries:

=over

=item *

threads

=item *

threads::shared

=item *

forks

=item *

SUPER

=item *

Thread::Semaphore

=item *

Time::HiRes

=item *

DateTime

=item *

FCGI

=item *

Digest::SHA

=item *

LWP::UserAgent

=item *

GD

=item *

Lazy::Utils

=item *

Object::Base

=back

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
