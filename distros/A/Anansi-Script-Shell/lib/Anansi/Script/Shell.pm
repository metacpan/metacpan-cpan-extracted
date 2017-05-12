package Anansi::Script::Shell;


=head1 NAME

Anansi::Script::Shell - Defines the mechanisms specific to handling command line execution.

=head1 SYNOPSIS

 my $OBJECT = Anansi::Script::Shell->new();

=head1 DESCRIPTION

This module is designed to be an optional component module for use by the
L<Anansi::Script> component management module.  It defines the processes
specific to handling both input and output from Perl scripts that are executed
from a command line.  See L<Anansi::Component> for inherited methods.

=cut


our $VERSION = '0.03';

use base qw(Anansi::Component);


=head1 METHODS

=cut


=head2 content

 my $contents = $OBJECT->content();

 # OR

 if(1 == $OBJECT->content(undef, undef));

 # OR

 if(1 == $OBJECT->channel('CONTENT', undef));

 # OR

 if(1 == $OBJECT->content(undef, 'some content'));

 # OR

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

Anansi::Component::addChannel('Anansi::Script::Shell', 'CONTENT' => 'content');


=head2 finalise

 $OBJECT::SUPER->finalise(@_);

An overridden virtual method called during object destruction.  Not intended to
be directly called unless overridden by a descendant.

=cut


sub finalise {
    my ($self, %parameters) = @_;
    print $self->content();
}


=head2 initialise

 $OBJECT::SUPER->initialise(@_);

An overridden virtual method called during object creation.  Not intended to be
directly called unless overridden by a descendant.

=cut


sub initialise {
    my ($self, %parameters) = @_;
    $self->loadParameters(%parameters);
    $self->content();
}


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
    return 'SHELL';
}

Anansi::Component::addChannel('Anansi::Script::Shell', 'MEDIUM' => 'medium');


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

Anansi::Component::addChannel('Anansi::Script::Shell', 'PARAMETER' => 'parameter');


=head2 validate

 my $valid = $OBJECT->validate();

 # OR

 my $valid = $OBJECT->channel('VALIDATE_AS_APPROPRIATE');

Determines whether this module is the correct one to use for handling Perl
script execution.

=cut


sub validate {
    my $self = shift(@_);
    my $channel;
    $channel = shift(@_) if(0 < scalar(@_));
    return 0 if(defined($ENV{'HTTP_HOST'}));
    return 1;
}

Anansi::Component::addChannel('Anansi::Script::Shell', 'VALIDATE_AS_APPROPRIATE' => 'validate');


=head1 AUTHOR

Kevin Treleaven <kevin AT treleaven DOT net>

=cut


1;
