# ConfigReader/Values.pm: stores a set of configuration values
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

package ConfigReader::Values;
$VERSION = "0.5";

require ConfigReader::Spec;
use     strict;

=head1 NAME

ConfigReader::Values  -  stores a set of configuration values

=head1 DESCRIPTION

This class stores a set of configuration values that have been read
from a configuration file.  Methods are provided to define directives,
assign and retrieve values, and to create accessor subroutines.

As this class will usually be subclassed to implement a reader for a
specific style of configuration files, the user-oriented methods will be
described first.  Methods used to help implement a subclass are
described later.

=head1 USER METHODS

=head2 C<directive($directive, [$parser, [$default, [$whence]]])

Defines a directive named $directive for the configuration file.  You
may optionally specify a parsing function or method for the directive,
and a default value.

If $directive is a simple string, it will be used as both the name of
the directive inside of the program and in the configuration file.
You can use an array ref of the form

     ['program-name', 'name1', 'name2', 'name3' ...]

to use 'program-name' inside of the program, but to recognize any of
'name1', 'name2', 'name3' as the name of directive in the
configuration file.

A directive will be set to undef if you don't specify a default value
and it is not set in the configuration file.

Any errors or warnings that occur while parsing the default value are
normally reported as orginating in the caller's module.  You can
change the reported location by specifying $whence.

=cut

sub directive {
    my ($self, $directive, $parser, $default, $whence) = @_;

    unless (defined $whence) {
        my ($package, $filename, $line) = caller;
        $whence = "at $filename line $line";
    }

    return $self->{'spec'}->directive($directive, $parser, $default, $whence);
}


=head2 C<required($directive, [$parser, [$whence]])

Defines a directive which must be specified in the configuration file.

=cut

sub required        { my $s = shift;  $s->{'spec'}->required(@_); }


=head2 C<ignore($directive, [$whence])>

Defines a directive which will be accepted but ignored in the
configuration file.

=cut

sub ignore          { my $s = shift;  $s->{'spec'}->ignore(@_); }


=head2 C<directives()>

Returns an array of the configuration directive names.

=cut

sub directives      { my $s = shift;  $s->{'spec'}->directives(@_); }


=head2 C<value($directive, [$whence])>

Returns the value of the configuration directive $directive.

=cut

sub value {
    my ($self, $directive, $whence) = @_;

    unless (defined $whence) {
        my ($package, $filename, $line) = caller;
        $whence = "at $filename line $line";
    }

    my $spec = $self->{'spec'};
    my $values = $self->{'values'};

    return $spec->value($directive, $values, $whence);
}


=head2 C<define_accessors([$package, [@names]])>

Creates subroutines in the caller's package to access configuration
values.  For example, if one of the configuration directives is named
"Input_File", you can do:

    $config->define_accessors();
    ...

    open(IN, Input_File());

The names of the created subroutines is returned in an array.  If
you'd like to export the accessor subroutines, you can say:

    push @EXPORT, $config->define_accessors();

You can specify the package in which to create the subroutines with the
optional $package argument.  You may also specify which configuration
directives to create accessor subroutines for.  By default,
subroutines will be created for all the directives.

=cut

sub define_accessors {
    my ($self, $package, @names) = @_;
    @names = $self->directives() unless @names;
    $package = (caller)[0] unless defined $package;

    my $name;
    foreach $name (@names) {
        $self->_define_accessor($name, $package);
    }
    @names;
}

sub _define_accessor {
    my ($self, $name, $package) = @_;
    $package = (caller)[0] unless defined $package;
    
    no strict 'refs';
    *{ $package . "::" . $name } = $self->_make_accessor($name);
    return $name;
}

sub _make_accessor {
    my ($self, $name) = @_;
    return sub {
        my ($package, $filename, $line) = caller;
        $self->value($name, "at $filename line $line")
    };
}

=head1 IMPLEMENTATION METHODS

The following methods will probably be called by a subclass
implementing a reader for a particular style of configuration files.

=head2 new( [$spec] )

The static method new() creates and returns a new ConfigReader::Values
object.

Unless the optional $spec argument is present, a new
ConfigReader::Spec object will be created to store the configuration
specification.  The directive(), required(), ignore(), value(), and
directive() methods described above are passed through to the spec
object.

By setting $spec, you can use a different class (perhaps a subclass)
to store the specification.

You can also set $spec if you want to use one specification for
multiple sets of values.  Files like /etc/termcap describe a
configuration for multiple objects (terminals, in this case), but use
the same directives to describe each object.

=cut

sub new {
    my ($class, $spec) = @_;
    $spec = new ConfigReader::Spec unless defined $spec;
    my $self = {spec   => $spec,
                values => {}};
    return bless $self, $class;
}


=head2 C<values()>

Returns the hash ref which actually stores the configuration directive
values.  The key of the hash ref is the directive name.

=cut

sub values {
    my ($self) = @_;
    return $self->{'values'};
}


=head2 C<spec()>

Returns the internal spec object used to store the configuration
specification.

=cut

sub spec {
    my ($self) = @_;
    return $self->{'spec'};
}


=head2 C<assign($directive, $value_string, $whence)>

Normally called while reading the configuration file, assigns a value
to the directive named $directive.  The $value_string will be parsed
by the directive's parsing function or method, if any.  $whence should
describe the line in the configuration file which contained the value
string.

=cut

sub assign {
    my ($self, $directive, $value_string, $whence) = @_;
    my $spec = $self->{'spec'};
    my $values = $self->{'values'};
    return $spec->assign($directive, $value_string, $values, $whence);
}

=head2 C<assign_defaults($whence)>

After the configuration file is read, the assign_defaults() method is
called to assign the default values for directives which were not
specified in the configuration file.  $whence should describe the name
of the configuration file.

=cut

sub assign_defaults {
    my ($self, $whence) = @_;
    my $values = $self->{'values'};
    my $spec = $self->{'spec'};
    return $spec->assign_defaults($values, $whence);
}

1;
