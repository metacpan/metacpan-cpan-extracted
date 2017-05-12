# $Id: Dot.pm 47 2007-11-03 21:11:17Z asksol $
# $Source: /opt/CVS/Getopt-LL/lib/Class/Dot.pm,v $
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/branches/stable-1.5.0/lib/Class/Dot.pm $
# $Revision: 47 $
# $Date: 2007-11-03 22:11:17 +0100 (Sat, 03 Nov 2007) $
package Class::Dot;

use strict;
use warnings;
use version qw(qv);
use 5.006000;

use Carp qw(croak);
use Class::Dot::Types qw(:std);

our $VERSION   = qv('1.5.0');
our $AUTHORITY = 'cpan:ASKSH';

my @EXPORT_OK = qw(
    property after_property_set after_property_get
);

push @EXPORT_OK, @Class::Dot::Types::STD_TYPES;

my $INTERNAL_ATTR_NOISE = '__x__';

my %EXPORT_CLASS = (
   ':std'  => [@EXPORT_OK],
);

our %OPTIONS_FOR     = ();
our %PROPERTIES_FOR  = ();

my %__TYPE_DICT__ = (
   'Array'     => \&isa_Array,
   'Code'      => \&isa_Code,
   'Data'      => \&isa_Data,
   'File'      => \&isa_File,
   'Hash'      => \&isa_Hash,
   'Int'       => \&isa_Int,
   'Object'    => \&isa_Object,
   'String'    => \&isa_String,
);

sub import { ## no critic
    my $this_class   = shift;
    my $caller_class = caller;

    my $options = { };
    my $export_class;
    my @subs;
    for my $arg (@_) {
        if ($arg =~ m/^-/xms) {
            $options->{$arg} = 1;
        }
        elsif ($arg =~ m/^:/xms) {
            croak(   'Only one export class can be used. '
                    ."(Used already: [$export_class] now: [$arg])")
                if $export_class;

            $export_class = $arg;
        }
        else {
            push @subs, $arg;
        }
    }
    $OPTIONS_FOR{$caller_class} = $options;

    my @subs_to_export
        = $export_class && $EXPORT_CLASS{$export_class}
        ? (@{ $EXPORT_CLASS{$export_class} }, @subs)
        : @subs;

    no strict 'refs'; ## no critic;
    for my $sub_to_export (@subs_to_export) {
        _install_sub_from_class($this_class, $sub_to_export => $caller_class);
    }


    my %INSTALL_METHOD = (
        DESTROY     => _create_destroy_method($caller_class),
        __setattr__ => _create_setattr($caller_class),
        __getattr__ => _create_getattr($caller_class),
        __hasattr__ => _create_hasattr($caller_class),
    );
    if ($options->{'-new'}) {
        $INSTALL_METHOD{'new'} = _create_constructor($caller_class);
    }

    while (my ($method_name, $method_ref) = each %INSTALL_METHOD) {
        _install_sub_from_coderef($method_ref => $caller_class, $method_name);
    }

    $PROPERTIES_FOR{$caller_class} = {};

    return;
}

sub _install_sub_from_class {
    my ($pkg_from, $sub_name, $pkg_to) = @_;
    my $from = join q{::}, ($pkg_from, $sub_name);
    my $to   = join q{::}, ($pkg_to,   $sub_name);

    no strict 'refs'; ## no critic
    *{$to} = *{$from};

    return;
}

sub _install_sub_from_coderef {
    my ($coderef, $pkg_to, $sub_name) = @_;
    my $to = join q{::}, ($pkg_to, $sub_name);

    no strict   'refs';     ## no critic
    no warnings 'redefine'; ## no critic
    *{$to} = $coderef;

    return;
}

sub _create_setattr {
	my ($caller_class) = @_;
	my $options = $OPTIONS_FOR{$caller_class};

	return sub {
		my ($self, $attribute, $value) = @_;
        my $property_key
            = $INTERNAL_ATTR_NOISE . $attribute .  $INTERNAL_ATTR_NOISE;
		my $properties = __PACKAGE__->properties_for_class($self);
		return if not $properties->{$attribute};
		$self->{$property_key} = $value;
		return 1;
	}
}

sub _create_getattr {
	my ($caller_class) = @_;

	return sub {
		my ($self, $attribute) = @_;
        my $property_key
            = $INTERNAL_ATTR_NOISE . $attribute .  $INTERNAL_ATTR_NOISE;
		my $properties = __PACKAGE__->properties_for_class($self);
		return if not $properties->{$attribute};
		return $self->{$property_key};
	}
}

sub _create_hasattr {
	my ($caller_class) = @_;

    # For some reason, perlcritic thinks 'return sub {)'
    # is ProhibitMixedBooleanOperators, so need no critic here.
	return sub { ## no critic
		my ($self, $attribute) = @_;
        my $ref_self = ref $self;

        my $class;
        if ($ref_self) {
            $class = $ref_self;
        }
        else {
            $class = $self;
        }

        no strict 'refs'; ## no critic;
        my  @isa = @{ "${class}::ISA" };
        my $has_property = 0;

        ISA:
        for my $isa ($class, @isa) {
            if ($PROPERTIES_FOR{$isa} && $PROPERTIES_FOR{$isa}{$attribute}) {
                $has_property = 1;
                last ISA;
            }
        }

		return if not $has_property;
		return 1;
	}
}


sub _create_constructor {
    my ($caller_class) = @_;
    my $options = $OPTIONS_FOR{$caller_class};

    return sub {
        my ($class, $options_ref) = @_;
        $options_ref ||= {};

        my $self = { };
        bless $self, $class;

        OPTION:
        while (my ($opt_key, $opt_value) = each %{$options_ref}) {

            if ($self->__hasattr__($opt_key)) {
                $self->__setattr__($opt_key, $opt_value);
            }
        }

        no strict 'refs'; ## no critic
        if (my $build_ref = *{ $class . '::BUILD' }{CODE}) { ## no critic
            $Carp::CallLevel++; ## no critic
            my $ret = $build_ref->($self, $options_ref);
            $Carp::CallLevel--; ## no critic
            if ($options->{'-rebuild'} && ref $ret) {
                $self = $ret;
            }
        }

        return $self;
        }
}

sub properties_for_class {
    my ($self, $class) = @_;
    $class = ref $class || $class; ## no critic

    my %class_properties;

    my @isa_for_class;
    {
        no strict 'refs'; ## no critic
        @isa_for_class = @{ $class . '::ISA' };
    }

    for my $parent ($class, @isa_for_class) {
        for my $parent_property (keys %{ $PROPERTIES_FOR{$parent} }) {
            $class_properties{$parent_property} = 1;
        }
    }

    return \%class_properties;
}

sub _create_destroy_method {
    my ($caller_class) = @_;

    return sub {
        my ($self) = @_;
        #my $properties_ref =$PROPERTIES_FOR{$caller_class};
        #undef %{$properties_ref};
        #delete $PROPERTIES_FOR{$caller_class};

        no strict   'refs'; ## no critic
        no warnings 'once'; ## no critic
        if (my $demolish_ref = *{$caller_class.'::DEMOLISH'}{CODE}) { ## no critic
            $demolish_ref->($self);
        }

        return;
    }
}

sub property (@) { ## no critic
    my ($property, $isa) = @_;
    return if not $property;

    my $caller_class = caller;
    my $set_property = "set_$property";


    no strict 'refs'; ## no critic
    if (not *{ $caller_class . "::$property" }{CODE}) {
        my $get_accessor = _create_get_accessor($caller_class, $property, $isa);
        _install_sub_from_coderef($get_accessor => $caller_class, $property);
    }

    if (not *{ $caller_class . "::$set_property" }{CODE}) {
        my $set_accessor = _create_set_accessor($caller_class, $property, $isa);
        _install_sub_from_coderef($set_accessor => $caller_class, $set_property);
    }

    $PROPERTIES_FOR{$caller_class}->{$property} = 1;

    return;
}

sub after_property_get (@&) { ## no critic
    my ($property, $func_ref) = @_;
    my $caller_class = caller;

    _install_sub_from_coderef($func_ref => $caller_class, $property);

    return;
}

sub after_property_set (@&) { ## no critic
    my ($property, $func_ref) = @_;
    my $caller_class = caller;
    my $set_property = "set_$property";

    _install_sub_from_coderef($func_ref => $caller_class, $set_property);

    return;
}

sub _create_get_accessor {
    my ($caller_class, $property, $isa) = @_;
    my $options = $OPTIONS_FOR{$caller_class};
    my $property_key
        = $INTERNAL_ATTR_NOISE . $property .  $INTERNAL_ATTR_NOISE;

    if ($options->{'-chained'}) {
        return sub {
            my $self = shift;
            if (@_) {
                my $set_property = "set_$property";
                $self->$set_property($_[0]);
                return $self;
            }
            if (!exists $self->{$property_key}) {
                $self->{$property_key} =
                    ref $isa eq 'CODE'
                    ? $isa->($self)
                    : $isa;
            }
    
            return $self->{$property_key};
        };
    }
    else {
        return sub {
            my $self = shift;

            if (@_) {
                require Carp;
                Carp::croak("You tried to set a value with $property(). Did "
                        ."you mean set_$property() ?");
            }

            if (!exists $self->{$property_key}) {
                $self->{$property_key} =
                    ref $isa eq 'CODE'
                    ? $isa->($self)
                    : $isa;
            }
    
            return $self->{$property_key};
        };
    }
}

sub _create_set_accessor {
    my ($caller_class, $property) = @_;
    my $options = $OPTIONS_FOR{$caller_class};
    my $property_key
        = $INTERNAL_ATTR_NOISE . $property .  $INTERNAL_ATTR_NOISE;

    if ($options->{'-chained'}) {
    
        return sub {
            my ($self, $value ) = @_;
            $self->{$property_key} = $value;
            return $self; # <-- this is the chained part.
        }
    }
    else {
        return sub  {
            my ($self, $value) = @_;
            $self->{$property_key} = $value;
            return;
        }
    }
}

1;

__END__

=begin wikidoc

= NAME

Class::Dot - Simple and fast properties for Perl 5.

= VERSION

This document describes Class::Dot version v1.5.0 (stable).

= SYNOPSIS

    # load standard types (:std) and install default constructor (-new).
    use Class::Dot qw(-new :std);

    # Property without type.
    property 'attribute';

    # List of property types, doesn't need a default value.
    property string     => isa_String('default value');

    property integer    => isa_Int(256);

    property object     => isa_Object('MyApp::Controller');

    property hashref    => isa_Hash(foo => 1, bar => 2);
    
    property arrayref   => isa_Array(qw(the quick brown fox ...));

    property filehandle => isa_File()

    property code       => isa_Code { return 42 };

    property any_data   => isa_Data;

    # Object type that automaticly creates new instance if it doesn't exist.
    property model      => isa_Object('MyApp::Model', auto => 1);

    # Initialize something at object construction.
    sub BUILD {
        my ($self, $options_ref) = @_;

        warn 'Creating a new object of type ', ref $self;

        return;
    }

    # Do something at object destruction.
    sub DEMOLISH {
        my ($self) = @_;

        warn 'Instance of class', ref $self, ' is going out of scope.';

        return;
    }

    # Re-bless instance at instance construction time. (option -rebuild)
    use Carp;
    use Class::Dot qw(-new -rebuild :std);
    use Class::Plugin::Util qw(require_class); # For dynamic loading of classes.

    sub BUILD {
        my ($self, $options_ref) = @_;

        if (exists $options_ref->{delegate_to}) {
            my $new_class    = $options_ref->{delegate_to};
            if (require_class($new_class)) {
                my $new_instance = $new_class->new();
                return $new_instance;
            }
            else {
                croak "Could not load class: $new_class"
            }
        }

        return;
    }

= DESCRIPTION

Simple and fast properties for Perl 5.

{Class::Dot} also lets you define types for your properties, like Hash,
String, Int, File, Code, Array and so on.

All the types are populated with sane defaults, so you no longer have to
write code like this:

   sub make_healthy {
      my ($self) = @_;
      my $state  = $self->state;
      my $fur    = $self->fur;

      $state ||= { }; # <-- you don't have to do this with class dot.
      $fur   ||= [ ]; # <-- same with this.
   }

Class::Dot can also create a default constructor for you if you pass it the
{-new} option on the use line:

   use Class::Dot qw(-new :std);

If you pass a hashref to the constructor, it will use them as values for the
properties:

   my $cat = Animal::Mammal::Carnivorous::Cat->new({
      gender => 'male',
      fur    => ['black', 'white', 'short'],
   }

      
If you want to intialize something at object construction time you can! Just
define a method named {BUILD}. {Class::Dot} will pass on the instance and
all the arguments that was sent to {new}.

   sub BUILD {
      my ($self, $options_ref) = @_;

      warn 'Someone created a ', ref $self;
   
      return;
   }


The return value of the {BUILD} method doesn't mean anything, that is unleass
you have to {-rebuild} option on. When the {-rebuild} option is on,
{Class::Dot} uses the return value of BUILD as the new object, so you can
create a abstract factory or similar:

   use Class::Dot qw(-new -rebuild :std);

   sub BUILD {
      my ($self, $option_ref) = @_;

      if (exists $options_ref->{delegate_to}) {
         my $new_class = $options_ref->{delegate_to};
         my $new_instasnce = $new_class->new($options_ref);

         return $new_instance;
      }

      return;
   }

A big value of using properties is that you can override them at a later point
to make them support additional functionality, like setting a hardware flag,
logging, etc. In Class::Dot you override a property simply by defining their
accessors:

   property name => isa_String();

   sub name {   # <-- overrides the get accessor
      my ($self) = @_;

      warn 'Acessing the name property';

      return $self->__getattr__('name');
   }


   sub set_name { # <-- overrides the set accessor
      my ($self, $new_name) = @_;

      warn $self->__getattr__('name'), " changed name to $new_name!";

      $self->__setattr__('name', $new_name);

      return;
   }


There is one exception where this won't work, though. That is if you define a
property in a {BEGIN} block. If you do that you have to use the
{after_property_get()} and {after_property_set()} functions:

   BEGIN {
      use Class::Dot qw(-new :std);
      property name => isa_String();
   }

   after_property_get name => sub {
      my ($self) = @_;

      warn 'Acessing the name property';

      return $self->__getattr__('name');
   }; # <-- the semicolon is required here!


   after_property_set name => sub {
      my ($self, $new_name) = @_;

      warn $self->__getattr__('name'), " changed name to $new_name!";

      $self->__setattr__('name', $new_name);

      return;
   }; # <-- the semicolon is required here!

You can read more about {Class::Dot} in the [Class::Dot::Manual::Cookbook] and
[Class::Dot::Manual::FAQ]. (Not yet written for the 2.0 beta release).

Have a good time working with {Class::Dot}, and please report any bug you
might find, or send feature requests. (although {Class::Dot} is not meant to
be [Moose], it's meant to be simple and fast).
   

= SUBROUTINES/METHODS

== CLASS METHODS

=== {property($property, $default_value)}
=for apidoc VOID = Class::Dot::property(string $property, data $default_value)

Example:

    property foo => isa_String('hello world');

    property bar => isa_Int(303);

will create the methods:

    foo( )
    set_foo($value)

    bar( )
    set_bar($value)

with default return values -hello world- and -303-.

=== {after_property_get($attr_name, \&code)}

Override the get accessor method for a property.

Example:

   property name => isa_String;

   after_property_get name => sub {
      my ($self) = @_;
      
      warn 'Accessing the name property of ' . ref $self;
      
      return $self->__getattr__('name');
   }; # <- needs the semi-colon at the end!

=== {after_property_set($attr_name, \&code)}

Override the set accessor method for a property.

Example:

   property name => isa_String;
   
   after_property_set name => sub {
      my ($self, $new_name) = @_;

      warn $self->__getattr__('name') . " is canging name to $new_name";

      $self->__setattr__('name', $new_name);

      return;
   }; # <- needs the semi-colon at the end!

=== {isa_String($default_value)}
=for apidoc CODEREF = Class::Dot::isa_String(data|CODEREF $default_value)

The property is a string.

=== {isa_Int($default_value)}
=for apidoc CODEREF = Class::Dot::isa_Int(int $default_value)

The property is a number.

=== {isa_Array(@default_values)}
=for apidoc CODEREF = Class::Dot::isa_Array(@default_values)

The property is an array.

=== {isa_Hash(%default_values)}
=for apidoc CODEREF = Class::Dot::isa_Hash(@default_values)

The property is an hash.

=== {isa_Object($kind)}
=for apidoc CODEREF = Class::Dot::isa_Object(string $kind)

The property is a object.
(Does not really set a default value.).

=== {isa_Data()}
=for apidoc CODEREF = Class::Dot::isa_Data($data)

The property is of a not yet defined data type.

=== {isa_Code()}
=for apidoc CODEREF = Class::Dot::isa_Code(CODEREF $code)

The property is a subroutine reference.

=== {isa_File()}
=for apidoc CODEREF = Class::Dot::isa_Code(FILEHANDLE $fh)

== INSTANCE METHODS

=== {->properties_for_class($class)}
=for apidoc HASHREF = Class::Dot->properties_for_class(_CLASS|BLESSED $class)

Return the list of properties for a class/object that uses the powers.

== PRIVATE CLASS METHODS

=== {_create_get_accessor($property, $default_value)}
=for apidoc CODEREF = Class::Dot::_create_get_accessor(string $property, data|CODEREF $default_value)

Create the set accessor for a property.
Returns a code reference to the new setter method.
It has to be installed into the callers package afterwards.

=== {_create_set_accessor($property)}
=for apidoc CODEREF = Class::Dot::_create_set_accessor(string $property)

Create the get accessor for a property.
Returns a code reference to the new getter method.
It has to be installed into the callers package afterwards.

= DIAGNOSTICS

== * You tried to set a value with {foo()}. Did you mean {set_foo()}

Self-explained?


= CONFIGURATION AND ENVIRONMENT

This module requires no configuration file or environment variables.

= DEPENDENCIES

* [version]

= INCOMPATIBILITIES

None known.

= BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
[bug-class-dot@rt.cpan.org|mailto:bug-class-dot@rt.cpan.org], or through the web interface at
[CPAN Bug tracker|http://rt.cpan.org].

= SEE ALSO

== [Moose]

A complete object system for Perl 5. It is much more complete than
{Class::Dot}, but it is also slower.

== [Class::Accessor]

Simple and fast implementation of properties. However, I don't like
the syntax ({__PACKAGE__->mk_accessors} etc).

== [Class::InsideOut]

For Inside-Out objects. Does not have types.

= AUTHOR

Ask Solem, [ask@0x61736b.net].


= LICENSE AND COPYRIGHT

Copyright (c), 2007 Ask Solem [ask@0x61736b.net|mailto:ask@0x61736b.net].

{Class::Dot} is distributed under the Modified BSD License.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. The name of the author may not be used to endorse or promote products derived
from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

= DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=end wikidoc

=for stopwords vim expandtab shiftround

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
