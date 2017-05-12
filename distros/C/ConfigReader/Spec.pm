# ConfigReader/Spec.pm: specifies a set of configuration directives
#
# Copyright 1996 by Andrew Wilcox <awilcox@world.std.com>.
# All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the Free
# Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

package ConfigReader::Spec;
$VERSION = "0.5";

my $This_file = __FILE__;       # used to get our filename out of error msgs

require 5.001;
use Carp;
use strict;

=head1 NAME

ConfigReader::Spec

=head1 DESCRIPTION

The ConfigReader::Spec class stores a specification about
configuration directives: their names, whether they are required or if
they have default values, and what parsing function or method to use.

=cut

## Public methods

sub new {
    my ($class) = @_;
    my $self = {directives => {},          # directive name => 1
                alias_to_directive => {},  # map alias to name
                default => {},             # name => default value
                whence_default => {},      # name => source location of default 
                parser => {},              # name => value parser
                name => {},                # name => 1, ignore this directive
                required => {}             # name => 1, required directive
            };
    return bless $self, $class;
}

sub directives {
    my ($self) = @_;
    return keys %{$self->{'directives'}};
}

sub value {
    my ($self, $directive, $values, $whence) = @_;
    $directive = $self->canonical_name($directive);

    my $name = $self->{'alias_to_directive'}{$directive};
    $self->_error("Undefined directive '$directive'", $whence)
        unless defined $name;

    $self->_error("The directive '$directive' has not been assigned a value",
                  $whence)
        unless exists($values->{$name});

    return $values->{$name};
}


sub alias {
    my ($self, $directive, @aliases) = @_;
    $directive = $self->canonical_name($directive);
    my $alias;
    foreach $alias (@aliases) {
        $self->{'alias_to_directive'}{$self->canonical_name($alias)} =
            $directive;
    }
}

sub define_directive {
    my ($self, $directive, $parser, $whence) = @_;

    my ($name, @aliases);

    my $ref = ref($directive);
    if (defined $ref and $ref eq 'ARRAY') {
        $name = shift @$directive;
        @aliases = @$directive;
    }
    else {
        $name = $directive;
        @aliases = ($directive);
    }
    $name = $self->canonical_name($name);

    $self->{'directives'}{$name} = 1;
    $self->alias($name, @aliases);

    if (defined $parser) {
        $self->{'parser'}{$name} =
            $self->_resolve_code($parser,
                                 'specified as parser',
                                 $whence);
    }
    else {
        delete $self->{'parser'};
    }

    return $name;
}

sub required {
    my ($self, $directive, $parser, $whence) = @_;

    my $name = $self->define_directive($directive,
                                       $parser,
                                       $whence);
    $self->{'required'}{$name} = 1;
}


sub directive {
    my ($self, $directive, $parser, $default, $whence) = @_;

    my $name = $self->define_directive($directive,
                                       $parser,
                                       $whence);
    $self->{'default'}{$name} = $default;
    $self->{'whence_default'}{$name} = $whence;
    return $name;
}

sub ignore {
    my ($self, $directive, $whence) = @_;

    my $name = $self->define_directive($directive, undef, undef, $whence);
    $self->{'ignore'}{$name} = 1;
}

sub assign {
    my ($self, $directive, $value_string, $values, $whence) = @_;
    $directive = $self->canonical_name($directive);

    my $name = $self->{'alias_to_directive'}{$directive};
    $self->undefined_directive($directive, $value_string, $whence)
        unless defined $name;

    return undef if $self->{'ignore'}{$name};

    $self->duplicate_directive($directive, $value_string, $whence)
        if defined $values and exists $values->{$name};

    if (not defined $value_string) {
        $values->{$name} = undef if defined $values;
        return undef;
    }

    my $parser = $self->{parser}{$name};
    my $value;

    if (defined $parser) {
        my @warnings = ();
        local $SIG{'__WARN__'} = sub { push @warnings, $_[0] };
        my $saved_eval_error = $@;
        eval { $value = &$parser($value_string) };
        my $error = $@;
        $@ = $saved_eval_error;

        my $warning;
        foreach $warning (@warnings) {
            $warning =~ s/ at $This_file line \d+$//o;  # uncarp
            if (defined $whence) {
                warn
"While parsing '$value_string' as the value for the
'$directive' directive as specified
$whence,
I got this warning:
$warning";
            }
            else {
                $warning =~ s/\n?$/\n/;
                carp $warning .
" while parsing '$value_string' as the value for the '$directive' directive";
            }
        }

        if ($error) {
            $error =~ s/ at $This_file line \d+$//o;  # uncroak
            if (defined $whence) {
                $whence =~ s,\n$,,;
                die
"I tried to parse '$value_string' as the value for the '$directive' directive as specified $whence
but the following error occurred:

$error";
            }
            else {
                $error =~ s/\n?$/\n/;
                croak $error."while parsing '$value_string' as the value for the '$directive' directive";
            }
        }
    }
    else {
        $value = $value_string;
    }

    $values->{$name} = $value if defined $values;
    return $value;
}

sub assign_defaults {
    my ($self, $values, $whence) = @_;

    my $name;
    foreach $name ($self->directives()) {
        $self->assign_default($name, $values, $whence);
    }
}

sub assign_default {
    my ($self, $directive, $values, $whence) = @_;
    $directive = $self->canonical_name($directive);

    my $name = $self->{'alias_to_directive'}{$directive};
    $self->_error("Undefined directive '$directive'", $whence)
        unless defined $name;

    return $values->{$name} if defined $values and exists $values->{$name};

    if ($self->{'required'}{$name}) {
        $self->_error("Please specify the '$name' directive", $whence);
    }
    elsif ($self->{'ignore'}{$name}) {
        return undef;
    }

    my $default = $self->{'default'}{$name};
    # "as the default value "
    my $whence_default = $self->{'whence_default'}{$name};
    my $value;

    if (not defined $default) {
        return $self->assign($name, undef, $values, $whence_default);
    }
    elsif (not ref $default) {
        return $self->assign($name, $default, $values, $whence_default);
    }
    elsif (ref($default) eq 'CODE') {
        local $SIG{'__DIE__'} = sub {
            $self->_error("$_[0]\nwhile assigning the default value for the '$name' directive", $whence_default);
        };
        $value = &$default();
        $values->{$name} = $value if defined $values;
        return $value;
    }
    else {
        $value = $default;
        $values->{$name} = $value if defined $values;
        return $value;
    }
}

## subclass hooks

sub canonical_name {
    my ($self, $directive) = @_;
    return $directive;
}

sub undefined_directive {
    my ($self, $directive, $value_string, $whence) = @_;

    $self->_error("Unknown directive '$directive' specified", $whence);
}

sub duplicate_directive {
    my ($self, $directive, $value_string, $whence) = @_;

    $self->_error("Duplicate directive '$directive' specified", $whence);
}


## Internal methods

# Allows the user to specify code to run in several different ways.
# Returns a code ref that will run the desired code.
#    'new URI::URL'       calls static method 'new' in class 'URI::URL'
#    $coderef             calls the code ref
#    [new => 'URI::URL']  calls new URI::URL
#    [parse => $obj]      calls $obj->parse()

sub _resolve_code {
    my ($self, $sub, $purpose, $whence) = @_;
    my ($r, $class, $static_method, $function);

    $r = ref($sub);
    if (not $r) {
        if (($static_method, $class) = ($sub =~ m/^(\w+) \s+ ([\w:]+)$/x)) {
            return sub {
                $class->$static_method(@_);
            };
        }
        else {
            $self->_error("Syntax error in function name '$sub' $purpose",
                          $whence);
        }
    }
    elsif ($r eq 'CODE') {
        return $sub;
    }
    elsif ($r eq 'ARRAY') {
        my ($method, $class_or_obj) = @$sub;
        $self->_error("Empty array used to $purpose", $whence)
            unless defined $method;
        $self->_error("Class or object not specified in array used to $purpose",
                      $whence)
            unless defined $class_or_obj;
        return sub {
            $class_or_obj->$method(@_);
        };
    }
    else {
        $self->_error("Unknown object $purpose", $whence);
    }
}

sub _error {
    my ($self, $msg, $whence) = @_;

    if (defined $whence) {
        $whence =~ s,\n?$,\n,;
        die "$msg $whence";
    }
    else {
        croak $msg;
    }
}

1;
