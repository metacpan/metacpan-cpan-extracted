package Anansi::Script::SOAP;


=head1 NAME

Anansi::Script::SOAP - Defines the mechanisms specific to handling SOAP.

=head1 SYNOPSIS

 my $OBJECT = Anansi::Script::SOAP->new();

=head1 DESCRIPTION

This module is designed to be an optional component module for use by the
L<Anansi::Script> component management module.  It defines the processes
specific to handling both input and output from Perl scripts that are executed
by a web server using the Simple Object Access Protocol.  See
L<Anansi::Component> for inherited methods.

=cut


our $VERSION = '0.02';

use base qw(Anansi::Component);

use CGI;


=head1 METHODS

=cut


=head2 finalise

 $OBJECT::SUPER->finalise(@_);

An overridden virtual method called during object destruction.  Not intended to
be directly called unless overridden by a descendant.

=cut


sub finalise {
    my ($self, %parameters) = @_;
    $self->used('CGI');
}


=head2 initialise

 $OBJECT::SUPER->initialise(@_);

An overridden virtual method called during object creation.  Not intended to be
directly called unless overridden by a descendant.

=cut


sub initialise {
    my ($self, %parameters) = @_;
    my $CGI = CGI->new();
    $self->uses(
        CGI => $CGI,
    );
    $self->loadParameters(%parameters);
}


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

 # OR

 my $medium = $OBJECT->medium();

 # OR

 my $medium = $OBJECT->channel('MEDIUM');

Returns the STRING description of the medium this module is designed to handle.

=cut


sub medium {
    my $self = shift(@_);
    my $channel;
    $channel = shift(@_) if(0 < scalar(@_));
    return 'SOAP';
}

Anansi::Component::addChannel('Anansi::Script::SOAP', 'MEDIUM' => 'medium');


=head2 parameter

 my $parameters = $OBJECT->parameter();

 # OR

 my $parameters = $OBJECT->channel('PARAMETER');

 # OR

 my $parameterValue = $OBJECT->parameter(undef, 'parameter name');

 # OR

 my $parameterValue = $OBJECT->channel('PARAMETER', 'parameter name');

 # OR

 if($OBJECT->parameter(undef, 'parameter name' => 'parameter value', 'another parameter' => undef));

 # OR

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

Anansi::Component::addChannel('Anansi::Script::SOAP', 'PARAMETER' => 'parameter');


=head2 validate

 my $valid = $OBJECT->validate();

 # OR

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
    # Check the HTTP_SOAPACTION environment variable.
    return 0 if(!defined($CGI->http('SOAPAction')));
    return 1;
}

Anansi::Component::addChannel('Anansi::Script::SOAP', 'VALIDATE_AS_APPROPRIATE' => 'validate');


=head1 AUTHOR

Kevin Treleaven <kevin AT treleaven DOT net>

=cut


1;
