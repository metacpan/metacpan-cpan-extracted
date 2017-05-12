# $Author: domi $
# $Date: 2004/12/13 12:20:10 $
# $Name:  $
# $Revision: 1.4 $

package Class::IntrospectionMethods::Catalog ;
use strict ;
use warnings ;
use Carp ;
use Storable qw/dclone/;
use Data::Dumper ;

require Exporter;
use vars qw/$VERSION @ISA @EXPORT_OK @CARP_NOT/ ;
@ISA = qw(Exporter);
@EXPORT_OK = qw(set_global_catalog set_method_info set_method_in_catalog);
@CARP_NOT=qw/Class::IntrospectionMethods/ ;

$VERSION = sprintf "%d.%03d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

my $obsolete_behavior = 'carp' ;
my $support_legacy = 0 ;

sub set_obsolete_behavior
  {
    $obsolete_behavior = shift;
    $support_legacy = shift ;
  }

sub warn_obsolete
  {
    return if $obsolete_behavior eq 'skip' ;
    no strict 'refs';
    $obsolete_behavior->(@_) ;
  }

=head1 NAME

Class::IntrospectionMethods::Catalog - manage catalogs from IntrospectionMethods

=head1 SYNOPSIS

 No synopsis. Directly used by Class::IntrospectionMethods

=head1 DESCRIPTION

This class handles slot catalogs for L<Class::IntrospectionMethods>.

=cut

# These lexical variables are also used in ClassCatalog and
# ObjectCatalog
my %construction_info ;
my %catalog_info ;

=head1 Exported functions

=head2 set_method_info( target_class, method_name, info_ref )

Store construction info for method C<method_name> of class
C<target_class>.

=cut

sub set_method_info
  {
    my ($target_class, $maker_slot_name, $info) = @_ ;
    $construction_info{$target_class}{$maker_slot_name} = $info ;
  }

=head2 set_global_catalog (target_class, ...)

Store catalog informations. The first parameter is the class featuring
the methods declared in the global catalog.

Following paramaters is a set of named paramaters (e.g. key => value):

=over

=item name

Mandatory name for the global catalog

=item list

array ref containing the list of slot and catalog. E.g.:

 list => [
	   [qw/foo bar baz/] => foo_catalog,
	   [qw/a b z/]       => alpha_catalog,
	   my_object         => my_catalog
	 ],

=item isa

Optional hash ref declaring a containment for catalog. E.g:

  list => [ 'foo' => 'USER' ,
            'admin' => 'ROOT' ],
  isa  => { USER => 'ROOT' }

Then the 'ROOT' catalog will return 'foo', and the 'USER' catalog will
return 'foo' and 'admin'.

=item help

Optional hash ref (C<< slot_name => help >>). Store some help
information for each slot.

=back

set_global_catalog will construct:

=over

=item *

A ClassCatalog object containing the global catalog informations.

=item *

A sub_ref containing the ClassCatalog object in a closure.

=back

Returns ( C<slot_name>, sub_ref ). The sub_ref is to be installed in
the target class.

When called as a class method, the subref will return the ClassCatalog
object. When called as a target class method, the subref will return
an ObjectCatalog object associated to the ClassCatalog object stored
in the closure.

These 2 object have the same API. ObjectCatalog is used to contain
catalog changes that may occur at run-time. ClassCatalog informations
will not change.

=cut

# the closures defined here have a class scope not an object
# scope. I.e there's one storage per class

sub set_global_catalog 
  {
    my $target_class = shift ;
    my %arg = @_ ;

    my $global_catalog_name = delete $arg{name} 
      or croak "set_global_catalog: no name defined";

    # get list of slot -> catalog
    croak "set_global_catalog: no list defined" unless defined $arg{list};

    # this object is stored in the closure below
    my $class_catalog = Class::IntrospectionMethods::ClassCatalog
      -> new ( target_class => $target_class, %arg ) ;

    my $sub = sub
      {
	my $self = shift ;
	return $self->{$global_catalog_name} ||=
	  Class::IntrospectionMethods::ObjectCatalog -> 
	      new ( class_catalog => $class_catalog ) if ref $self;
	return $class_catalog ;
      } ;

    $catalog_info{$target_class}=$sub ;

    my @methods = ($global_catalog_name, $sub  ) ;

    return @methods ;
  }

sub set_method_in_catalog
  {
    my ($target_class,$slot,$catalog) = @_ ;

    croak "set_global_catalog was not called for class $target_class, ",
      "Did you forgot to 'global_catalog' parameter in make_methods call ?"
      unless defined $catalog_info{$target_class} ;

    my $f = $catalog_info{$target_class} ;

    &$f->add($slot,$catalog) ;
  }

1;

package Class::IntrospectionMethods::AnyCatalog ;
use Carp;

# data : { catalog_list => { catalog_a => [slot1 slot2],
#                            catalog_b => [slot2 slot3]},
#          slot_list    => { slot1 => [catalog_a],
#                            slot2 => [catalog_a catalog_b],
#                            slot3 => [catalog_b]} },
#          ordered_slot_list => [ slot1 slot2 slot3 ]

sub all {confess "deprecated"} 

sub rebuild
  {
    my $self = shift ;

    # reset and rebuild slot list from catalog_list
    delete $self->{slot_list} ;
    foreach my $catalog (sort keys %{$self->{catalog_list}} ) 
      {
	map{ push @{$self->{slot_list}{$_}}, $catalog ;} 
	  @{$self->{catalog_list}{$catalog}} ;
      }
  } ;

=head1 ClassCatalog or ObjectCatalog methods

=cut

=head2 catalog( slot_name )

Returns the catalogs names containing this slot (does not take into
accounts the isa stuff)

Return either an array or an array ref depending on context.

=cut

sub catalog
  {
    my ($self, $slot_name) = @_ ;

    croak "catalog: Missing slot name"
      unless defined $slot_name;

    # returns the catalogs names containing this slot (does not take
    # into accounts the isa stuff)
    my $slist = $self->{slot_list} ;

    croak "catalog: unknown slot $slot_name, expected",
      join(',',keys %$slist)
	unless defined $slist->{$slot_name};

    my @result = @{$slist->{$slot_name}} ;

    return wantarray ? @result : \@result ;
  }

=head2 slot ( catalog_name, ... )

Returns the slots contained in the catalogs passed as
arguments. (takes into accounts the isa parameter)

=cut

sub slot
  {
    my $self = shift ;
    my @all_cats = @_ ;

    croak "slot: Missing catalog name" unless @_ ;

    my $clist = $self->{catalog_list} ;

    foreach my $catalog_name (@all_cats) 
      {
	if (not defined $clist->{$catalog_name})
	  {
	    if ($support_legacy)
	      {
		$self->{catalog_list}{$catalog_name} = [] ;
		$self->{class_catalog}->add_catalog($catalog_name) ;
		Class::IntrospectionMethods::Catalog::warn_obsolete
		    ("Warning: undeclared catalog $catalog_name, Created ...");
	      }
	    else
	      {
		croak "slot: unknown catalog $catalog_name, expected",
		  join(',',keys %$clist) ;
	      }
	  }
      }

    # add inherited catalogs
    push @all_cats,
      map {$self->catalog_isa($_)} @all_cats ;

    #print "slot: @_ is @all_cats\n";
    my @result ;
    foreach my $slot (@{$self->ordered_slot_list()})
      {
        my @c = @{$self->{slot_list}{$slot}} ;
        my %c ;
        foreach my $c (@c) {$c{$c} = 1}
        my %isect ;
        foreach my $c (@all_cats) { $isect{$c} = 1 if $c{$c} }

        push @result, $slot if scalar keys %isect ; 
      }  ;

    #print "result is @result\n";
    return wantarray ? @result : \@result ;
  }

=head2 all_slot()

Return a list of all slots (respecting the order defined in
global_catalog).

=cut

sub all_slot
  {
    my $self = shift;
    return @{$self->ordered_slot_list} ;
  }

=head2 all_catalog()

Returns a sorted list of all defined catalogs.

=cut

sub all_catalog
  {
    my ($self) = @_ ;
    return sort keys %{$self->{catalog_list}} ;
  }

#internal
sub update_catalog_list
  {
    my $self = shift ;

    # reset and update catalog lists (which is somewhat different from rebuild)
    delete $self->{catalog} ;
    foreach my $slot (sort keys %{$self->{slot_list}} ) 
      {
        map{ push @{$self->{catalog_list}{$_}}, $slot ;} 
          @{$self->{slot_list}{$slot}} ;
      }
 }

package Class::IntrospectionMethods::ObjectCatalog ;

use Carp;
use Storable qw(dclone) ;
use vars qw($AUTOLOAD @ISA);

@ISA = qw/Class::IntrospectionMethods::AnyCatalog/ ;

sub new
  {
    my $type =shift ;
    my $self = { @_ } ;

    croak __PACKAGE__,"->new: no class_catalog given" unless defined
      $self->{class_catalog} ;

    $self->{slot_list} = 
      dclone($self->{class_catalog}->slot_list() ) ;

    bless $self, $type ;
    $self->update_catalog_list ;

    return $self ;
  }

=head1 ObjectClass methods

Unknown methods will be forwarded to associated ClassCatalog object.

=head2 change( slot_name, catalog_name )

Move the slot into catalog C<catalog_name>.

=cut

sub change
  {
    my ($self, $slot_name, $catalog_name) = @_ ;

    croak "set_catalog, change command: Missing slot name"
      unless defined $slot_name;
    croak "set_catalog, change command: Missing catalog name"
      unless defined $catalog_name;

    # check new catalog
   my @cat = ref $catalog_name ? sort @$catalog_name : ($catalog_name) ;
    map 
      {
	if (not defined $self->{catalog_list}{$_})
	  {
	    if ($support_legacy) 
	      {
		Class::IntrospectionMethods::Catalog::warn_obsolete("Warning: Undeclared catalog $_. Created...");
		$self->{class_catalog}->add_catalog($_);
		$self->{catalog_list}{$_} = [ $slot_name ] ;
	      }
	    else
	      {
		croak "set_catalog, change command: unknown catalog ",
		  "$catalog_name, expected '",
		    join("','",keys %{$self->{catalog_list}}),"'\n"
	      }
	  }
      } @cat ;

    # move slot from older catalog(s) to other(s)
    $self->{slot_list}{$slot_name} = \@cat ;

    $self->update_catalog_list ;

    return @cat ;
  }

=head2 reset( slot_name )

Put back slot in catalog as defined by global_catalog (and as stored
in ClassCatalog).

=cut

sub reset
  {
    my ($self, $slot_name) = @_ ;

    croak "set_catalog, change command: Missing slot name"
      unless defined $slot_name;

    # move slot from older catalog(s) to other(s)
    my @cat = $self->{class_catalog}->catalog($slot_name);
    $self->{slot_list}{$slot_name} = \@cat ; ;

    $self->update_catalog_list ;

    return @cat ;
  } ;

# Used to provide legacy
sub add
  {
    my ($self, $slot,$catalog) = @_ ;

    my @cat = ref $catalog ? @$catalog : ($catalog) ;
    map { push @{$self->{catalog_list}{$_}}, $slot;} @cat ;
    $self->{slot_list}{$slot} = \@cat ;

    $self->{class_catalog}->add($slot,$catalog) ;
  }

# forward unknown method to associated ClassCatalog
sub AUTOLOAD
  {
     my $meth = $AUTOLOAD;
     $meth =~ s/.*:://;
     return if $meth eq 'DESTROY' ;
     shift -> {class_catalog} -> $meth(@_) ;
  }

package Class::IntrospectionMethods::ClassCatalog ;

use Carp;
use vars qw($AUTOLOAD @ISA);

@ISA = qw/Class::IntrospectionMethods::AnyCatalog/ ;

sub new
  {
    my $type = shift ;

    my $self = { @_ } ;

    my @user_list = @{$self -> {list}} ;
    while (@user_list)
      {
	my ($slot,$cat) = splice @user_list,0,2 ;
	my @slot = ref $slot ? @$slot : ($slot) ;
	my @cat = ref $cat ? @$cat : ($cat) ;
	map 
	  {
	    push @{$self->{ordered_slot_list}}, $_ ;
	    $self->{slot_list}{$_} = \@cat ;
	  } @slot
      }

    bless $self, $type ;
    $self->update_catalog_list ;

    return $self ;
  }

sub slot_list
  {
    return $_[0]->{slot_list} ;
  }

sub ordered_slot_list
  {
    return $_[0]->{ordered_slot_list} ;
  }

sub catalog_list
  {
    return $_[0]->{catalog_list} ;
  }


# To support legacy, catalogs can be added at run_time not sure it's a
# good idea for new application (too many way to mess things up)
sub add_catalog
  {
    my ($self, $catalog) = @_ ;
    $self->{catalog_list}{$catalog} ||= [] ;
  }

sub add
  {
    my ($self, $slot,$catalog) = @_ ;
    push @{$self->{ordered_slot_list}}, $slot ;

    my @cat = ref $catalog ? @$catalog : ($catalog) ;
    map { push @{$self->{catalog_list}{$_}}, $slot;} @cat ;
    $self->{slot_list}{$slot} = \@cat ;
  }

=head1 ClassCatalog methods

=head2 help ( slot_name )

Return the help info for slot_name that was given to
set_global_catalog. Return an empty string if no help was
provided. This help method is just a place holder, no fancy treatment
is done.

=cut

sub help
  {
    my $self = shift;
    return $self->{help}{$_[0]} || '';
  }

sub catalog_isa
  {
    my ($self,$catalog_name)= @_ ;

    croak "set_catalog, isa command: Missing catalog name"
      unless defined $catalog_name;

    my @result ;
    my $next = $catalog_name ;
    my $isa = $self->{isa} ;
    while (defined $isa->{$next})
      {
	push @result, $next = $isa->{$next} ;
      }
    return @result ;
  }

=head2 info ( slot_name )

Returns construction informations of slot_name. This is handy for
introspection of actual properties of slot C<slot_name>.

The details are returned in an array that contains:

=over 8

=item *

The slot type: i.e. either C<slot_type =E<gt> scalar>, 
C<slot_type =E<gt> array> or C<slot_type =E<gt> hash>.

=item *

If the index is tied (for C<array> or C<hash> slot type), the array
will contain: C<tie_index =E<gt> $tie_class>. If some constructor
arguments are used, the array will also contain C<tie_index_args
=E<gt> \@args>.

=item *

If the target value (i.e. the scalar) is tied (for all slot types),
the array will contain: C<tie_scalar =E<gt> $tie_class>. If some constructor
arguments are used, the array will also contain 
C<tie_scalar_args =E<gt> \@args>.

=item *

If the target value (i.e. the scalar) is a plain object (for all slot
types), the array will contain: C<class =E<gt> $class>. If some
constructor arguments are used, the array will also contain 
C<class_args =E<gt> \@args>.

=back

=cut

sub info
  {
    my ($self, $slot_name) = @_ ;

    my $tgt = $self->{target_class} ;

    my $result =  $construction_info{$tgt}{$slot_name};

    croak "no info on slot $slot_name (class $tgt)" unless
      defined $result ;
    return wantarray ? (ref $result eq 'HASH' ? %$result : @$result ) : $result ;
  }

1;

__END__

=head1 EXAMPLE

 package X ;
 use ExtUtils::testlib;
 
 use Class::IntrospectionMethods qw/make_methods set_obsolete_behavior/;
 
 make_methods
   (
    # slot order is important in global_catalog (and will be respected)
    global_catalog => 
    {
     name => 'metacat',
     list => [
 	     [qw/foo bar baz/]                 => foo_cat,
 	     [qw/a b z/] 		       => alpha_cat,
 	     [qw/stdhash my_object my_scalar/] => my_cat
 	    ],
     isa => { my_cat => 'alpha_cat'} # my_cat includes alpha_cat
    },
    get_set => [qw/bar foo baz/],
 
    hash => 
    [
     a => {
           tie_hash      => ['MyHash', dummy => 'booh'],
           class_storage => ['MyObj', 'a' => 'foo']
          },
     [qw/z b/] => {
                   tie_hash => ['MyHash'],
                   class_storage => ['MyObj', 'b' => 'bar']
                  },
     stdhash => {
                 class_storage => ['MyObj', 'a' => 'foo']
                }
    ],
 
    object => [ 'my_object' => 'MyObj'  ],
    tie_scalar => [ 'my_scalar' => ['MyScalar' , foo => 'bar' ]] ,
    new => 'new' 
   );
 
 package main;
 
 # class catalog
 my $class_cat_obj = &X::metacat ;
 
 print $class_cat_obj->all_catalog];
 # -> alpha_cat foo_cat my_cat
 print $class_cat_obj->slot('foo_cat') ;
 # -> foo bar baz
 print $class_cat_obj->slot('alpha_cat');
 # -> a b z
 print $class_cat_obj->slot('my_cat');
 # -> a b z stdhash my_object my_scalar
 print $class_cat_obj->catalog('a');
 # -> alpha_cat
 print $class_cat_obj->info('my_object');
 # -> slot_type scalar class MyObj
 
 # more complex info result
 my @result = $class_cat_obj->info('a') ;
 
 # @result is :
 #	  [
 #	   'slot_type', 'hash',
 #	   'class', 'MyObj',
 #	   'class_args', ['a', 'foo'],
 #	   'tie_index', 'MyHash',
 #	   'tie_index_args', ['dummy', 'booh']
 #	  ], 
 
 
 @result = $class_cat_obj->info('my_scalar') ;
 
 # @result is :
 #	  [
 #	   'slot_type', 'scalar',
 #	   'tie_scalar', 'MyScalar',
 #	   'tie_scalar_args', ['foo', 'bar']
 #	  ], "test class_cat_obj->info('my_scalar')") ;
 
 # object catalog
 
 my $o = new X;
 my $cat_obj = $o->metacat ;
 
 print $cat_obj->all_catalog;
 # -> alpha_cat foo_cat my_cat
 print $cat_obj->slot('foo_cat');
 # -> foo bar baz
 
 # moving a slot
 print $class_cat_obj->catalog('stdhash') ;
 # -> my_cat
 
 $cat_obj->change('stdhash' => 'foo_cat') ;
 
 # class catalog has not changed
 print $class_cat_obj->catalog('stdhash') ;
 # -> my_cat
 
 # my_cat does no longer feature stdhash
 print $cat_obj->slot('my_cat');
 # -> a b z my_object my_scalar
 
 # stdhash is now in foo_cat
 print $cat_obj->slot('foo_cat') ;
 # -> foo bar baz stdhash
 
 print $cat_obj->catalog('stdhash');
 # -> foo_cat

=head1 COPYRIGHT

Copyright (c) 2004 Dominique Dumont. All rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.


=head1 SEE ALSO

  L<Class::IntrospectionMethods>
