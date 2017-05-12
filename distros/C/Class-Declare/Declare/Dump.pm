#!/usr/bin/perl -Tw

# $Id: Dump.pm 1518 2010-08-22 23:56:21Z ian $
package Class::Declare::Dump;

use strict;

=head1 NAME

Class::Declare::Dump - provide object dump routine for Class::Declare

=head1 SYNOPSIS

This module should not be used directly; it is a helper module for
L<Class::Declare>, providing the B<dump()> routine.

=cut


use base  qw( Class::Declare     );
use vars  qw( $REVISION $VERSION );

  $REVISION = '$Revision: 1518 $';
  $VERSION  = '0.20';	# Class::Declare->VERSION;


=head1 DESCRIPTION

B<Class::Declare::Dump> adds a detailed B<dump()> method to L<Class::Declare>,
allowing inspection of L<Class::Declare> derived objects. This method is only
installed (and indeed, this module only compiled) if B<dump()> is called on
a L<Class::Declare>-derived object or package.

=cut
{ # closure for dump() related methods and variables

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
  # Class::Declare. See the comment in Class::Declare::dump() for an
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
  # Store attribute references for showing equality in the dump.
  my  %__REFERENCES__;  undef %__REFERENCES__;

  # $__INDENT__
  #
  # Current indentation level for this invocation
  my  $__INDENT__;      undef $__INDENT__;

  # $__ARGS__
  #
  # Original calling arguments for dump(), minus the
  # object/instance/class
  my  $__ARGS__;        undef $__ARGS__;

  # %__CALLER__
  #
  # Store the caller information for the original call to dump()
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
      return undef      unless ( $target->isa( 'Class::Declare' ) );

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
      return undef  unless (    $caller->isa( $class  )
                             ||  $class->isa( $caller )
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


  # $__isnum__()
  #
  # Return true if the first argument is a number.
  #   - should probably use Scalar::Util, but for now we'll stick with this
  my  $__isnum__  = sub {
        # certain strings can cause the lines after this one to throw a
        # warning, so let's try to catch it out
        return 0        if ( $_[ 0 ] =~ /\W/o );

        # suppress all warnings from the eval() call
        local $SIG{ __WARN__ }  = sub {};

        my  $value  = ( eval $_[ 0 ] ) || $_[ 0 ];
        return ( ( $value & ~$value ) eq '0' );
      }; # $__isnum__()

  # $__quote__()
  #
  # Return the quoted representation of a scalar value
  #   i.e. strings are singly quoted, with appropriate escaping,
  #   and numbers are left as is
  #  NB: if we're given a reference, then that reference is simply
  #      stringified
  my  $__quote__  = sub {
        # if we have an undefined value return the string
        # 'undef'
        return 'undef'      unless ( defined $_[ 0 ] );

        # if this is just a number, then don't quote it
        return   $_[ 0 ]    if ( $__isnum__->( $_[ 0 ] ) );

        # if we've got a reference, then just stringify it
        return  "$_[ 0 ]"   if ( ref $_[ 0 ] );

        # otherwise, should quote
        return "'$_[ 0 ]'";
      }; # $__quote__()


  # $__dump__()
  #
  # Return a string representation for a given value.
  my  $__dump__;
    $__dump__ = sub { # <value> [<depth>]
        # if we're at the bottom of our recursion, then
        # simply return the value given
        return $__quote__->( $_[ 0 ] )
            unless ( ! defined $_[ 1 ] || $_[ 1 ] > 0 );

        # set the depth for (possibly) limiting recursion
        #   - if the depth is defined, then decrement it
        my  $depth  = $_[ 1 ];
            $depth--      if ( defined $depth );

        # otherwise, we should examine this value and recurse
        # accordingly

        # if we don't have a reference, then just return the
        # correctly quoted value
        return $__quote__->( $_[ 0 ] )    unless ( ref $_[ 0 ] );

        # what sort of reference do we have?
        REF: foreach ( ref $_[ 0 ] ) {
          # scalar
          /^SCALAR$/o && do {
            # return the scalar prefixed with a \
            return '\\' . $__quote__->( ${ $_[ 0 ] } );
          };

          # array
          /^ARRAY$/o  && do {
            # return the list of elements in []s
            return '[ ' . join( ', ' ,
                                map { $__dump__->( $_ , $depth ) }
                                    @{ $_[ 0 ] }
                              )
                        . ' ]';
          };

          # hash
          /^HASH$/o   && do {
            # return a list of key => value pairs in {}s
            return '{ ' . join( ', ' ,
                                map { join ' => ' ,
                                           $__quote__->( $_ ) ,
                                           $__dump__->(  $_[ 0 ]->{ $_ } ,
                                                         $depth
                                                      )
                                    } sort keys %{ $_[ 0 ] } )
                        . ' }';
          };

          # code
          /^CODE$/o   && last REF;

          # object that has a dump() method, and is derived from
          # Class::Declare
             UNIVERSAL::isa( $_[ 0 ] , 'Class::Declare' )
          && UNIVERSAL::can( $_[ 0 ] , 'dump'           )
          && do {
            # if we have the depth set then we need to pass it
            # with the list of arguments
            my  @args = @{ $__ARGS__ };
              push @args , ( depth => $depth )
                         if ( defined $depth );

            # call dump() and recurse
            return $_[ 0 ]->dump( @args );
          };
        }

        # otherwise, just return the quoted value
        return $__quote__->( $_[ 0 ] );
      }; # $__dump__();


  # # $__save__()
  #
  # Save original calling state.
  my  $__save__ = sub { # <object> <argument list reference>
      # reset the indentation counter
      undef $__INDENT__;

      # undefine the reference tracking hash
      undef %__REFERENCES__;

      # need to store the original caller stack so that dump()
      # can determined public(), private(), etc rights for the
      # calling routine/context
      $__CALLER__{ package    } = ( caller 1 )[ 0 ];
      $__CALLER__{ subroutine } = ( caller 2 )[ 3 ];

      # store the display indentation so that recursive calls to
      # dump() are consistent with the first call
      #   - we don't need to pass any other arguments to recursive
      #     calls because, in short, it doesn't make sense
      #       e.g. if dump() is called to display an object's private
      #            attributes, and one of the attribute values is
      #            another Class::Declare-derived object, then we
      #            should show all attributes (honouring permissions)
      #            of that object, not just the private attributes
      #            (which we may or may not have permission to show)
      my  $indent         = $_[ 1 ]->{ indent    };
      my  $backtrace      = $_[ 1 ]->{ backtrace };
      $__ARGS__           = [ backtrace => $_[ 1 ]->{ backtrace } ];
        ( defined $indent )
            and push @{ $__ARGS__ } , indent => $indent;
    }; # $__save__()


  # $__clear__()
  #
  # Clear original calling state.
  my  $__clear__  = sub {
      # reset the indentation counter
      undef $__INDENT__;

      # undefine the reference tracking hash
      undef %__REFERENCES__;

      # clear the caller stack
      %__CALLER__ = ();

      # clear the list of command-line arguments
      undef $__ARGS__;
    }; # $__clear__()


# jump into the Class::Declare namespace to create the dump() routine
package Class::Declare;


# dump()
#
# Generate a textual representation of the object/class
sub dump : method
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
                                           friends    => undef ,
                                           abstract   => undef ,
                                           depth      => undef ,
                                           backtrace  => 1     ,
                                           indent     => 4     ,
                                           all        => 1     } );

  # have we been called from outside this file
  # i.e. is this a non-recursive call (first call)
  my  $outside  = ( caller )[ 1 ] ne __FILE__;

  # if we're called from outside this file (i.e. it's not an
  # internal recursive call to dump() from $__dump__()) then make
  # note of the arguments and the context
    $__save__->( $self , $_args ) if ( $outside );

  # store the current depth limit
  my  $depth    = delete $_args->{ depth };

  # make sure the indentation is sensible
    $_args->{ indent } ||= 0;
  ( $_args->{ indent }  >= 0 )
    or do {
      my  ( undef , $file , $line , $sub )  = caller 0;

      die "indentation must be greater than or equal to zero "
          . " in call to $sub() at $file line $line\n";
    };

  # unset 'all' if any of the other arguments have been set
  ( $_args->{ $_ } )
    and delete $_args->{ all }
    and last
      foreach ( qw( public private protected  abstract
                    class  static  restricted friends  ) );

  # if we have asked for nothing, then return undef
  return undef    unless ( grep { defined }
                                map { $_args->{ $_ } }
                                    qw( public private protected  abstract
                                        class  static  restricted friends
                                        all                                ) );

  # next, we need to check to ensure the user has permission to access the
  # specified attribute types for the given object
  #   - this test should only be done at the top level
  if ( $outside ) {
    # ignoring friends, indentation and the all argument, make sure we
    # have permission to access the specified attribute types
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
                              && !/friends/o
                              && !/indent/o
                              && !/backtrace/o
                            } keys %{ $_args } );
  }

  # create a list of dump lines
  my  @dump;    undef @dump;
  # increase the indentation
    $__INDENT__ += $_args->{ indent };

  # display order: class, static, restricted, public, private, protected
  # and friends
  #
  # determine the attribute types that may be displayed/have been requested
  # NB: if required, as this is first calculated during the
  #     top-level call to dump()
  my  @types  = qw( abstract class  static  restricted
                             public private protected  );
      @types  = grep { $_args->{ $_ } } @types  unless ( $_args->{ all } );
  # if we've been asked to list friends, then add this separately
    push @types , 'friends'           if ( $_args->{ friends } );

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

  # if we've been asked to list friends, then we need to add this to the
  # reverse map
    $rmap{ $_ } = undef   foreach ( grep { $_ eq 'friends' } @types );

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

  # remember which references we've seen
  my  %refs;  undef %refs;

  # determine the maximum length of attribute names for this map
  #   - make sure we only take into account the attributes we can actually
  #     see
  my  $length = 0;
    ( $length < length )
      and $length = length
          foreach ( grep { $perm->( $self => $_ ) } keys %map );

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

  # OK, generate the dump
  DUMP: foreach my $type ( grep { exists $rmap{ $_ } } @types ) {
    # set the type heading
    my  $heading       = ' ' x $__INDENT__ . $type . ':';

    # increase the indentation
        $__INDENT__   += $_args->{ indent };

    # if we're displaying abstract class/attributes, then just list
    # the methods and attributes as listed (no values)
    ( $type eq 'abstract' )
      and do {
        # do we need to add the type heading?
        push @dump , $heading
          and undef $heading      if ( defined $heading );

        # add the list of abstract attributes and methods
        push @dump , map { ( ' ' x $__INDENT__ ) . $_ }
                         sort map { @{ $_ } }
                                  grep { defined }
                                       $rmap{ $type };

        # reduce the indent and loop again
        $__INDENT__ -= $_args->{ indent };
        next DUMP;
      };

    # if we're displaying class friend information, then just
    # list the methods and classes as listed
    ( $type eq 'friends' )
      and do {
        # do we need to add the type heading?
        push @dump , $heading
          and undef $heading      if ( defined $heading );

        # add the list of friends
        push @dump , map { ( ' ' x $__INDENT__ ) . $_ }
                         map { sort keys %{ $_ } }
                             grep { defined }
                                  $__GET_FRIENDS__->( $class );

        # reduce the indent and loop again
        $__INDENT__ -= $_args->{ indent };
        next DUMP;
      };

    # OK, we have class, public, private and protected attributes
    # to display

    # for each attribute, extract the value and add it to the
    # dump string
    my  $string;  undef $string;

    # print the attribute values we have access to
    ATTR: foreach my $attr ( sort grep { $perm->( $self => $_ ) }
                                       map { @{ $_ } }
                                           grep { defined }
                                                $rmap{ $type } ) {

      # extract the attribute value from the lookup table
      my  $value  = $hash->{ $attr };

      # add the attribute name to the string
          $string = sprintf( '%-*s = ' , $length , $attr );

      my  $str    = undef;
      # if this is a reference, then we should look at a cache
      # of previously encountered references and see if we can
      # match the reference with another attribute
      # NB: this prevents infinite recursion through circular
      #     references
      if ( ref $value && $_args->{ backtrace } ) {
        $str  = $__REFERENCES__{ $value };
        unless ( $str ) {
          # OK, if we've seen this object before (i.e. $self),
          # then we should show where it came from
          my  $origin = $__REFERENCES__{ $self } || $self;

          $__REFERENCES__{ $value } = join '->' , $origin , $attr;
          $str                      = $__dump__->($value , $depth);
        }

      # otherwise, just dump the value
      } else {
        $str  .= $__dump__->( $value , $depth );
      }

      # OK, need to perform indenting for $str to make sure it
      # lines up with the rest of the output
        $str     =~ s#\n#"\n" . ( ' ' x length( $string ) )#egm;

      # add this to the string
        $string .= $str;

      # do we need to add the type heading?
      push @dump , $heading
        and undef $heading      if ( defined $heading );

      # add this string to the output
      push @dump , ( ' ' x $__INDENT__ ) . $string;
    }

    # reduce the indentation
      $__INDENT__ -= $_args->{ indent };
  }

  # drop a level in the indentation
    $__INDENT__ -= $_args->{ indent };

  # if this is the top level call to dump() (i.e. no recursion)
  # then add a newline to the end of the dump string
    push @dump , ''   if ( $outside );

  # if this is the final exit of dump() (i.e. this execution frame
  # corresponds to the original invocation of dump() and not an internal
  # recursive call, then we should clear the saved state information
    $__clear__->()    if ( $outside );

  # return the dump() string
  return join "\n" , $self , @dump;
} # dump()

} # end dump() closure


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
