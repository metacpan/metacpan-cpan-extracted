package Class::DBI::Storable;
our $VERSION = '0.01';

=pod

=head1 NAME
 
Class::DBI::Storable - Mixin Storable hooks to freeze and thaw objects
 
=head1 VERSION
 
Version 0.01
 
=head1 SYNOPSIS
 
    package My::Class;
    use base 'Class::DBI';
    use Class::DBI::Storable;
  
    package main;
    use Storable qw(freeze thaw dclone);

    my $obj = My::Class->retrieve($id);

    dclone($obj);   # Produces a warning
  
=head1 DESCRIPTION

Class::DBI attempts to maintain the the uniqueness of objects
in memory.  Serializers such as Storable will generally violate
this constraint when an object is frozen and thawed.

This mixin module makes your Class::DBI objects serializable with
Storable.  Only the primary keys are serialized and the objects
is thawed using "retrieve" on the appropriate CDBI class.
 
The Storable hooks carp if there are unsaved changes to the object
being frozen or if you attempt to dclone a object.
Using dclone on a CDBI object doesn't really make sense.
 
STORABLE_freeze and STORABLE_attach the only methods.  They will be
called automatically by Storable.
 
=head2 Are You Sure This Is A Good Idea?

No.

This module exists to try to make Class::DBI and Storable work
together acceptably.  It's existence is not to be construed as
a recommendation of the practice.

=head1 DIAGNOSTICS

Storable::dclone($cdbi_object) will emit:

    "Warning, cloning a Class::DBI object of class <class name>"

This is to help catch inadvertent uses of dclone and to discourage it's use.
(The warning can be suppressed with the $CloneCarp package variable)

If Storable::freeze is called of an object with unsaved changes then:

    "Warning, freezing <class name> discards unsaved changes"

It also calls the discard_changes method from Class::DBI which may
throw an exception.
(Suppress the warning with the package variable $FreezeCarp)
 
=head1 DEPENDENCIES
 
Storable 2.14 or newer
 
=head1 BUGS AND LIMITATIONS
 
There are no known bugs in this module. 

Please report problems to the author directly or via RT

=head1 SEE ALSO

L<Class::DBI> in particular "Uniqueness of Objects in Memory", L<Storable>
 
=head1 AUTHOR
 
Brad Bowman E<lt>cpan@bereft.netE<gt>
 
=head1 LICENCE AND COPYRIGHT
 
Copyright (c) 2005 Brad Bowman E<lt>cpan@bereft.netE<gt>. All rights reserved.
 
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 

=cut

use strict;
use Storable qw(nfreeze thaw); # XXX Storable must be 2.14 or greater
use Carp qw(croak carp);

# The hooks can be imported or inherited
use Exporter;
our @EXPORT = qw(STORABLE_freeze STORABLE_attach);

our $CloneCarp = 1;
our $FreezeCarp = 1;

sub STORABLE_freeze {
    my ($self, $cloning) = @_;

    if ($cloning) {
        if($CloneCarp) {
            carp "Warning, cloning a Class::DBI object of class ", ref($self);
        } 
        return;
    }

    if ($self->is_changed) {
        if($FreezeCarp) {
            carp "Warning, freezing ", ref($self), " discards unsaved changes";
        }
        $self->discard_changes; # May throw an exception
    }

    return nfreeze([ $self->id ]);
}

sub STORABLE_attach {
    my ($class, $cloning, $serialized) = @_;

    return if ($cloning);

    my @id = @{ thaw($serialized) };

    my %key_values;
    @key_values{ $class->columns('Primary') } = @id;

    return $class->retrieve(%key_values);
}

1;
