# mamgal - a program for creating static image galleries
# Copyright 2007, 2008 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# An output formatting class, for creating the actual index files from some
# contents
package App::MaMGal::MplayerWrapper;
use strict;
use warnings;
use base 'App::MaMGal::Base';
use Carp;
use File::Temp 'tempdir';
use App::MaMGal::Exceptions;

sub init
{
	my $self = shift;
	my $cc = shift or croak 'Arg required: command checker';
	$cc->isa('App::MaMGal::CommandChecker') or croak 'Arg must be a CommandChecker';
	croak "Just one argument allowed" if @_;
	eval {
		$self->{tempdir} = tempdir(CLEANUP => 1);
	}; if ($@) {
		App::MaMGal::SystemException->throw(message => 'Temporary directory creation failed: %s.', objects => [$@]);
	}
	$self->{cc} = $cc;
}

sub run_mplayer
{
	my $self = shift;
	my $film_path = shift;
	my $dir = $self->{tempdir};
	my $pid = fork;
	if (not defined $pid) {
		App::MaMGal::MplayerWrapper::ExecutionFailureException->throw("Fork failed: $!");
	} elsif ($pid == 0) {
		# Child
		open(STDOUT, ">${dir}/stdout") or App::MaMGal::MplayerWrapper::ExecutionFailureException->throw("Cannot open \"${dir}/stdout\" for writing: $!");
		open(STDERR, ">${dir}/stderr") or App::MaMGal::MplayerWrapper::ExecutionFailureException->throw("Cannot open \"${dir}/stderr\" for writing: $!");
		my @cmd = ('mplayer', $film_path, '-noautosub', '-nosound', '-vo', "jpeg:quality=100:outdir=${dir}", '-frames', '2');
		{ # own scope to prevent a compile-time warning
		exec(@cmd);
		}
		App::MaMGal::MplayerWrapper::ExecutionFailureException->throw("Cannot run mplayer: $!");
	} else {
		# Parent
		waitpid($pid, 0);
		App::MaMGal::MplayerWrapper::ExecutionFailureException->throw("Mplayer failed ($?).", $self->_read_messages) if $? != 0;
	}
}

sub _read_log
{
	my $self = shift;
	my $name = shift;
	my $dir = $self->{tempdir};
	open(F, "<${dir}/$name") or App::MaMGal::MplayerWrapper::ExecutionFailureException->throw("Cannot open \"${dir}/$name\" for reading: $!");
	my @ret = <F>;
	close(F) or App::MaMGal::MplayerWrapper::ExecutionFailureException->throw("Cannot close \"${dir}/$name\": $!");
	chomp @ret;
	return \@ret;
}

sub _read_messages
{
	my $self = shift;
	return map { $_ => $self->_read_log($_) } qw(stdout stderr);
}

sub snapshot
{
	my $self = shift;
	$self->{available} = $self->{cc}->is_available('mplayer') unless exists $self->{available};
	App::MaMGal::MplayerWrapper::NotAvailableException->throw unless $self->{available};
	my $film_path = shift or croak "snapshot needs an arg: path to the film";
	-r $film_path or App::MaMGal::SystemException->throw(message => '%s: not readable', objects => [$film_path]);
	my $dir = $self->{tempdir};
	$self->run_mplayer($film_path);
	my $img = Image::Magick->new;
	if (my $r = $img->Read("${dir}/00000001.jpg")) {
		App::MaMGal::MplayerWrapper::ExecutionFailureException->throw(message => "Could not read the snapshot produced by mplayer: $r", $self->_read_messages);
	}
	$self->cleanup;
	return $img;
}

sub cleanup
{
	my $self = shift;
	my $path = $self->{tempdir};
	opendir my $d, $path or App::MaMGal::MplayerWrapper::ExecutionFailureException->throw("Cannot open \"$path\" to clean up after mplayer");
	my @files = readdir $d;
	closedir $d;
	# This assumes that mplayer did not create any directories.
	unlink(map($path.'/'.$_, @files));
}

1;
