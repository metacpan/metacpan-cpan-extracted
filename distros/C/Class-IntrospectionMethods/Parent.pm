# $Author: domi $
# $Date: 2004/12/08 12:50:41 $
# $Name:  $
# $Revision: 1.3 $

package Class::IntrospectionMethods::Parent ;
use strict ;
use warnings ;
use Carp ;
use Storable qw/dclone/;
use Data::Dumper ;

require Exporter;
use vars qw/$VERSION @ISA @EXPORT_OK $trace/ ;
@ISA = qw(Exporter);
@EXPORT_OK = qw(set_parent_method_name graft_parent_method set_obsolete_behavior);

$VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)\.(\d+)/;

$trace = 0;

use vars qw( $VERSION );

=head1 NAME

Class::IntrospectionMethods::Parent - Handles parent relationship for Class::IntrospectionMethods

=head1 SYNOPSIS

 No synopsis. Directly used by Class::IntrospectionMethods

=head1 DESCRIPTION

This class handles parent relationship for Class::IntrospectionMethods. 

In other word, for any child object managed by
Class::IntrospectionMethods, it will :

=over

=item *

Create a ParentInfo object that contains 

=over

=item *

the parent object ref (weakened by L<Scalar::Util> C<weaken> function)

=item *

The slot name containing the child

=item *

The index of the element containing the child if the slot is array or
hash based.

=back

=item *

Install a function/method in child's class to retrieve the
ParentInfo object.

=item *

An attribute in child to store the ParentInfo's ref.

=back

By default, the name of the installed function and arribute is
C<cim_parent> but this can be changed by calling
C<set_parent_method_name>.

=cut

my $obsolete_behavior = 'carp' ;
my $support_legacy = 0 ;

sub warn_obsolete
  {
    return if $obsolete_behavior eq 'skip' ;
    no strict 'refs';
    $obsolete_behavior->(@_) ;
  }

=head1 Exported functions

=head2 set_parent_method_name( name )

This function changes the name of the function and attribute names
installed by C<graft_parent_method>. (C<cim_parent> by default)

=cut

my $parent_method_name = 'cim_parent' ;
my $too_late_to_change_name = 0 ;

sub set_parent_method_name
  {
    croak "set_parent_method_name must be called before graft_parent_method"
      if $too_late_to_change_name ;
    $parent_method_name = shift ;
  }

sub set_obsolete_behavior
  {
    $obsolete_behavior = shift;
    $support_legacy = shift ;
  }

=head2 graft_parent_method( child, parent, slot, [index] )

Creates the ParentInfo object, install the C<cim_parent> function in
child's class, store the ParentInfo in child object, finally store
slot and index in ParentInfo object.

=cut

# this function is called anytime a child object is created
sub graft_parent_method 
  {
    my ($child,$parent, $slot, $index) = @_ ;

    $too_late_to_change_name = 1;

    croak "graft_parent_method error: cannot graft method if object is not based on HASH"
      unless $child->isa('HASH') ;

    my $parent_class = ref($parent) ;

    my $subname = ref($child).'::'.$parent_method_name ;

    print "grafting child $subname with an accessor for parent $parent_class $parent\n".
      (defined $slot ? "\tslot is $slot\n" : '') .
	(defined $index ? "\tindex is $index\n" : '' )
	  if $trace ;

    no strict 'refs' ;
    *$subname = sub 
      {
	return shift -> {$parent_method_name} ;
      }
	unless $child -> can($parent_method_name) ;

    my $parent_obj = $child->{$parent_method_name} =
      Class::IntrospectionMethods::ParentInfo
	  -> new( index_value => $index,
		  slot_name   => $slot,
		  parent      => $parent
		) ;

    if ($support_legacy) 
      {
	tie $child->{CMM_SLOT_NAME} , 
	  'Class::IntrospectionMethods::ParentNameTie' , 
	    name => 'CMM_SLOT_NAME',
	      parent => $parent_obj , method => 'slot_name';

	tie $child->{CMM_INDEX_VALUE} , 
	  'Class::IntrospectionMethods::ParentNameTie',
	    name => 'CMM_INDEX_VALUE',
	      parent => $parent_obj, method => 'index_value' ;

	tie $child->{CMM_PARENT} , 
	  'Class::IntrospectionMethods::ParentNameTie',
	    name => 'CMM_PARENT',
	      parent => $parent_obj, method => 'parent' ;

	my $sub_slot_name = ref($child).'::CMM_SLOT_NAME' ;
	*$sub_slot_name = sub 
	  { 
	    warn_obsolete ("CMM_SLOT_NAME method is deprecated") ;
	    my $po = shift ->$parent_method_name() ;
	    return defined $po  ? $po->slot_name : undef; 
	  } unless $child -> can($sub_slot_name) ;

	my $sub_index_name = ref($child).'::CMM_INDEX_VALUE' ;
	*$sub_index_name = sub 
	  { 
	    warn_obsolete ("CMM_INDEX_VALUE method is deprecated") ;
	    my $po = shift ->$parent_method_name() ;
	    return defined $po  ? $po->index_value :undef;
	  } unless $child -> can($sub_index_name)  ;

	my $sub_parent = ref($child).'::CMM_PARENT' ;
	*$sub_parent = sub 
	  { 
	    warn_obsolete ("CMM_PARENT method is deprecated") ;
	    my $po = shift ->$parent_method_name() ;
	    return defined $po  ? ($po->parent(@_)) : (undef) ;
	  } unless $child -> can($sub_parent) ;
      }
  }

=head1 ParentInfo class

A ParentInfo object is created each time the C<graft_parent_method>
function is called.

When, needed, this object is retrieved by calling:

  $child->cim_parent

The the following methods may be applied to retrive the informations
stored durung C<graft_parent_method> call:

=cut

package Class::IntrospectionMethods::ParentInfo ;
use Scalar::Util qw(isweak weaken) ;

sub new
  {
    my $type = shift;
    my $self = {@_ };

    # Necessary to avoid ghost object and memory leaks. See
    # WeakRef module See also "Programming perl" 3rd edition
    # page 266.
    weaken ($self -> {parent}) ;
    bless $self,$type ;
  }

=head2 index_value

Returns the index value of the element containing the child object.
Returns undex if the Class::IntrospectionMethods slot is not hash or
array based.

=cut

sub index_value { return shift -> {index_value} ;}

=head2 index_value

Identical to index_value. This method may be preferred for hash based
slots. (This is just syntactical sugar).

=cut

sub key_name    { return shift -> {index_value} ;}



=head2 slot_name

Returns the name of the IntrospectionMethods slot containing the child
object. 

=cut

sub slot_name   { return shift -> {slot_name} ;}

=head2 parent

Returns the parent object containing child.

=cut

sub parent
  {
    my $self = shift ; 
    my $parent = shift ;
    if (defined $parent)
      {
	# Necessary to avoid ghost object and memory leaks. See
	# WeakRef module See also "Programming perl" 3rd edition
	# page 266.
	weaken ($self -> {parent} = $parent) ;
      }
    return $self->{parent}
  }


# This class is provided for backward compatibility for an older
# projet (the one that used a modified version of Class::MethodMaker)
# Do not use.

package Class::IntrospectionMethods::ParentNameTie ;

require Tie::Scalar;
use Carp ;
use vars qw/@ISA/ ;

@ISA = ('Tie::Scalar');

sub TIESCALAR 
  {
    my $type = shift;
    my $self = { @_ } ;
    bless $self, $type;
  }

sub FETCH
  {
    my $self = shift;
    Class::IntrospectionMethods::Parent::warn_obsolete("Reading directly $self->{name} is deprecated");
    my $m = $self->{method} ;
    return $self->{parent}->$m(@_)
  }

sub STORE
  {
    my $self = shift;
    croak "Writing directly to $self->{name} is forbidden";
  }
1;

__END__

=head1 EXAMPLE

 package X ;
 
 use Class::IntrospectionMethods 
   qw/make_methods set_parent_method_name/;
 
 set_parent_method_name('metadad') ;
 
 make_methods
   (
    'parent',
 
    hash => 
    [
     a => {
 	  tie_hash      => ['MyHash', dummy => 'booh'],
 	  class_storage => ['MyObj', 'a' => 'foo']
 	 },
    ],
 
    new => 'new' 
   );
 
 package main;
 
 my $o = new X;
 
 my $obj = $o->a('foo') ;
 my $info = $obj->metadad ;
 
 my $p= $info->parent; # $p is $o
 print $info->slot_name; # -> 'a'
 print $info->index_value; # -> 'foo'
 
 # check parent method on object behind tied hash
 my $tied_hash_obj = $o->tied_hash_a ;
 my $p2 = $tied_hash_obj->metadad->parent; # $p2 is $o

=head1 COPYRIGHT

Copyright (c) 2004 Dominique Dumont. All rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

  L<Class::IntrospectionMethods>

=cut
