
package Daemon::Generic::AnyEvent;

use strict;
use warnings;
require Daemon::Generic;
require AnyEvent;
require Exporter;

our @ISA = qw(Daemon::Generic Exporter);
our @EXPORT = @Daemon::Generic::EXPORT;
our $VERSION = 0.84;

sub newdaemon
{
	local($Daemon::Generic::caller) = caller() || 'main';
	local($Daemon::Generic::package) = __PACKAGE__;
	Daemon::Generic::newdaemon(@_);
}

sub gd_setup_signals
{
	my $self = shift;

	$self->{gd_reload_event} = AnyEvent->signal(
		signal	=> 'HUP',
		cb	=> sub { 
			$self->gd_reconfig_event; 
			$self->{gd_timer}->cancel()
				if $self->{gd_timer};
			$self->gd_setup_timer();
		},
	);
	$self->{gd_quit_event} = AnyEvent->signal(
		signal	=> 'INT',
		cb	=> sub { $self->gd_quit_event; },
	);
}

sub gd_setup_timer
{
	my $self = shift;
	if ($self->can('gd_run_body')) {
		my $interval = ($self->can('gd_interval') && $self->gd_interval()) || 1;
		$self->{gd_timer} = AnyEvent->timer(
			cb		=> sub { $self->gd_run_body() },
			interval	=> $interval,
		);
	}
}

sub gd_run
{
	my $self = shift;
	$self->gd_setup_timer();
	Event::loop();
}

sub gd_quit_event
{
	my $self = shift;
	print STDERR "Quitting...\n";
	Event::unloop_all();
}

1;

=head1 NAME

 Daemon::Generic::AnyEvent - Generic daemon framework with AnyEvent.pm

=head1 SYNOPSIS

 use Daemon::Generic::AnyEvent;
 use Some::Event::Loop::Supported::By::AnyEvent;

 @ISA = qw(Daemon::Generic::AnyEvent);

 sub gd_preconfig {
	# stuff
 }

=head1 DESCRIPTION

Daemon::Generic::AnyEvent is a subclass of L<Daemon::Generic> that
predefines some methods:

=over 15

=item gd_run()

Setup a periodic callback to C<gd_run_body()> if there is a C<gd_run_body()>.
Call C<Event::loop()>.  

=item gd_setup_signals()

Bind SIGHUP to call C<gd_reconfig_event()>. 
Bind SIGINT to call C<gd_quit_event()>.

=back

To use Daemon::Generic::Event, you have to provide a C<gd_preconfig()>
method.   It can be empty if you have a C<gd_run_body()>.

Set up your own events in C<gd_preconfig()> and C<gd_postconfig()>.

If you have a C<gd_run_body()> method, it will be called once per
second or every C<gd_interval()> seconds if you have a C<gd_interval()>
method.  Unlike in L<Daemon::Generic::While1>, C<gd_run_body()> should
not include a call to C<sleep()>.

=head1 LICENSE

Copyright (C) 2006-2010 David Muir Sharnoff <muir@idiom.com>. 
Copyright (C) 2011 Google, Inc.
This module may be used and distributed on the same terms
as Perl itself.

