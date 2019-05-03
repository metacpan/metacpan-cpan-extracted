package Anansi::Script::SOAP;


=head1 NAME

Anansi::Script::SOAP - Defines the mechanisms specific to handling SOAP.

=head1 SYNOPSIS

    my $OBJECT = Anansi::Script::SOAP->new();

=head1 DESCRIPTION

This module is designed to be an optional component module for use by the
L<Anansi::Script> component management module.  It defines the processes
specific to handling both input and output from Perl scripts that are executed
by a web server using the Simple Object Access Protocol.  Uses
L<Anansi::ComponentManager> I<(indirectly)>, L<Anansi::ScriptComponent> and
L<base>.

=cut


our $VERSION = '0.04';

use base qw(Anansi::ScriptComponent);

use CGI;


=head1 INHERITED METHODS

=cut


=head2 addChannel

Declared in L<Anansi::Component>.

=cut


=head2 channel

Declared in L<Anansi::Component>.

=cut


=head2 componentManagers

Declared in L<Anansi::Component>.

=cut


=head2 finalise

    $OBJECT->SUPER::finalise();

Declared in L<Anansi::Class>.  Overridden by this module.

=cut


sub finalise {
    my ($self, %parameters) = @_;
    $self->used('CGI');
}


=head2 implicate

Declared in L<Anansi::Class>.  Intended to be overridden by an extending module.

=cut


=head2 import

Declared in L<Anansi::Class>.

=cut


=head2 initialise

    $OBJECT->SUPER::initialise();

Declared in L<Anansi::Class>.  Overridden by this module.

=cut


sub initialise {
    my ($self, %parameters) = @_;
    my $CGI = CGI->new();
    $self->uses(
        CGI => $CGI,
    );
    $self->loadParameters(%parameters);
}


=head2 old

Declared in L<Anansi::Class>.

=cut


=head2 removeChannel

Declared in L<Anansi::Component>.

=cut


=head2 used

Declared in L<Anansi::Class>.

=cut


=head2 uses

Declared in L<Anansi::Class>.

=cut


=head1 METHODS

=cut


=head2 loadParameters

    $OBJECT->loadParameters();

Loads all of the CGI parameters supplied upon page REQUEST.

=cut


sub loadParameters {
    my ($self, %parameters) = @_;
    $self->{PARAMETERS} = {} if(!defined($self->{PARAMETERS}));
    foreach my $name ($self->{CGI}->param()) {
        ${$self->{PARAMETERS}}{$name} = $self->{CGI}->param($name);
    }
}


=head2 medium

    my $medium = Anansi::Script::SOAP->medium();

    my $medium = $OBJECT->medium();

    my $medium = $OBJECT->channel('MEDIUM');

Returns the STRING description of the medium this module is designed to handle.

=cut


sub medium {
    my $self = shift(@_);
    my $channel;
    $channel = shift(@_) if(0 < scalar(@_));
    return 'SOAP';
}

Anansi::ScriptComponent::addChannel('Anansi::Script::SOAP', 'MEDIUM' => 'medium');


=head2 parameter

    my $parameters = $OBJECT->parameter();

    my $parameters = $OBJECT->channel('PARAMETER');

    my $parameterValue = $OBJECT->parameter(undef, 'parameter name');

    my $parameterValue = $OBJECT->channel('PARAMETER', 'parameter name');

    if($OBJECT->parameter(undef, 'parameter name' => 'parameter value', 'another parameter' => undef));

    if($OBJECT->channel('PARAMETER', 'parameter name' => 'parameter value', 'another parameter' => undef));

Either returns an ARRAY of all the existing parameter names or returns the value
of a specific parameter or sets the value of one or more parameters.  Assigning
an "undef" value has the effect of deleting the parameter.

=cut


sub parameter {
    my $self = shift(@_);
    my $channel;
    $channel = shift(@_) if(0 < scalar(@_));
    if(0 == scalar(@_)) {
        return [] if(!defined($self->{PARAMETERS}));
        return [( keys(%{$self->{PARAMETERS}}) )];
    } elsif(1 == scalar(@_)) {
        my $name = shift(@_);
        return if(!defined($self->{PARAMETERS}));
        return if(!defined(${$self->{PARAMETERS}}{$name}));
        return ${$self->{PARAMETERS}}{$name};
    } elsif(1 == scalar(@_) % 2) {
        return 0;
    }
    my ($name, %parameters) = @_;
    foreach my $name (keys(%parameters)) {
        if(defined(${$self->{PARAMETERS}}{$name})) {
            ${$self->{PARAMETERS}}{$name} = $parameters{$name};
        } else {
            delete(${$self->{PARAMETERS}}{$name});
        }
    }
    return 1;
}

Anansi::ScriptComponent::addChannel('Anansi::Script::SOAP', 'PARAMETER' => 'parameter');


=head2 priority

    my $priority = Anansi::Script::SOAP->priority();

    my $priority = $OBJECT->priority();

    my $priority = $OBJECT->channel('PRIORITY_OF_VALIDATE');

Returns a hash of the priorities of this script component in relation to other
script components.  Each priority is represented by a component namespace in the
form of a key and a value of B<lower>, B<-1> I<(minus one)> or any negative
value implying this component is of higher priority, B<higher>, B<1> I<(one)> or
any positive value implying this component is of lower priority or B<same> or
B<0> I<(zero)> implying this component is of the same priority.

=cut


sub priority {
    my $self = shift(@_);
    my $channel;
    $channel = shift(@_) if(0 < scalar(@_));
    my $priorities = {
        'Anansi::Script::CGI' => 'lower',
        'Anansi::Script::Shell' => 'lower',
    };
    return $priorities;
}

Anansi::ScriptComponent::addChannel('Anansi::Script::SOAP', 'PRIORITY_OF_VALIDATE' => 'priority');


=head2 validate

    my $valid = $OBJECT->validate();

    my $valid = $OBJECT->channel('VALIDATE_AS_APPROPRIATE');

Determines whether this module is the correct one to use for handling Perl
script execution.

=cut


sub validate {
    my ($self, %parameters) = @_;
    my $channel;
    $channel = shift(@_) if(0 < scalar(@_));
    return 0 if(!defined($ENV{'HTTP_HOST'}));
    my $CGI = CGI->new();
    return 1 if(defined($CGI->http('SOAPAction')));
    return 0 if(!defined($CGI->http('Content-Type')));
    return 0 if($CGI->http('Content-Type') !~ /^application\/soap\+xml(;.*)?$/i);
    return 1;
}

Anansi::ScriptComponent::addChannel('Anansi::Script::SOAP', 'VALIDATE_AS_APPROPRIATE' => 'validate');


=head1 NOTES

This module is designed to make it simple, easy and quite fast to code your
design in perl.  If for any reason you feel that it doesn't achieve these goals
then please let me know.  I am here to help.  All constructive criticisms are
also welcomed.

=cut


=head1 AUTHOR

Kevin Treleaven <kevin I<AT> treleaven I<DOT> net>

=cut


1;

