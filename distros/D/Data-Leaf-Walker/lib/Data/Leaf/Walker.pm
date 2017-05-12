package Data::Leaf::Walker;

use warnings;
use strict;

=head1 NAME

Data::Leaf::Walker - Walk the leaves of arbitrarily deep nested data structures.

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

   $data   = {
      a    => 'hash',
      or   => [ 'array', 'ref' ],
      with => { arbitrary => 'nesting' },
      };

   $walker = Data::Leaf::Walker->new( $data );
   
   while ( my ( $k, $v ) = $walker->each )
      {
      print "@{ $k } : $v\n";
      }
      
   ## output might be
   ## a : hash
   ## or 0 : array
   ## or 1 : ref
   ## with arbitrary : nesting

=head1 DESCRIPTION

C<Data::Leaf::Walker> provides simplified access to nested data structures. It
operates on key paths in place of keys. A key path is a list of HASH and ARRAY
indexes which define a path through your data structure. For example, in the
following data structure, the value corresponding to key path C<[ 0, 'foo' ]> is
C<bar>: 

   $aoh = [ { foo => 'bar' } ];

You can get and set that value like so:

   $walker = Data::Leaf::Walker->new( $aoh );      ## create the walker
   $bar    = $walker->fetch( [ 0, 'foo' ] );       ## get the value 'bar'
   $walker->store( [ 0, 'foo'], 'baz' );           ## change value to 'baz'

=head1 FUNCTIONS

=head2 new( $data )

Construct a new C<Data::Leaf::Walker> instance.

   $data   = {
      a    => 'hash',
      or   => [ 'array', 'ref' ],
      with => { arbitrary => 'nesting' },
      };

   $walker = Data::Leaf::Walker->new( $data );
   
=head3 Options

=over 3

=item * max_depth: the C<each>, C<keys> and C<values> methods iterate no deeper
than C<max_depth> keys deep.

=item * min_depth: the C<each>, C<keys> and C<values> methods iterate no shallower
than C<min_depth> keys deep.

=back

=cut

sub new
   {
   my ( $class, $data, %opts ) = @_;
   my $self = bless
      {
      _data          => $data,
      _data_stack    => [],
      _key_path      => [],
      _array_tracker => {},
      _opts          => {},
      }, $class;
   $self->opts( %opts );
   return $self;
   }

=head2 each()

Iterates over the leaf values of the nested HASH or ARRAY structures. Much like
the built-in C<each %hash> function, the iterators for individual structures are
global and the caller should be careful about what state they are in. Invoking
the C<keys()> or C<values()> methods will reset the iterators. In scalar
context it returns the key path only.

   while ( my ( $key_path, $value ) = $walker->each )
      {
      ## do something
      }

=cut

sub each
   {
   my ( $self ) = @_;
   
   if ( ! @{ $self->{_data_stack} } )
      {
      push @{ $self->{_data_stack} }, $self->{_data};
      }
      
   return $self->_iterate;
   }

=head2 keys()

Returns the list of all key paths.

   @key_paths = $walker->keys;

=cut

sub keys
   {
   my ( $self ) = @_;

   my @keys;

   while ( defined( my $key = $self->each ) )
      {
      push @keys, $key;
      }
   
   return @keys;
   }
   
=head2 values()

Returns the list of all leaf values.

   @leaf_values = $walker->values;

=cut

sub values
   {
   my ( $self ) = @_;

   my @values;

   while ( my ($key, $value) = $self->each )
      {
      push @values, $value;
      }

   return @values;
   }

=head2 fetch( $key_path )

Lookup the value corresponding to the given key path. If an individual key
attempts to fetch from an invalid the fetch method dies.

   $key_path = [ $key1, $index1, $index2, $key2 ];
   $leaf     = $walker->fetch( $key_path );

=cut

sub fetch
   {
   my ( $self, $key_path ) = @_;

   my $data = $self->{_data};
   
   for my $key ( @{ $key_path } )
      {

      my $type = ref $data;
      
      if ( $type eq 'ARRAY' )
         {
         $data = $data->[$key];
         }
      elsif ( $type eq 'HASH' )
         {
         $data = $data->{$key};
         }
      else
         {
         die "Error: cannot lookup key ($key) in invalid ref type ($type)";
         }
         
      }
      
   return $data;
   }

=head2 store( $key_path, $value )

Set the value for the corresponding key path.

   $key_path = [ $key1, $index1, $index2, $key2 ];
   $walker->store( $key_path, $value );

=cut

sub store
   {
   my ( $self, $key_path, $value ) = @_;
   
   my @store_path = @{ $key_path };
   
   my $twig_key = pop @store_path;
   
   my $twig = $self->fetch( \@store_path );
   
   if ( ! defined $twig )
      {
      die "Error: cannot autovivify arbitrarily";
      }
   
   my $type = ref $twig;
   
   if ( $type eq 'HASH' )
      {
      return $twig->{ $twig_key } = $value;
      }
   elsif  ( $type eq 'ARRAY' )
      {
      return $twig->[ $twig_key ] = $value;
      }
   
   }

=head2 delete( $key_path )

Delete the leaf key in the corresponding key path. Only works for a HASH leaf,
dies otherwise. Returns the deleted value.

   $key_path  = [ $key1, $index1, $index2, $key2 ];
   $old_value = $walker->delete( $key_path );

=cut

sub delete
   {
   my ( $self, $key_path ) = @_;

   my @delete_path = @{ $key_path };
   
   my $twig_key = pop @delete_path;
   
   my $twig = $self->fetch( \@delete_path );
   
   defined $twig || return;
   
   my $type = ref $twig;
   
   if ( $type eq 'HASH' )
      {
      return delete $twig->{ $twig_key };
      }
   elsif  ( $type eq 'ARRAY' )
      {
      die "Error: cannot delete() from an ARRAY leaf";
      }
   
   }

=head2 exists( $key_path )

Returns true if the corresponding key path exists.

   $key_path = [ $key1, $index1, $index2, $key2 ];
   if ( $walker->exists( $key_path ) )
      {
      ## do something
      }

=cut

sub exists
   {
   my ( $self, $key_path ) = @_;

   my $data = $self->{_data};
   
   for my $key ( @{ $key_path } )
      {

      my $type = ref $data;
      
      if ( $type eq 'ARRAY' )
         {
         if ( exists $data->[$key] )
            {
            $data = $data->[$key];
            }
         else
            {
            return;
            }
         }
      elsif ( $type eq 'HASH' )
         {
         if ( exists $data->{$key} )
            {
            $data = $data->{$key};
            }
         else
            {
            return;
            }
         }
      else
         {
         return;
         }
         
      }
      
   return 1;
   }

=head2 reset()

Resets the current iterators. This is faster than using the C<keys()> or
C<values()> methods to do an iterator reset.

   ## set the max depth one above the bottom, to get the twig structures
   $key_path = $walker->each;
   $walker->opts( max_depth => @{ $key_path } - 1 );
   $walker->reset;
   @twigs = $walker->values;

=cut

sub reset
   {
   my ( $self ) = @_;
   
   for my $data ( @{ $self->{_data_stack} } )
      {
      if ( ref $data eq 'HASH' )
         {
         CORE::keys %{ $data };
         }
      }

   %{ $self->{_array_tracker} } = ();
   @{ $self->{_data_stack} }    = ();
   @{ $self->{_key_path} }      = ();
   
   return;
   }

=head2 opts()

Change the values of the constructor options. Only given options are affected.
See C<new()> for a description of the options. Returns the current option hash
after changes are applied.

   ## change the max_depth
   $walker->opts( max_depth => 3 );
   
   ## get the current options
   %opts = $walker->opts;

=cut

sub opts
   {
   my ( $self, %opts ) = @_;

   if ( CORE::keys %opts )
      {

      for my $key ( CORE::keys %opts )
         {
         $self->{_opts}{$key} = $opts{$key};
         }

      }

   return %{ $self->{_opts} };
   }

sub _iterate
   {
   my ( $self ) = @_;

   ## find the top of the stack   
   my $data = ${ $self->{_data_stack} }[-1];
   
   ## iterate on the stack top
   my ( $key, $val ) = $self->_each($data);

   ## if we're at the end of the stack top
   if ( ! defined $key )
      {
      ## remove the stack top
      pop @{ $self->{_data_stack} };
      pop @{ $self->{_key_path} };

      ## iterate on the new stack top if available
      if ( @{ $self->{_data_stack} } )
         {
         return $self->_iterate;
         }
      ## mark the stack as empty
      ## return empty/undef
      else
         {
         return;
         }

      }
   
   ## _each() succeeded

   ## return right away if we're at max_depth   
   my $max_depth = $self->{_opts}{max_depth};
   if ( defined $max_depth && @{ $self->{_key_path} } + 1 >= $max_depth )
      {
      my $key_path = [ @{ $self->{_key_path} }, $key ];
      return wantarray ? ( $key_path, $val ) : $key_path;
      }

   ## if the value is a HASH/ARRAY, add it to the stack and iterate
   if ( defined $val && ( ref $val eq 'HASH' || ref $val eq 'ARRAY' ) )
      {
      push @{ $self->{_data_stack} }, $val;
      push @{ $self->{_key_path} }, $key;
      return $self->_iterate;
      }
      
   ## continue iterating if we are less than min_depth
   my $min_depth = $self->{_opts}{min_depth};
   if ( defined $min_depth && @{ $self->{_key_path} } + 1 < $min_depth )
      {
      return $self->_iterate;
      }

   my $key_path = [ @{ $self->{_key_path} }, $key ];

   return wantarray ? ( $key_path, $val ) : $key_path;   
   }

sub _each
   {
   my ( $self, $data ) = @_;
   
   if ( ref $data eq 'HASH' )
      {
      return CORE::each %{ $data };
      }
   elsif ( ref $data eq 'ARRAY' )
      {
      my $array_tracker = $self->{_array_tracker};
      $array_tracker->{ $data } ||= 0;
      if ( $array_tracker->{ $data } <= $#{ $data } )
         {
         my $index = $array_tracker->{ $data };
         ++ $array_tracker->{ $data };
         return( $index, $data->[ $index ] );
         }
      else
         {
         $array_tracker->{ $data } = 0;
         return;
         }
      
      }
   else
      {
      die "Error: cannot call _each() on non-HASH/non-ARRAY data record";
      }
   
   }

=head1 AUTHOR

Dan Boorstein, C<< <danboo at cpan.org> >>

=head1 CAVEATS

=head2 Global Iterators

Because the iterators are global, data structures which contain cyclical
references or repeated sub structures are not handled correctly.

=head2 Hash Iterators

If you iterate directly over a hash which is also contained in your leaf walker
instance, be sure to leave it in a proper state. If that hash is a sub reference
within the leaf walker, calling the C<keys()> or C<values()> methods, for the
purpose of resetting the iterator, may not be able to reach the hash. A second
reset attempt should work as expected. If you consistently use the leaf walker
instance to access the data structure, you should be fine.

=head1 PLANS

=over 3

=item * add type and twig limiters for C<each>, C<keys>, C<values>

=item * optional autovivification (Data::Peek, Scalar::Util, String::Numeric)

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-Data-Leaf-Walker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Leaf-Walker>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Leaf::Walker


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Leaf-Walker>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Leaf-Walker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Leaf-Walker>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Leaf-Walker/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Boorstein.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::Leaf::Walker
