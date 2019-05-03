package Anansi::Script::Shell;


=head1 NAME

Anansi::Script::Shell - Defines the mechanisms specific to handling command line execution.

=head1 SYNOPSIS

    my $OBJECT = Anansi::Script::Shell->new();

=head1 DESCRIPTION

This module is designed to be an optional component module for use by the
L<Anansi::Script> component management module.  It defines the processes
specific to handling both input and output from Perl scripts that are executed
from a command line.  Uses L<Anansi::ComponentManager> I<(indirectly)>,
L<Anansi::ScriptComponent> and L<base>.

=cut


our $VERSION = '0.05';

use base qw(Anansi::ScriptComponent);


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

    $OBJECT->Anansi::Script::Shell::finalise();

Declared in L<Anansi::Class>.  Overridden by this module.

=cut


sub finalise {
    my ($self, %parameters) = @_;
    print $self->content();
}


=head2 implicate

Declared in L<Anansi::Class>.  Intended to be overridden by an extending module.

=cut


=head2 import

Declared in L<Anansi::Class>.

=cut


=head2 initialise

    $OBJECT->SUPER::initialise();

    $OBJECT->Anansi::Script::Shell::initialise();

Declared in L<Anansi::Class>.  Overridden by this module.

=cut


sub initialise {
    my ($self, %parameters) = @_;
    $self->loadParameters(%parameters);
    $self->content();
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


=head2 content

    my $contents = $OBJECT->content();

    if(1 == $OBJECT->content(undef, undef));

    if(1 == $OBJECT->channel('CONTENT', undef));

    if(1 == $OBJECT->content(undef, 'some content'));

    if(1 == $OBJECT->channel('CONTENT', 'some content'));

Either returns the existing content or redefines the content.

=cut


sub content {
    my $self = shift(@_);
    my $channel;
    $channel = shift(@_) if(0 != scalar(@_));
    $self->{CONTENTS} = '' if(!defined($self->{CONTENTS}));
    return $self->{CONTENTS} if(0 == scalar(@_));
    my $content = shift(@_);
    return 0 if(0 < scalar(@_));
    $content = '' if(!defined($content));
    return 0 if(ref($content) !~ /^$/);
    $self->{CONTENTS} = $content;
    return 1;
}

Anansi::ScriptComponent::addChannel('Anansi::Script::Shell', 'CONTENT' => 'content');


=head2 loadParameters

    $OBJECT->loadParameters();

Loads all of the argument values from the command line, assigning any names that
are supplied to the values.

=cut


sub loadParameters {
    my ($self, %parameters) = @_;
    $self->{PARAMETERS} = {} if(!defined($self->{PARAMETERS}));
    for(my $index = 0; $index < scalar(@ARGV); $index++) {
        if($ARGV[$index] =~ /^[a-zA-Z]+[a-zA-Z0-9_-]*=.*$/) {
            my ($name, $value) = ($ARGV[$index] =~ /^([a-zA-Z]+[a-zA-Z0-9_-]*)=(.*)$/);
            ${$self->{PARAMETERS}}{$name} = $value;
        } elsif($ARGV[$index] =~ /^-[a-zA-Z]+[a-zA-Z0-9_-]*=.*$/) {
            my ($name, $value) = ($ARGV[$index] =~ /^-([a-zA-Z]+[a-zA-Z0-9_-]*)=(.*)$/);
            ${$self->{PARAMETERS}}{$name} = $value;
        } else {
            ${$self->{PARAMETERS}}{$index} = $ARGV[$index];
        }
    }
}


=head2 medium

    my $medium = Anansi::Script::Shell->medium();

    my $medium = $OBJECT->medium();

    my $medium = $OBJECT->channel('MEDIUM');

Returns the STRING description of the medium this module is designed to handle.

=cut


sub medium {
    my $self = shift(@_);
    my $channel;
    $channel = shift(@_) if(0 < scalar(@_));
    return 'SHELL';
}

Anansi::ScriptComponent::addChannel('Anansi::Script::Shell', 'MEDIUM' => 'medium');


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

Anansi::ScriptComponent::addChannel('Anansi::Script::Shell', 'PARAMETER' => 'parameter');


=head2 validate

    my $valid = $OBJECT->validate();

    my $valid = $OBJECT->channel('VALIDATE_AS_APPROPRIATE');

Determines whether this module is the correct one to use for handling Perl
script execution.

=cut


sub validate {
    my $self = shift(@_);
    my $channel;
    $channel = shift(@_) if(0 < scalar(@_));
    return 1;
}

Anansi::ScriptComponent::addChannel('Anansi::Script::Shell', 'VALIDATE_AS_APPROPRIATE' => 'validate');


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

