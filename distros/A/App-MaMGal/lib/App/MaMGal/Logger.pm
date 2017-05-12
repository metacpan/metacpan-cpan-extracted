# mamgal - a program for creating static image galleries
# Copyright 2007-2009 Marcin Owsiany <marcin@owsiany.pl>
# See the README file for license information
# A logging subsystem class
package App::MaMGal::Logger;
use strict;
use warnings;
use base 'App::MaMGal::Base';
use Carp;

sub init
{
	my $self = shift;
	my $fh = shift or croak "filehandle arg required";
	$self->{fh} = $fh;
}

sub log_message
{
	my $self = shift;
	my $msg = shift;
	my $prefix = shift || '';
	$prefix .= ': ' if $prefix;
	$self->{fh}->printf("%s%s\n", $prefix, $msg);
}

our $not_available_warned_before = 0;
our $exe_failure_warned_before = 0;

sub log_exception
{
	my $self = shift;
	my $e = shift;
	my $prefix = shift;
	if ($e->isa('App::MaMGal::MplayerWrapper::NotAvailableException')) {
		# TODO this needs to be made thread-safe
		return if $not_available_warned_before;
		$not_available_warned_before = 1;
	} elsif ($e->isa('App::MaMGal::MplayerWrapper::ExecutionFailureException')) {
		# TODO this needs to be made thread-safe
		goto JUST_LOG if $exe_failure_warned_before or (! $e->stdout and ! $e->stderr);
		$exe_failure_warned_before = 1;
		$self->log_message($e->message, $prefix);
		$self->log_message('--------------------- standard output messages -------------------', $prefix);
		$self->log_message($_, $prefix) for $e->stdout ? @{$e->stdout} : ();
		$self->log_message('--------------------- standard error messages --------------------', $prefix);
		$self->log_message($_, $prefix) for $e->stderr ? @{$e->stderr} : ();
		$self->log_message('------------------------------------------------------------------', $prefix);
		return;
	} elsif ($e->isa('App::MaMGal::SystemException')) {
		$self->log_message($e->interpolated_message);
		return;
	}
JUST_LOG:
	$self->log_message($e->message, $prefix);
}

1;
