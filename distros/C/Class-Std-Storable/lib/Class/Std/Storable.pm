package Class::Std::Storable;

use version; $VERSION = qv('0.0.1');
use strict;
use warnings;
use Class::Std; #get subs from parent to export
use Carp;

#hold attributes by package
my %attributes_of;

my @exported_subs = qw(
    new
    ident
    DESTROY
    MODIFY_HASH_ATTRIBUTES
    MODIFY_CODE_ATTRIBUTES
    AUTOLOAD
    _DUMP
    STORABLE_freeze
    STORABLE_thaw
);

sub import {
    no strict 'refs';
    for my $sub ( @exported_subs ) {
        *{ caller() . '::' . $sub } = \&{$sub};
    }
}

#NOTE: this subroutine should override the one that's imported
#by the "use Class::Std" above.
{
    my $old_sub = \&Class::Std::MODIFY_HASH_ATTRIBUTES;
    my %positional_arg_of;
    my $new_sub = sub {
        my ($package, $referent, @attrs) = @_;
        my @return_attrs = $old_sub->(@_);

        for my $attr (@attrs) {
            next if $attr !~ m/\A ATTRS? \s* (?:[(] (.*) [)] )? \z/xms;
            my $name;
            #we have a backup if no name is given for the attribute.
            $positional_arg_of{$package} ||= "__Positional_0001";
            #but we would prefer to know the argument as the class does.
            if (my $config = $1) {
                $name = Class::Std::_extract_init_arg($config)
                    || Class::Std::_extract_get($config)
                    || Class::Std::_extract_set($config);
            }
            $name ||= $positional_arg_of{$package}++;
            push @{$attributes_of{$package}}, {
                ref      => $referent,
                name     => $name,
            };
        }
        return @return_attrs;
    };

    no warnings; #or this complains about redefining sub
    *MODIFY_HASH_ATTRIBUTES = $new_sub;
};

sub STORABLE_freeze {
    #croak "must be called from Storable" unless caller eq 'Storable';
    #unfortunately, Storable never appears on the call stack.
    my($self, $cloning) = @_;
    $self->STORABLE_freeze_pre($cloning)
        if UNIVERSAL::can($self, "STORABLE_freeze_pre");
    my $id = ident($self);
    require Storable;
    my $serialized = Storable::freeze( \ (my $anon_scalar) );

    my %frozen_attr; #to be constructed
    my @package_list = ref $self;
    my %package_seen = ( ref($self) => 1 ); #ignore diamond/looped base classes :-)
    PACKAGE:
    while( my $package = shift @package_list) {
        #make sure we add any base classes to the list of
        #packages to examine for attributes.
        { no strict 'refs';
            for my $base_class ( @{"${package}::ISA"} ) {
                push @package_list, $base_class
                    if !$package_seen{$base_class}++;
            }
        }
        #examine attributes from known packages only
        my $attr_list_ref = $attributes_of{$package} or next PACKAGE;

        #look for any attributes of this object for this package
        ATTR:
        for my $attr_ref ( @{$attr_list_ref} ) {
            #nothing to do if attr not set for this object
            next ATTR if !exists $attr_ref->{ref}{$id};
            #save the attr by name into the package hash
            $frozen_attr{$package}{ $attr_ref->{name} }
                = $attr_ref->{ref}{$id};
        }
    }

    $self->STORABLE_freeze_post($cloning, \%frozen_attr)
        if UNIVERSAL::can($self, "STORABLE_freeze_post");
    return ($serialized, \%frozen_attr );
}

sub STORABLE_thaw {
    #croak "must be called from Storable" unless caller eq 'Storable';
    #unfortunately, Storable never appears on the call stack.
    my($self, $cloning, $serialized, $frozen_attr_ref) = @_;
    #we can ignore $serialized, as we know it's an anon_scalar.
    $self->STORABLE_thaw_pre($cloning, $frozen_attr_ref)
        if UNIVERSAL::can($self, "STORABLE_thaw_pre");
    my $id = ident($self);
    PACKAGE:
    while( my ($package, $pkg_attr_ref) = each %$frozen_attr_ref ) {
        croak "unknown base class '$package' seen while thawing ".ref($self)
            if ! UNIVERSAL::isa($self, $package);
        my $attr_list_ref = $attributes_of{$package};
        ATTR:
        for my $attr_ref ( @{$attr_list_ref} ) { #for known attrs...
            #nothing to do if frozen attr doesn't exist
            next ATTR if !exists $pkg_attr_ref->{ $attr_ref->{name} };
            #block attempts to meddle with existing objects
            croak "trying to modify existing attributes for $package"
                if exists $attr_ref->{ref}{$id};
            #ok, set the attribute
            $attr_ref->{ref}{$id}
                = delete $pkg_attr_ref->{ $attr_ref->{name} };
        }
        if( my @extra_keys = keys %$pkg_attr_ref ) {
            #this is probably serious enough to throw an exception.
            #however, TODO: it would be nice if the class could somehow
            #indicate to ignore this problem.
            croak "unknown attribute(s) seen while thawing"
                ." class $package: " . join(q{, }, @extra_keys);
        }
    }
    $self->STORABLE_thaw_post($cloning)
        if UNIVERSAL::can($self, "STORABLE_thaw_post");
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Class::Std::Storable - Support for creating serializable "inside-out" classes

=head1 VERSION

This document describes Class::Std::Storable version 0.0.1

=head1 SYNOPSIS

In general, use this class exactly as you would Class::Std.

    package Ice::Cream;
    use Class::Std::Storable;
    {
        my %name_of :ATTR( :get<name> :set<name> );
        my %flavor_of :ATTR( :get<flavor> :set<flavor> );
    }

    package main;
    my $object = Ice::Cream->new;
    $object->set_name("Vanilla Bean");
    $object->set_flavor("vanilla");

But now, you may also serialize the object with Storable.

    use Storable;
    my $serialized = Storable::freeze($object);
    #store to a file, database, or wherever, and retrieve later.
    my $clone = Storable::thaw($serialized);

=head1 DESCRIPTION

Class::Std introduced the "inside-out" model for classes (perldoc Class::Std
for details).  Among its salient features is complete encapsulation;
that is, an object's data may only be accessed via its methods, unlike the
usual hashref model that permits direct access by any code whatsoever.
However, the drawback of complete encapsulation is that normal mechanisms
for serialization won't work, as they rely on direct access to an object's
attributes.

This class provides the class-building functionality from Class::Std, and in
addition provides an interface to allow Storable to freeze and thaw any
declared attributes of this class and any superclasses that were built via
Class::Std::Storable.

However, in order to let Storable save attributes and construct the object,
it is necessary to expose the attributes of the class to the world.  Thus,
any code could use the same interface that Storable does to get a copy of
object attributes and create new objects with arbitrary attributes
without going through the constructor.  While the interface CAN'T be used to
replace the existing attributes of an object, it COULD be used to create an
arbitrarily mutated clone of an object without going through its methods.
Also, if attributes are themselves references, then the objects to which
they refer can be obtained and modified.

As true encapsulation is one of the major features of Class::Std, this
would be a good reason NOT to use this class.  But this sacrifice is
required to provide serialization.  You must choose which is more
important for your purposes, serialization or complete encapsulation.
Consider also that while bypassing the class methods is possible to a limited
degree with Class::Std::Storable, doing so is much more complicated than
just using the methods, so use of this class still discourages casual
violations of encapsulation.

=head1 INTERFACE 

See Class::Std

This package provides object methods STORABLE_freeze and STORABLE_thaw
which are not intended to be used directly or overridden.

A class generated using Class::Std::Storable may provide hooks to be called
when a freeze or a thaw is performed.  These methods will be called if
provided:

=over

=item $obj->STORABLE_freeze_pre($cloning)

Called against the object at the very beginning of a freeze.  First parameter
is Storable's "cloning" flag -- see Storable.  This method could be used, for
example, to adjust or remove non-serializable attributes.

=item $obj->STORABLE_freeze_post($cloning, $param_ref)

Called against the object after the parameters for the freeze have
been determined, but before actual serialization.  First parameter is
Storable's "cloning" flag -- see Storable.  Second parameter is a reference
to a hash of hashes of parameters to be frozen, where the first level hash
is keyed on the package name of the class, and the second level is keyed
on the declared parameters of that class.  E.g.:

    $param_ref = {
        'Base::Class' => {
            flavor  => "vanilla",
            name  => "Vanilla Bean",
        },
        'Sub::Class' => {
            name => "Shiny Wax",
            price => '$0.02',
        },
    };

This hook could be used to adjust the attributes that are about to be frozen
for its class.  It is probably unwise to adjust the attributes of other
classes or to add new top-level hash entries.  This hook could also be
used to undo any changes that were necessary in STORABLE_freeze_pre.

=item $obj->STORABLE_thaw_pre($cloning, $param_ref)

Called against the object at the very beginning of a thaw.  First parameter
is Storable's "cloning" flag -- see Storable.  Second parameter is the
same parameter hash described for the previous method, which will be used
to reconstruct the object.

This method could be used for
validation, or to reconstruct attributes that couldn't be serialized.

=item $obj->STORABLE_thaw_post($cloning)

Called against the object when a thaw is otherwise complete.  First parameter
is Storable's "cloning" flag -- see Storable.  This method could be used for
validation, to reconstruct attributes that couldn't be serialized, or to
adjust class data.

=back

It would undoubtedly be a good idea to mark these methods :CUMULATIVE if
provided, so that base classes can perform their own hooks.  Also, these
methods can not be provided via AUTOLOAD.

=head1 DIAGNOSTICS

See Class::Std for its diagnostics.  Only the following are
particular to Class::Std::Storable.  All are exceptions thrown
with Carp::croak.

=over

=item "unknown attribute(s) seen while thawing"

This indicates that when STORABLE_thaw tried to thaw an object, it found
that the frozen object had an attribute that is not declared in the class.

This could mean the class definition changed, removing or renaming
attributes, between the freezing and thawing of the object.

It could also mean that the STORABLE_freeze_post hook was used to insert
an unknown key into the freezing hash for this class.  Remove such additions
in the STORABLE_thaw_pre hook (before the thawing gets under way).

=item "unknown base class '$package' seen while thawing"

This means that when thawing an object, its frozen hash representation
included an entry that is neither the class or a base class.  While this
could mean that class names changed between freezing and thawing the
object (don't do that), a more likely explanation is that a
STORABLE_freeze_post hook inserted an unknown key into the top level of
the freezing hash (don't do that either).

=item "trying to modify existing attributes for $package"

This probably means that some code is calling STORABLE_thaw
directly on an existing object in an attempt to fiddle with its attributes.
Don't even think about doing that.

The other explanation would be that the STORABLE_thaw_pre hook set an
attribute for the object but left that attribute in the frozen hash to
be thawed later.  STORABLE_thaw_pre should delete from the frozen hash
any attributes that it sets itself.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Class::Std::Storable requires no configuration files or environment variables.

=head1 DEPENDENCIES

Class::Std version 0.0.4 or newer, which is not at this time part of
the Perl core modules.  This module depends on a small set of Class::Std
internals staying largely the same and could break if that assumption proves
false.

=head1 INCOMPATIBILITIES

None reported.

=head1 LIMITATIONS

Vanilla Class::Std objects are not themselves serializable.  Any base
classes that are not built using Class::Std::Storable will probably not
serialize correctly without special tricks.  This is a feature, as it means
no one can just subclass a Class::Std class and break its encapsulation.

Class::Std::Storable works fine with nested structures and correctly
persists multiple references to the same object, as long as all references
are contained in a single serialization.

Class::Std::Storable has never been tested for thread safety, so no
guarantees there.

Class::Std::Storable attempts to identify attributes by their declaration,
that is, according to how :ATTR declares their getters/setters/initializers.
If none of these are declared for an attribute, it can only be identified by
its position, that is, the order of its appearance in the source code.  This
scheme will break if you change the position of these nameless attributes, or
change the names of the named ones, between the freezing and the thawing of an
object.

Serialization of inside-out objects naturally maintains the same caveats as for
any other object.  Only declared (:ATTR) object attributes identified with the
object will be serialized with the object.  In particular, "class data" won't
be serialized with the object.  Also, an object can't be serialized if any of
its attributes cannot themselves be serialized, e.g. if one is a closure.

=head1 BUGS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-class-std-storable@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Luke Meyer  C<< <luke@daeron.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Luke Meyer. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
