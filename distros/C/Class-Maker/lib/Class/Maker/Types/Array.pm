package Class::Maker::Types::Array;

our $VERSION = "0.06";

use Array::Compare;

use Data::Iter qw(iter);

use Data::Dump qw(dump);

use Statistics::Tests::Wilcoxon;

require Algorithm::FastPermute;

use Class::Maker::Exception qw(:try);

{
package Class::Maker::Types::Array::Exception::NullDivision;

        Class::Maker::class
        {
                isa => [qw( Class::Maker::Exception )],

                public =>
                {
                        string => [qw( email )],
                },
        };
}

Class::Maker::class
{
	public =>
	{
		getset => [qw( max )],

		array => [qw( keys )],
	},

	private =>
	{
		array => [qw( array )],
	},
};

sub _preinit
{
	my $this = shift;

	my $args = shift;

		# Manipulate args list, because otherwise teh Class::Maker constructor would forward args
		# for inhertance

	if( defined $args )
	{
		$this->_array( $args->{array} ) if exists $args->{array};

		delete $args->{array};
	}
}

sub _postinit
{
	my $this = shift;

	warn "$this was initiazed with an array argument. This is dangerous until you use a method !" unless $this->_array;
}

sub _gen
{
	my $this = shift;

return Class::Maker::Types::Array->new( array => \@_ );
}

sub at : lvalue method
{
	my $this = shift;

return $this->_array->[shift];
}

sub push : method
{
	my $this = shift;

	push @{ $this->_array }, @_;
}

sub pop : method
{
	pop @{ shift->_array };
}

sub shift : method
{
	my $this = shift;

return shift @{ $this->_array };
}

sub unshift : method
{
	my $this = shift;

return unshift @{ $this->_array }, @_;
}

sub count : method
{
	scalar @{ shift->_array };
}

sub reset : method
{
	@{ shift->_array } = ();
}

sub get : method
{
	@{ shift->_array };
}

sub members : method
{
	@{ shift->_array };
}

sub set : method
{
	my $this = shift;

	@{ $this->_array } = @_;

return $this;
}

sub pick : method
{
	my $this = shift;

		my $step = shift || 2;

		my @result;

		my $cnt;

		map { push @result, $_ unless $cnt++ % $step } @{ $this->_array };

return Class::Maker::Types::Array->new( array => \@result );
}

sub every : method
{
	pick( @_ );
}

sub join : method
{
	my $this = shift;

return join( shift, @{ $this->_array } );
}

sub sort : method
{
	my $this = shift;

	my $alpha = shift;

		if( $alpha )
		{
			$this->_array( [sort { $a cmp $b } @{ $this->_array }] ) ;
		}
		else
		{
			$this->_array( [sort { $a <=> $b } @{ $this->_array }] );
		}

return $this;
}

# from the perlfaq:
# fisher_yates_shuffle( \@array ) :
# generate a random permutation of @array in place
sub _fisher_yates_shuffle
{
    my $array = shift;

    my $i;

    for ($i = @$array; --$i; )
    {
        my $j = int rand ($i+1);

        @$array[$i,$j] = @$array[$j,$i];
    }
}

sub rand : method
{
	my $this = shift;

		_fisher_yates_shuffle( scalar $this->_array );

return $this;
}

sub warp : method
{
	my $this = shift;


	my @result;

	for( @_ ) 
	{	
		push @result, $this->at($_);
	}	


	my @result_keys;

	if( scalar $this->keys )
	{	
	  for( @_ ) 
	    {	
	      push @result_keys, $this->keys->[$_];
	    }	
	}

return Class::Maker::Types::Array->new( array => \@result, keys => \@result_keys );
}

# subset( @indices )

sub subset : method
  {
    warp( @_ );
  }


sub _algebra
{
	my $this = shift;

	my $type = shift;

		my $other = shift;

		$other = ref($other) eq 'ARRAY' ? $other : [ $other->_array ];

return Class::Maker::Types::Array->new( array => _calc( [ $this->_array ], $other )->[$type] );
}

sub union : method
{
	my $this = shift;

return $this->_algebra( 0, @_ );
}

sub intersection : method
{
	my $this = shift;

return $this->_algebra( 1, @_ );
}

sub diff : method
{
	my $this = shift;

return $this->_algebra( 2, @_ );
}

sub _calc
{
	my ( $a, $b ) = @_;

	die 'argument type mismatch for _calc( aref, aref )' unless ref($a) eq 'ARRAY' && ref($a) eq 'ARRAY';

	my @array1 = _unique( @$a );

	my @array2 = _unique( @$b );

	no strict;

	@union = @intersection = @diff = ();

	%count = ();

	foreach $element (@array1, @array2) { $count{$element}++ }

	foreach $element (keys %count)
	{
	    push @union, $element;

	    push @{ $count{$element} > 1 ? \@intersection : \@diff }, $element;
	}

return [ \@union, \@intersection, \@diff ];
}

sub eq : method
{
	my $this = shift;

	my $that = shift;

	my $comp = Array::Compare->new;

return $comp->compare( scalar $this->_array , scalar $that->_array );
}

sub ne : method
{
	my $this = shift;

	my $that = shift;

return not $this->eq( $that );
}

sub totext : method
{
	my $this = shift;

return '['.join( '], [', @{ $this->_array } ).']';
}

sub sum : method
{
	my $this = shift;
	
	my $sum;
	
	$sum += $_ foreach @{ $this->_array };

return $sum;
}

sub _unique : method
{
	my %temp;
	
		@temp{ @_ } = 1;
	
return keys %temp;
}

sub unique : method
{
	my $this = shift;
	

	@{ $this->_array } = _unique( @{ $this->_array } );
	
return $this;
}

sub permute : method
{
	my $this = shift;

		my @result;

		my $p = Algorithm::FastPermute::permute { push @result, $_ } ( @{ $this->_array } );
		
		@{ $this->_array } = @result;

return $this;
}

	# search our object list and return the obj with matching attributes

sub get_where : method
{
	my $this = shift;

	my %arghash = @_;

	my $key = shift @{ [ keys %arghash ] };

	my @results;

		foreach my $obj ( @{ $this->_array } )
		{
			if( $obj->$key() eq $arghash{$key} )
			{
				push @results, $obj;
			}
		}

#	return undef unless @results;

return wantarray ? @results : $this->_gen( @results );
}

sub get_where_sref : method
{
	my $this = shift;


	my @results;

		foreach my $obj ( $this->get )
		{
		  for( @_ )
		    {
			push @results, $obj if $_->( $this, $obj );
		    }
		}

#	return undef unless @results;

return wantarray ? @results : $this->_gen( @results );
}



sub get_where_regexp : method
{
	my $this = shift;


	my @results;

		foreach my $obj ( $this->get )
		{
		  my @args = @_;

		  for( @args )
		    {
		      my $key =  shift @args;
		      my $value =  shift @args;

		      if( ref( $key_) =~ /CODE/i )
			{
#			  warn sprintf "REGEXP CODE %s method $key ", ref( $obj );

			  push @results, $obj if $obj->$key( $this, $obj ) =~ $value;
			}
		      elsif( ref( $key ) eq 'ARRAY' )
			{
			  my @call_args = @$key;

			  my $func = shift @call_args;

#			  warn sprintf "REGEXP ARRAY %s method $func ", ref( $obj );

			  push @results, $obj if $obj->$func( @call_args ) =~ $value;
			}
		      else
		      {
#			  warn sprintf "REGEXP CALL %s method $key ", ref( $obj );

			  push @results, $obj if $obj->$key =~ $value;
		      }
		    }
		}

return wantarray ? @results : $this->_gen( @results );
}

{
  package Class::Maker::Types::Array::ElementSelector;

  Class::Maker::class
      {
	public =>
	  {
	   scalar => [qw( desc )],	 
	  },
	    
	};

  sub test : method
    {
      die "abstract method called";
    }
}

sub get_where_elementselector : method
{
    my $this = shift;

    my $selector_obj = shift || die;

    die "Class::Maker::Types::Array::ElementSelector required" unless $selector_obj->isa( 'Class::Maker::Types::Array::ElementSelector' );

    my @results = $this->get_where_sref( 
			  sub 
			  { 
			      return 1 if $selector_obj->test( $_[1] );
			  } 
			  );

return wantarray ? @results : $this->_gen( @results );
}

sub stats : method
{
	my $this = shift;

return Statistics::Tests::Wilcoxon::Basics->stats_all( $this->_array );
}


sub pair : method
{
	my $this = shift;

	my $index = shift;

return ( $this->keys->[ $index ], $this->_array->[ $index ] );
}

sub as_aref : method
{
	my $this = shift;

return scalar $this->_array;
}

sub as_hash : method
{
	my $this = shift;

	my @result;

	for( 0..$this->count-1 )
	{
	    push @result, $this->pair( $_ );
	}

return { @result };
}

sub clone : method
{
	my $this = shift;

return Class::Maker::Types::Array->new( array => \@{ $this->_array }, keys => \@{ $this->keys } );
}

sub copy_from : method
{
	my $this = shift;

	my $rhs = shift;

	$this->set( @{ $rhs->_array } );
	
	@{ $this->keys } = @{ $rhs->keys };

return $this;
}

sub div_by_array : method
{
	my $this = shift;

	my $val = shift;


	my @result;

	foreach ( iter $this->as_aref )
	{
		unless( $val->[ $_->COUNTER ] )
		  {
		    Class::Maker::Types::Array::Exception::NullDivision->throw();
	          }

	  unless( $this->at( $_->COUNTER ) )
	    {
	      push @result, $this->at( $_->COUNTER );

	      next;
	    }

	    push @result, $this->at( $_->COUNTER ) / $val->[ $_->COUNTER ];
	}	

	my $clone = $this->clone;

	$clone->set( @result );

return $clone;
}

sub div_by_array_obj : method
{
	my $this = shift;

	my $that = shift;


	my $val = $that->as_aref;


	my @result;

	foreach ( iter $this->as_aref )
	{
	  unless( $val->[ $_->COUNTER ] )
	    {
	      Class::Maker::Types::Array::Exception::NullDivision->throw();
	    }

	  unless( $this->at( $_->COUNTER ) )
	    {
	      push @result, $this->at( $_->COUNTER );

	      next;
	    }

	    push @result, $this->at( $_->COUNTER ) / $val->[ $_->COUNTER ];
	}	

	my $clone = $this->clone;

	$clone->set( @result );

return $clone;
}

sub div : method
{
	my $this = shift;

	my $val = shift;

	
	my @result;

	foreach my $obj ( $this->get )
	{
	  unless( $val )
	    {
	      Class::Maker::Types::Array::Exception::NullDivision->throw();
	    }

	  unless( $obj )
	    {
	      push @result, $obj;

	      next;
	    }

	      push @result, $obj / $val;		
	}	

	my $clone = $this->clone;

	$clone->set( @result );

return $clone;
}

sub scale_unit : method
{
	my $this = shift;

return $this->div( $this->stats->{max} );
}

sub mult_by_array : method
{
	my $this = shift;

	my $val = shift;


	my @result;

	foreach ( iter $this->as_aref )
	{
	    push @result, $this->at( $_->COUNTER ) * $val->[ $_->COUNTER ];
	}	

	my $clone = $this->clone;

	$clone->set( @result );

return $clone;
}

sub mult_by_array_obj : method
{
	my $this = shift;

	my $that = shift;


	my $val = $that->as_aref;


	my @result;

	foreach ( iter $this->as_aref )
	{
	    push @result, $this->at( $_->COUNTER ) * $val->[ $_->COUNTER ];
	}	

	my $clone = $this->clone;

	$clone->set( @result );

return $clone;
}


sub mult : method
{
	my $this = shift;

	my $val = shift;

	
	my @result;

	foreach my $obj ( $this->get )
	{
	    push @result, $obj * $val;		
	}	

	my $clone = $this->clone;

	$clone->set( @result );

return $clone;
}



sub minus_by_array : method
{
	my $this = shift;

	my $val = shift;


	my @result;

	foreach ( iter $this->as_aref )
	{
	    push @result, $this->at( $_->COUNTER ) - $val->[ $_->COUNTER ];
	}	

	my $clone = $this->clone;

	$clone->set( @result );

return $clone;
}

sub minus_by_array_obj : method
{
	my $this = shift;

	my $that = shift;


	my $val = $that->as_aref;


	my @result;

	foreach ( iter $this->as_aref )
	{
	    push @result, $this->at( $_->COUNTER ) - $val->[ $_->COUNTER ];
	}	

	my $clone = $this->clone;

	$clone->set( @result );

return $clone;
}

sub minus : method
{
	my $this = shift;

	my $val = shift;

	
	my @result;

	foreach my $obj ( $this->get )
	{
	    push @result, $obj - $val;		
	}	

	my $clone = $this->clone;

	$clone->set( @result );

return $clone;
}


 # plus

sub plus_by_array_obj : method
{
	my $this = shift;

	my $that = shift;


	my $val = $that->as_aref;


	my @result;

	foreach ( iter $this->as_aref )
	{
	    push @result, $this->at( $_->COUNTER ) + $val->[ $_->COUNTER ];
	}	

	my $clone = $this->clone;

	$clone->set( @result );

return $clone;
}


 # preliminary function to smooth out values (conceptually thought to be similar as diffusion)

sub smooth : method
  {
  my $this = shift;

  my $aref = $this->as_aref;

  my $result;

  for ( iter $aref ) {
    printf STDERR "%d/%d VALUE %s (%s)\n", COUNTER, LAST_COUNTER, VALUE, $aref->[ COUNTER() ];

    if ( COUNTER > 0 && ( COUNTER() < LAST_COUNTER() ) ) {
      if ( $aref->[ COUNTER() ] == 0 && $aref->[ COUNTER() + 1 ] != 0 ) {
	push @$result, $aref->[ COUNTER()+1 ] / 2;
	print STDERR "new value $result->[-1]\n";
      } elsif ( $aref->[ COUNTER() - 1 ] != 0 && $aref->[ COUNTER() ] == 0 ) {
	push @$result, $aref->[ COUNTER()-1 ] / 2;
	print STDERR "new value $result->[-1]\n";
      } else {
	push @$result, VALUE;
      }
      ;

    }	  
  }

    my $clone = $this->clone;

    $clone->set( @$result );

    return $clone;
}





1;

__END__

=head1 NAME

Class::Maker::Types::Array - a sophisticated but slow array class

=head1 SYNOPSIS

  use Class::Maker::Types::Array;

	Class::Maker::Types::Array->new( array => [1..100] );

		# standard

	$a->shift;

	$a->push( qw/ 1 2 3 4 / );

	$a->pop;

	$a->unshift( qw/ 5 6 7 / );

	$a->reset;

	$a->join( ', ' );

		# extended

	$a->count;

	$a->get;

	$a->set( 1..100 );

	my $clone = $a->clone;

	$a->copy_from( $b );

	$a->pick( 4 );

	$a->warp( 2, 3, 1, 0 );  # place elements in this new order of indices

	$a->union( 100..500 );

	$a->intersection( 50..100 );

	$a->diff( 50..100 );

	$a->rand;

	$a->sort;

	$a->totext;

	$a->sum;
	
	$a->unique;

	$a->permute;

	print "same" if $a->eq( $other );

	# if array of objects
 
	$a->get_where( method1 => 'myvalue' );

	$a->get_where_sref( $sref, .. );

	$a->get_where_regexp( method1 => $regexp1, .. );
	
	$a->get_where_elementselector( Class::Maker::Types::Array::ElementSelector->new( .. ) );

	$a->stats;

	$a->scale_unit;

	$a->keys( [qw( alpha beta gamma )] );

	my ($key, $value) = $a->pair(0);

	my $href=$a->as_hash;

	my $c = $a->div( 2 );

	my $d = $a->div_by_array( qw(1 2 3) );

	my $e = $a->div_by_array( $d );

	$a->scale_unit; # scales values to < 1.0

=head1 DESCRIPTION

This an object-oriented array class, which uses a method-oriented interface.

=head1 METHODS

Mostly they have the similar syntax as the native perl functions (use "perldoc -f"). If not they are
documented below, otherwise a simple example is given.

 sub at : method
 sub _preinit : method
 sub push : method
 sub pop : method
 sub shift : method
 sub unshift : method
 sub count : method
 sub reset : method
 sub get : method
 sub members : method
 sub pick : method
 sub every : method
 sub join : method
 sub sort : method
 sub warp : method
 sub _fisher_yates_shuffle
 sub rand : method
 sub _algebra
 sub union : method
 sub intersection : method
 sub diff : method
 sub _calc
 sub eq : method
 sub ne : method
 sub totext : method
 sub sum : method
 sub unique : method
 sub permute : method
 sub stats : method
 sub pair : method
 sub div : method
 sub div_by_array : method
 sub div_by_array_obj : method

=head2 at($i)

Returns the element at position $i.

=head2 count

Returns the number of elements (same as @arry in scalar context).

=head2 reset

Resets the array to an empty array.

=head2 get

Returns the backend array.

=head2 pick( [step{scalar}]:2 )

Returns every 'step' (default: 2) element.

=head2 warp( @indices )

Copies the elements in the new sequence as indicated by indices. 

=head2 union

Returns the union of two arrays (Array object is returned).

=head2 intersection

Returns the intersection of the two arrays (Array object is returned).

=head2 $array_new = diff

Returns the diff of the two arrays (Array object is returned).

=head2 @objects = get_where( method_name => $value, method_name1 => $value )

Call C<method_name> of all set array and filters the ones that match to C<$value>.

Note: All these C<get_where...> methods return an array of the resulting objects. Empty when nothing found.

=cut

=head2 @objects = get_where_sref( sub { }, [ sub { }, ... ] )

Filters the array and returns the ones where the sref returns true. The sref get 

 $_[0] : the Class::Maker::Types::Array object

 $_[1] : the set object member

so a prototypical sref would look like

 my $sref = sub {

     my $array_obj = shift;

     my $obj = shift;

     return 1 if $obj->method_name eq ...;
 }

=cut

=head2 @objects = get_where_regexp( method_name => qr/../, [ method_name => qr/../, ... ] )
                  get_where_regexp( [qw(method_name arg1 arg2)] => qr/../, [ method_name => qr/../, ... ] )

Filters the array which return a value that matches the regexps. To call methods with arbitrary args, give an array reference
as key where the first element is the method name.

=head2 stats(void)

Returns a hashref with following keys and values determined by the array members.

 {
  count => 5,
  max => "0.217529585558676",
  mean => "0.109738802941511",
  min => undef,
  sample_range => "0.217529585558676",
  standard_deviation => "0.103038948420036",
  sum => "0.548694014707553",
  variance => "0.0106170248915069",
 }

[Note] The module L<Statistics::Tests::Wilcoxon> is used to generate these calculations and with any update of it, the available models may increase. 
Refer to its documentation and locate the stats_all() method for detailed information.

=head2 keys( @names_as_keys )

This method can be used to set array key names. Once set can be accessed as an array ref. See pair method below.

  $a->keys( qw(alpha beta gamme) );

  printf "key=%s, value=%s", $a->keys->[0], $a->at(0);

=head2 pair( $i )

Returns a ( key => value ) pair. The key may be only valid if keys was set before.

  $a->keys( qw(alpha beta gamme) );

  my ( $key, $value ) = $a->pair( 0 );
 
=cut

=head1 EXPORT

None by default.

=head1 EXAMPLE

=head2 Purpose

Because most methods return Array objects itself, the can be easily further treated with Array methods.
Here a rather useless, but informative example.

=head2 Code

use Class::Maker::Types::Array;

	my $a = Class::Maker::Types::Array->new( array => [1..70] );

	my $b = Class::Maker::Types::Array->new( array => [50..100] );

	$a->intersection( $b )->pick( 4 )->join( ', ' );

=head1 AUTHOR

Murat Uenalan, muenalan@cpan.org

=head1 SEE ALSO

L<perl>, L<perlfunc>, L<perlvar>

=cut

