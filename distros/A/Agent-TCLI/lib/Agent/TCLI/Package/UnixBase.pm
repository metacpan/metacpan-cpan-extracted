package Agent::TCLI::Package::UnixBase;
#
# $Id: UnixBase.pm 59 2007-04-30 11:24:24Z hacker $
#
=head1 NAME

Agent::TCLI::Package::UnixBase - Base class for Agent::TCLI::Package
objects accessing other Unix commands.

=head1 SYNOPSIS

	use Object::InsideOut qw(Agent::TCLI::Package::UnixBase);

=head1 DESCRIPTION

Base class for Packages needing to run other Unix programs. It provides methods
to asnychronously call Unix programs using POW::Wheel::Run through
POE::Component::Child. This base class comes with simple
event handlers to accept the output and/or errors returned from the wheel.

Typically, one may want their subclass to replace the stdout method
with one that does more processing of the responses. One should use the
methods here as a starting point in such cases.

Commands run through these methods are run in their own processes asychonously.
Other Agent processing continues while the results of the commands are
captured and returned. Package authors need to ensure that their command
threads shut down or else they may exhaust system resources.

=head1 INTERFACE

=cut

use warnings;
use strict;
use Carp;
use Object::InsideOut qw(Agent::TCLI::Package::Base);

use POE qw(Component::Child Filter::Stream);

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: UnixBase.pm 59 2007-04-30 11:24:24Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard accessor/mutator
methods unless otherwise noted.

=over

=item child

This holds the POE::Component::Child session to use for running
command line requests. A package will typically use this attribute in a chain
to acceess POE::Component::Child methods. For instance, to run a command one
uses:

	my $wheel = $self->child->run('who');

=cut
my @child			:Field
#					:Type('type')
					:All('child');


# Standard class utils are inherited

=back

See Agent::TCLI::Package::Base for other attributes applicable to Packages.

=head2 METHODS

These simple methods may be used as is, or subclasses may use them as
starting point.

=over

=item RunWheelStart

This initializes the POE::Component::Child session. It may be called
from a Package's _start routine or the contents may be copied for further
modification.

=cut

sub RunWheelStart {
	my $self = shift;

	$self->child( POE::Component::Child->new(
		alias => $self->name,
#		debug => $self->verbose,
	));

#	$self->child->{'StdioFilter'} = POE::Filter::Stream->new;
}

=item stdout

This POE event handler is the default way stdout lines are returned from
the child command being run.

=cut

sub stdout {
    my ($kernel,  $self, $child, $resp) =
      @_[KERNEL, OBJECT,   ARG0,  ARG1];
	$self->Verbose("stdout: wheel_id(".$resp->{'wheel'}.") ",1);

    my $request = $self->GetWheelKey( $resp->{'wheel'}, 'request' );
	my $output = $resp->{'out'};

	unless ( ref($request) =~ qr(Request) )
	{
		$self->Verbose("stdout: wid(".$resp->{'wheel'}.")no request for output($output)",0);
		return;
	}
	$self->Verbose("stdout: rid (".$request->id.")  wid(".$resp->{'wheel'}.")" );

	$request->Respond( $kernel, $output, 200);
}

=item stderr

This POE event handler is the default way stderr lines are returned from
the child command being run.

=cut

sub stderr {
    my ($kernel,  $self, $child, $resp) =
      @_[KERNEL, OBJECT,   ARG0,  ARG1];
	$self->Verbose("stderr: wheel_id(".$resp->{'wheel'}.") ",1);

    my $request = $self->GetWheelKey( $resp->{'wheel'}, 'request' );

	my $output = "STDERR: ".$resp->{'out'}." !!! ";

	$request->Respond( $kernel, $output, 400);
}

=item error

This POE event handler is the default way errors are returned from
the child command being run.

=cut

sub error {
    my ($kernel,  $self, $operation, $errnum, $errstr, $wheel_id) =
      @_[KERNEL, OBJECT,       ARG0,    ARG1,    ARG2,     ARG3];

    $errstr = "remote end closed" if $operation eq "read" and !$errnum;
	my $output = "Wheel $wheel_id generated $operation error $errnum: $errstr\n";

	$self->Verbose("error: output($output)",2);
    my $request = $self->GetWheelKey( $wheel_id, 'request' );

	$request->Respond( $kernel, $output, 400) if defined($request);
}

=item done

This POE event handler is the default way a child indicates that it is
done.

=cut

sub done {
    my ($self, $child, $resp) = @_[OBJECT, ARG0, ARG1];
#    my $child = $self->GetWheel( $resp->id );
    $self->Verbose( "done: wheel (".$resp->{'wheel'}." ) has finished.");
    #remove wheel reference
	$self->SetWheel($resp->{'wheel'});
}

1;

=back

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from
Agent::TCLI::Package::Base. It inherits methods from both.
Please refer to their documentation for more details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

SHOULDS and MUSTS are currently not enforced.

Test scripts not thorough enough.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
