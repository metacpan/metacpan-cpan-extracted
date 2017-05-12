#!/usr/bin/perl -Tw

# $Id: Hash.pm 1518 2010-08-22 23:56:21Z ian $
package Class::Declare::Hash;

use strict;

=head1 NAME

Class::Declare::Hash - generate a hash of accessible attributes

=head1 SYNOPSIS

This module should not be used directly; it is a helper module for
L<Class::Declare>, providing the B<hash()> routine.

=cut


use base  qw( Class::Declare     );
use vars  qw( $REVISION $VERSION );

  $REVISION = '$Revision: 1518 $';
  $VERSION  = '0.20';	# Class::Declare->VERSION;


=head1 DESCRIPTION

B<Class::Declare::Hash> adds a detailed B<hash()> method to L<Class::Declare>,
allowing retrieval of an attribute/value hash representing a given
L<Class::Declare> derived object. This method is only installed (and indeed,
this module only compiled) if B<hash()> is called on a
L<Class::Declare>-derived object or package.

=cut
{ # closure for hash() related methods and variables

  #
  # Closure variables
  #
  
  # references to subroutines that permit access to some of the
  # Class::Declare data structures use to marshal objects and classes
  my  $__GET_ATTRIBUTES__;  undef $__GET_ATTRIBUTES__;
  my  $__GET_VALUES__;      undef $__GET_VALUES__;
  my  $__GET_FRIENDS__;     undef $__GET_FRIENDS__;


  # __init__()
  #
  # __init__() is used to obtain references to anonymous subroutines that
  # give access to the %__ATTR__, %__FRIEND__ and %__DEFN__ hashes of
  # Class::Declare. See the comment in Class::Declare::hash() for an
  # explanation.
  sub __init__ : method
  {
    my  $class  = __PACKAGE__->class( shift );
    # what's our method name?
    my  $sub    = ( caller 1 )[ 3 ];

    # make the reference assignment (only if it hasn't been done
    # before)
    $__GET_ATTRIBUTES__ = $_[ 0 ] unless ( defined $__GET_ATTRIBUTES__ );
    $__GET_VALUES__     = $_[ 1 ] unless ( defined $__GET_VALUES__     );
    $__GET_FRIENDS__    = $_[ 2 ] unless ( defined $__GET_FRIENDS__    );

    1;  # that's all: hack complete :)
  }


  # %__REFERENCES__
  #
  # Store attribute references for showing equality in the hash.
  my  %__REFERENCES__;  undef %__REFERENCES__;

  # %__CALLER__
  #
  # Store the caller information for the original call to hash()
  my  %__CALLER__;      undef %__CALLER__;


  #
  # Closure methods
  #

  # $__permission__()
  #
  # For a given caller stack (as stored by $__save__() below) and target
  # object (passed in as the first argument), determine if we have a given
  # permission (e.g. public, private, protected, etc). Return true if we
  # do, false otherwise.
  #
  # NB: these routines have been lifted directly from Class::Declare.
  my  $__permission__ = sub { # <access level> => <target>
      my  $type   = shift;  # the access control type
      my  $target = shift;  # the object of interest
      my  $class  = shift;  # the target class
      
      # NB: the target class is not necessarily the same class as the
      #     target since methods/attributes may be inherited, in which
      #     case they belong to a different class

      # we need to know the calling context for this permission test -
      # this will either be passed in as the third argument, or we can
      # take it from the original calling context

      # first, we must be certain that the target is derived from
      # Class::Declare
      return undef      unless ( UNIVERSAL::isa( $target          ,
                                                 'Class::Declare' ) );

      # if we're testing class or abstract attributes, then that's all we need
      return 1              if ( $type eq 'class'    );
      return 1              if ( $type eq 'abstract' );

      # if we're testing public attributes, then return true if this
      # is a reference to an object
      return ref( $target ) if ( $type eq 'public' );

      # OK, from here we're dealing with either restricted, protected,
      # static or private attributes

      # get the friends of the target class
      my  $friend = $__GET_FRIENDS__->( $class ) || {};

      # if the caller is not in the same or a derived package, or is
      # not a friend, then we can't proceed
      my  $caller = $__CALLER__{ package    };
      my  $sub    = $__CALLER__{ subroutine };
      return undef  unless (    UNIVERSAL::isa( $caller , $class  )
                             || UNIVERSAL::isa( $class  , $caller )
                             || $caller && exists $friend->{ $caller }
                             || $sub    && exists $friend->{ $sub    }
                           );

      # OK, if we're looking for restricted attributes we're done
      return 1              if ( $type eq 'restricted' );

      # if we're looking for protected attributes, then we need a
      # reference to return true
      return ref( $target ) if ( $type eq 'protected' );

      # if the class is the same as the defining class then we can
      # access static/private attributes, otherwise fail
      return undef    unless (            $class   eq  $caller
                               ||         $class->isa( $caller )
                               || exists $friend->{    $caller }
                               || exists $friend->{    $sub    } );

      # that's all we need to check for static attributes
      return 1              if ( $type eq 'static' );

      # otherwise, we need to make sure we have a reference for
      # private attributes
      return ref( $target ) if ( $type eq 'private' );

      return undef; # permission denied
    }; # $__permission__()


  # # $__save__()
  #
  # Save original calling state.
  my  $__save__ = sub { # <object> <argument list reference>
      # need to store the original caller stack so that hash()
      # can determined public(), private(), etc rights for the
      # calling routine/context
      $__CALLER__{ package    } = ( caller 1 )[ 0 ];
      $__CALLER__{ subroutine } = ( caller 2 )[ 3 ];

      # reset the references store
      undef %__REFERENCES__;
    }; # $__save__()


  # $__clear__()
  #
  # Clear original calling state.
  my  $__clear__  = sub {
      # clear the caller stack
      %__CALLER__ = ();

      # reset the references store
      undef %__REFERENCES__;
    }; # $__clear__()


  # $__hash__()
  #
  # Perform a recursive hash() expansion for a given value
  my  $__hash__;
      $__hash__   = sub { # <r> , <depth> , <args>
      my  $r          = shift;
      my  $depth      = shift;

      # if depth is zero, then return the value we have
      return $r       unless ( ! defined $depth || $depth > 0 );

      # if the value is undefined, then return undefined
      return undef    unless (   defined $r );

      # if we don't have a reference, then return the supplied value
      return $r       unless (       ref $r );

      # reduce the depth (if defined)
          $depth--        if (   defined $depth );

      # we have a reference value
      #   - if it's an object derived from Class::Declare, then we should
      #     call its hash() method and perform a recursive expansion
      #   - if it's an ARRAY or HASH, we should iterate through its values
      #     and attempt to expand them (if possible)
      foreach ( ref $r ) {
        # array
        /^ARRAY$/o  && do {
          my  $ref  = [];
          push @{ $ref } , scalar $__hash__->( $_ , $depth , @_ )
                                                        foreach ( @{ $r } );

          # return the generated array
          return $ref;
        };

        # hash
        /^HASH$/o   && do {
          my  $ref          = {};
          while ( my ( $k , $v ) = each %{ $r } ) {
              $ref->{ $k }  = $__hash__->( $v , $depth , @_ )
          }

          # return the generated hash
          return $ref;
        };

        # are we dealing with a Class::Declare object that supports the hash()
        # method?
        #   - if so, recurse through that
            UNIVERSAL::isa( $r , 'Class::Declare' )
        and UNIVERSAL::can( $r , 'hash'           )
        and return scalar $r->hash( @_ , depth => $depth );
      }

      # if we've made it this far, then simply return the value passed in
      return $r;
    };  # $__hash__()


# jump into the Class::Declare namespace to create the dump() routine
package Class::Declare;


# hash()
#
# Generate a textual representation of the object/class
sub hash : method
{
  my  $self   = Class::Declare->class( shift );
  my  $class  = ref( $self ) || $self;

  # OK, parse the arguments
  my  $_args  = $self->arguments( \@_ => { public     => undef ,
                                           private    => undef ,
                                           protected  => undef ,
                                           class      => undef ,
                                           static     => undef ,
                                           restricted => undef ,
                                           abstract   => undef ,
                                           depth      => undef ,
                                           backtrace  => 1     ,
                                           all        => 1     } );

  # have we been called from outside this file
  # i.e. is this a non-recursive call (first call)
  my  $outside  = ( caller )[ 1 ] ne __FILE__;

  # if we're called from outside this file (i.e. it's not an
  # internal recursive call to hash()) then make
  # note of the arguments and the context
    $__save__->( $self , $_args ) if ( $outside );

  # store the current depth limit
  my  $depth    = delete $_args->{ depth };

  # unset 'all' if any of the other arguments have been set
  ( $_args->{ $_ } )
    and delete $_args->{ all }
    and last
      foreach ( qw( public private protected  abstract
                    class  static  restricted          ) );

  # if we have asked for nothing, then return undef
  return undef    unless ( grep { defined }
                                map { $_args->{ $_ } }
                                    qw( public private protected  abstract
                                        class  static  restricted all      ) );

  # next, we need to check to ensure the user has permission to access the
  # specified attribute types for the given object
  #   - this test should only be done at the top level
  if ( $outside ) {
    # make sure we have permission to access the specified attribute types
    # or raise a fatal error (in keeping with the behaviour of
    # Class::Declare
    ( $__permission__->( $_ => $self => ref( $self ) || $self )
    # also, if we don't have a reference, then we should raise an error
    # if instance attributes have been requested
      && ( ref( $self ) || !/^public$/o
                        && !/^private$/o
                        && !/^protected$/o ) )
      or do {
        # find out where the call to dump() was made
        my  ( undef , $file , $line , $sub )  = caller 0;

        # die with an informative error message
        die "access to $_ attributes denied in call to "
            . "$sub() at $file line $line\n";
      } foreach ( grep { $_args->{ $_ } }
                       grep {    !/all/o
                              && !/backtrace/o
                            } keys %{ $_args } );
  }

  # determine the attribute types that may be returned/have been requested
  # NB: if required, as this is first calculated during the
  #     top-level call to hash()
  my  @types  = qw( abstract class  static  restricted
                             public private protected  );
      @types  = grep { $_args->{ $_ } } @types  unless ( $_args->{ all } );

  # generate the combined @ISA array for this class
  my  @isa  = ( $class );
  my  $i    = 0;
  while ( $i <= $#isa ) {
    no strict 'refs';

    my  $pkg  = $isa[ $i++ ]  or next;
    push @isa , @{ $pkg . '::ISA' };
  }
  # remove the duplicates and reverse
    @isa  = local %_ || grep { ! $_{ $_ }++ } reverse @isa;

  # construct the list of public, private, class, etc attributes
  # for this class (taking into account inheritance)
  my  %map; undef %map;
  ISA: foreach my $isa ( @isa ) {
    my  $ref  = $__GET_ATTRIBUTES__->( $isa )   or next ISA;

    while ( my ( $k , $v ) = each %{ $ref } ) {
      $map{ $_ }  = { type => $k , class => $isa }  for ( @{ $v } );
    }
  }
  # now build a reverse map of type to attribute
  my  %rmap;  undef %rmap;
  foreach my $attr ( keys %map ) {
    my  $type = $map{ $attr }->{ type };

    push @{ $rmap{ $type } } , $attr;
  }

  # define a map for determining if a given attribute may be accessed
  # through the given object/class
  # NB: this takes into account the class defining the attribute, not
  #     just the class/object trying to access it
  my  $perm = sub {
      my  $object = shift;
      my  $attr   = shift;

      # extract the attribute type and the class defining the
      # attribute
      my  ( $type , $class )  = map { $map{ $attr }->{ $_ } }
                                    qw( type class );

      return $__permission__->( $type => $object => $class );
    }; # $perm()

  # get the object/class hash for this target
  #   - if we have an object, simply pass the object
  #   - otherwise, if we have a class, loop through all classes in its
  #       @ISA array
  my  $hash = ( ref $self ) ? $__GET_VALUES__->( $self )
                            : { map { %{ $_ } }
                                    grep { defined }
                                         map { $__GET_VALUES__->( $_ ) }
                                             @isa
                              };

  # generate the return hash
  my  %rtn;   undef %rtn;

  HASH: foreach my $type ( grep { exists $rmap{ $_ } } @types ) {
    # print the attribute values we have access to
    ATTR: foreach my $attr ( sort grep { $perm->( $self => $_ ) }
                                       map { @{ $_ } }
                                           grep { defined }
                                                $rmap{ $type } ) {

      # what value do we have?
      my  $v            = $hash->{ $attr };

      # if this is a reference
      if ( ref $v ) {
        # if we have backtrace turned on, then check to see if we have
        # seen this reference before
        my  $r          = $__REFERENCES__{ $v };

        # if we've not seen this reference before, then we should attempt
        # to expand it
        unless ( defined $r ) {
          # if we have not reached our depth limit, then recurse if we need to
          #   - if the depth has not been given, then we descend as far
          #     as we can
          #   - NOTE: this is a change in default behaviour since v0.08
          if ( ! defined $depth || $depth > 0 ) {
            # generate the expansion of this value
            #   - decrement the depth count
            #$depth--      if ( defined $depth );
            $r          = $__hash__->( $v , $depth , %{ $_args } );
          }

          # if we don't have a reference, then use the original value
            $r        ||= $v;

          # the value we have now is all we are going to get for this
          # attribute, so make sure it's stored (if we have backtracing turned
          # on)
            $__REFERENCES__{ $v } =  $r     if ( $_args->{ backtrace } );
        }

        # use whatever expansion we have obtained
          $v            = $r;
      }

      # record the expansion for this attribute
          $rtn{ $attr } = $v;
    }
  }

  # if this is the final exit of hash() (i.e. this execution frame
  # corresponds to the original invocation of hash() and not an internal
  # recursive call, then we should clear the saved state information
    $__clear__->()    if ( $outside );

  # do we want a hash, or a has reference?
  return ( wantarray ) ? %rtn : \%rtn;
} # hash()

} # end hash() closure


=head1 SEE ALSO

L<Class::Declare>

=head1 AUTHOR

Ian Brayshaw, E<lt>ibb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2016 by Ian Brayshaw. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

############################################################################
1;  # end of module
__END__
