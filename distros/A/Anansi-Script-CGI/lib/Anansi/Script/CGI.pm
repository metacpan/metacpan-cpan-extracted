package Anansi::Script::CGI;


=head1 NAME

Anansi::Script::CGI - Defines the mechanisms specific to handling web browser execution.

=head1 SYNOPSIS

    my $OBJECT = Anansi::Script::CGI->new();

=head1 DESCRIPTION

This module is designed to be an optional component module for use by the
L<Anansi::Script> component management module.  It defines the processes
specific to handling both input and output from Perl scripts that are executed
by a web server using the Common Gateway Interface.  Uses
L<Anansi::ComponentManager> I<(indirectly)>, L<Anansi::ScriptComponent> and
L<base>.

=cut


our $VERSION = '0.03';

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
    $self->saveHeaders(%parameters);
    print $self->content();
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

Declared in L<Anansi::initialise>.  Overridden by this module.

=cut


sub initialise {
    my ($self, %parameters) = @_;
    my $CGI = CGI->new();
    $self->uses(
        CGI => $CGI,
    );
    $self->loadHeaders(%parameters);
    $self->loadParameters(%parameters);
    $self->header('content-type' => 'text/html');
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

    my $contents = $OBJECT->channel('CONTENT');

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

Anansi::ScriptComponent::addChannel('Anansi::Script::CGI', 'CONTENT' => 'content');


=head2 header

    my $headers = $OBJECT->header();

    my $headers = $OBJECT->channel('HEADER');

    my $headerValue = $OBJECT->header(undef, 'header_name');

    my $headerValue = $OBJECT->channel('HEADER', 'header_name');

    if($OBJECT->header(undef, 'header_name' => 'header value', 'another_header' => undef, 'yet_another_header' => [1, 2, 3], 'one_more' => {'hash key' => 'some value', 'another key' => undef}));

    if($OBJECT->channel('HEADER', 'header_name' => 'header value', 'another_header' => undef, 'yet_another_header' => [1, 2, 3], 'one_more' => {'hash key' => 'some value', 'another key' => undef}));

Either returns an ARRAY of all the existing header names or returns the value of
a specific header or sets the value of one or more headers.  Assigning an
"undef" value to a header has the effect of deleting the header.  Assigning an
"undef" HASH key value to a header's HASH value has the effect of deleting the
HASH key value.

=cut


sub header {
    my $self = shift(@_);
    my $channel;
    $channel = shift(@_) if(0 < scalar(@_));
    if(0 == scalar(@_)) {
        return [] if(!defined($self->{HEADERS}));
        return [( keys(%{$self->{HEADERS}}) )];
    } elsif(1 == scalar(@_)) {
        my $name = shift(@_);
        return if(!defined($self->{HEADERS}));
        return if(!defined(${$self->{HEADERS}}{$name}));
        return ${$self->{HEADERS}}{$name};
    } elsif(1 == scalar(@_) % 2) {
        return 0;
    }
    my ($name, %parameters) = @_;
    foreach my $name (keys(%parameters)) {
        if(!defined(${$self->{HEADERS}}{$name})) {
        } elsif(ref($parameters{$name}) =~ /^$/) {
        } elsif(ref($parameters{$name}) =~ /^ARRAY$/i) {
            foreach my $value (@{${$self->{HEADERS}}{$name}}) {
                return 0 if(ref($value) !~ /^$/);
            }
        } elsif(ref($parameters{$name}) =~ /^HASH$/i) {
            foreach my $value (keys(%{$parameters{$name}})) {
                if(defined(${$parameters{$name}}{$value})) {
                    return 0 if(ref(${$parameters{$name}}{$value}) !~ /^$/);
                }
            }
        } else {
            return 0;
        }
    }
    foreach my $name (keys(%parameters)) {
        if(!defined(${$self->{HEADERS}}{$name})) {
            delete(${$self->{HEADERS}}{$name});
        } elsif(ref($parameters{$name}) =~ /^$/) {
            ${$self->{HEADERS}}{$name} = $parameters{$name};
        } elsif(ref($parameters{$name}) =~ /^ARRAY$/i) {
            ${$self->{HEADERS}}{$name} = [];
            foreach my $value (@{${$self->{HEADERS}}{$name}}) {
                push(@{${$self->{HEADERS}}{$name}}, $value);
            }
        } elsif(ref($parameters{$name}) =~ /^HASH$/i) {
            ${$self->{HEADERS}}{$name} = {} if(ref(${$self->{HEADERS}}{$name}) !~ /^HASH$/i);
            foreach my $value (keys(%{$parameters{$name}})) {
                if(!defined(${$parameters{$name}}{$value})) {
                    delete(${${$self->{HEADERS}}{$name}}{$value}) if(defined(${${$self->{HEADERS}}{$name}}{$value}));
                } else {
                    ${${$self->{HEADERS}}{$name}}{$value} = ${$parameters{$name}}{$value};
                }
            }
        }
    }
    return 1;
}

Anansi::ScriptComponent::addChannel('Anansi::Script::CGI', 'HEADER' => 'header');


=head2 loadHeaders

    $OBJECT->loadHeaders();

Loads all of the CGI headers supplied upon page REQUEST.

=cut


sub loadHeaders {
    my ($self, %parameters) = @_;
    $self->{HEADERS} = {} if(!defined($self->{HEADERS}));
    foreach my $name ($self->{CGI}->param()) {
        ${$self->{HEADERS}}{$name} = $self->{CGI}->param($name);
    }
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

    my $medium = Anansi::Script::CGI->medium();

    my $medium = $OBJECT->medium();

    my $medium = $OBJECT->channel('MEDIUM');

Returns the STRING description of the medium this module is designed to handle.

=cut


sub medium {
    my $self = shift(@_);
    my $channel;
    $channel = shift(@_) if(0 < scalar(@_));
    return 'CGI';
}

Anansi::ScriptComponent::addChannel('Anansi::Script::CGI', 'MEDIUM' => 'medium');


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

Anansi::ScriptComponent::addChannel('Anansi::Script::CGI', 'PARAMETER' => 'parameter');


=head2 priority

    my $priority = Anansi::Script::CGI->priority();

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
        'Anansi::Script::Shell' => 'lower',
    };
    return $priorities;
}

Anansi::ScriptComponent::addChannel('Anansi::Script::CGI', 'PRIORITY_OF_VALIDATE' => 'priority');


=head2 saveHeaders

    $OBJECT->saveHeaders();

Prints the CGI headers.

=cut


sub saveHeaders {
    my ($self, %parameters) = @_;
    return if(0 == scalar(keys(%{$self->{HEADERS}})));
    foreach my $header (keys(%{$self->{HEADERS}})) {
        if(ref(${$self->{HEADERS}}{$header}) =~ /^$/) {
            print $header.': '.${$self->{HEADERS}}{$header}."\n";
        } elsif(ref(${$self->{HEADERS}}{$header}) =~ /^ARRAY$/i) {
            foreach my $value (@{${$self->{HEADERS}}{$header}}) {
                print $header.': '.$value."\n";
            }
        } elsif(ref(${$self->{HEADERS}}{$header}) =~ /^HASH$/i) {
            foreach my $name (keys(%{${$self->{HEADERS}}{$header}})) {
                print $header.': '.${${$self->{HEADERS}}{$header}}{$name}."\n";
            }
        }
    }
    print "\n";
}


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
    return 1 if(exists($ENV{'MOD_PERL'}));
    return 1 if(exists($ENV{'GATEWAY_INTERFACE'}));
    return 0;
}

Anansi::ScriptComponent::addChannel('Anansi::Script::CGI', 'VALIDATE_AS_APPROPRIATE' => 'validate');


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

