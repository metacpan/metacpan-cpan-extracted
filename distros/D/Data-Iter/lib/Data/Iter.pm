package Data::Iter;

use 5.006;
use strict;
use warnings;

use Carp;


$Carp::Verbose = 1;


require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(iter counter COUNTER LAST_COUNTER value VALUE key KEY get GET getnext GETNEXT GETPREV IS_LAST IS_FIRST transform_array_to_hash) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.2';

# Preloaded methods go here.

#prototype of ($$) is important for sort functions

sub sort_alpha($$) { $_[0] cmp $_[1] }
sub sort_num($$) { $_[0] <=> $_[1] }

our $cref_sort = sub { $a cmp $b };

sub default_sort { $cref_sort->(@_) }

our $Sort = 'default_sort';

our $options = { };

sub _KEY       { 0 }
sub _VALUE     { 1 }
sub _COUNT     { 2 }
sub _KEY_REF   { 3 }
sub _VALUE_REF { 5 }
sub _LIST_REF  { 6 }

sub iter
{
	my $this = shift if ( ref $_[0] || $_[0] ) eq __PACKAGE__;
	
	my $cnt = 0;
	
	my $ref_data = shift;
	
	my @result = ();

	unless( @_ )
	{
		if( ref $ref_data eq 'HASH'  )
		{		
			foreach my $key ( sort $Sort keys %{ $ref_data } )
			{
				my $obj = [];
				
				@$obj[ _KEY, _VALUE, _COUNT, _KEY_REF, _VALUE_REF, _LIST_REF ] = ( $key, $ref_data->{$key}, $cnt, \$key, \( $ref_data->{$key}, \@result ) );
				
				push @result, bless $obj, __PACKAGE__;
				
				$cnt++;
			}
		}
		elsif( ref $ref_data eq 'ARRAY' )
		{				
			@result = ();
			
			foreach my $value ( @$ref_data )
			{
				my $obj = [];
				
				@$obj[ _KEY, _VALUE, _COUNT, _VALUE_REF, _LIST_REF ] = ( $cnt, $value, $cnt, \( $ref_data->[$cnt] ), \@result );
														
				push @result, bless $obj, __PACKAGE__;
				
				$cnt++;
			}
		}
		else
		{
			croak "iter() only accepts reference to ARRAY or HASH. Found: ". ref( $ref_data );
		}
	}
	else
	{
		croak "iter() only accepts one parameter (reference to ARRAY or HASH). Found extra args: ", scalar @_;
	}
	
return @result;  
}

sub _handle_this
{
	my $this;

	  # called as method ?
	  
	$this = shift @{$_[0]} if ( ref $_[0]->[0] || defined $_[0]->[0] ) eq __PACKAGE__;

	  # no, so use $_ as obj
	  
	$this = $_ unless $this;
	
return $this;
}



sub counter
{
	my $this = _handle_this( \@_ );
	
return $this->[_COUNT];
}

sub COUNTER { goto &counter }

sub value
{
	my $this = _handle_this( \@_ );

		# set value if argument given
		
	$this->[_VALUE] = ${ $this->[_VALUE_REF] } = $_[0] if @_;
	
return $this->[_VALUE];
}

sub VALUE { goto &value }

sub key
{
	my $this = _handle_this( \@_ );

		# set value if argument given
		
	$this->[_VALUE] = ${ $this->[_KEY_REF] } = $_[0] if @_;

return $this->[_KEY];
}

sub KEY { goto &key }

sub get
{
	my $this = _handle_this( \@_ );

	my $pos = shift || -1;

return $this->[_LIST_REF]->[$pos];
}

sub GET { goto &get }

sub getnext
{
	my $this = _handle_this( \@_ );

	my $pos = -1;

	my $result = $this->get( $this->counter+1 );

	return $result unless $result;

return $result;
}

sub GETNEXT { goto &getnext }

sub GETPREV
{
	my $this = _handle_this( \@_ );

return $this->getnext( $this->counter-1 );
}

sub LAST_COUNTER 
{ 
	my $this = _handle_this( \@_ );

return scalar @{ $this->[_LIST_REF] } - 1;
}

sub IS_LAST
{ 
    my $this = _handle_this( \@_ );

    return $this->COUNTER == $this->LAST_COUNTER;
}

sub IS_FIRST
{ 
    my $this = _handle_this( \@_ );

    return $this->COUNTER == 0;
}



sub pair
{
	my $this = _handle_this( \@_ );


	if( $this->COUNTER() % 2 == 0 )
	{
	    return ( $this->VALUE, $this->GETNEXT->VALUE );
	}

return ();
}

sub PAIR { goto &pair }

# some nice service functions

    sub transform_array_to_hash
      {
	my $array = shift;
	

	my $result;

	foreach ( iter $array )
	  {
	    if( COUNTER() % 2 == 0 )
	      {
		#printfln q{%s => %s}, VALUE, GETNEXT->VALUE;

		if( exists $result->{ VALUE() } )
		  {
		    push @{ $result->{ VALUE() } }, GETNEXT->VALUE;
		  }
		else
		  {
		    $result->{ VALUE() } = [ GETNEXT->VALUE ];
		  }
	      }
	  }
	
	return $result;
      }

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Data::Iter - easily iterate over a hash/array

=head1 SYNOPSIS

   my @obj = iter( $href );
   
   my @obj = iter( $aref );

=head1 EXAMPLE "Function Interface with exported iter()"

 use Data::Iter qw(:all);
   
     # as 'loop' functions
	 
   foreach ( iter [qw/Mon Tue Wnd Thr Fr Su So/] )
   {		
     printf "Day: %s [%s]\n", VALUE, COUNTER;
   }

   foreach ( iter { 1 => 'one', 2 => 'two', 3 => 'three', 4 => 'four' } )
   {	
     printf "%10s [%10s] %10d\n", KEY, VALUE, COUNTER;
		 
     print "End.\n" if COUNTER == LAST_COUNTER;
   }

   # An array is handles like a hash (preserves order of elements which hash's don't)

   foreach ( iter [qw(one 1 two 2 three 3)] )
   {		
      if( COUNTER() % 2 == 0 )
      {
          printfln q{%s => %s}, VALUE, GETNEXT->VALUE;
      }
   }

=head1 EXAMPLE "OO Interface"

 use Data::Iter;

     # as 'loop' methods
	 
   foreach ( Data::Iter->iter [qw/Mon Tue Wnd Thr Fr Su So/] )
   {		
     printf "Day: %s [%s]\n", $_->value, $_->counter;
   }

   foreach my $i ( iter [qw/Mon Tue Wnd Thr Fr Su So/] )
   {		
      printfln q{Day: %s [%s].  Next is %s     returned by $i->getnext()}, $i->VALUE, $i->counter, $i->getnext ? $i->getnext->VALUE : 'undef';
   }

   foreach ( Data::Iter->iter { 1 => 'one', 2 => 'two', 3 => 'three', 4 => 'four' } )
   {	
     printf "%10s [%10s] %10d\n", $_->key, $_->value, $_->counter;
   }

=head1 EXAMPLE "Modify during loop"

   my $h = { 1 => 'one', 2 => 'two', 3 => 'three', 4 => 'four' }

   foreach ( Data::Iter->iter( $h )  )
   {	
     printf "%10s [%10s] %10d\n", $_->key, $_->value( $_->value." camel" ), $_->counter;
   }

   # $h->{1} = 'one camel'
   # ...

=head1 DESCRIPTION

Data::Iter provides functions for comfortably iterating over perl data structures. Its slower, but
easier to code. An array containing object elements for every iteration is generated with the L<iter()> 
function - due to array'ish nature of for(), foreach() and map() loops it is easy to use.

=head2 FUNCTIONS AND METHODS

=head3 iter

Accepts a reference to an ARRAY or HASH. Returns a sorted list of 'Data::Iter' objects. So you can
use methods (or functions) during looping through this objects.

=head3 KEY( $newvalue )

Returns the current key (The key of the HASH entry). 

Same as $_->key( $newvalue )

[Note] For ARRAYs it is identical to L<COUNTER>.

[Info] B<$newvalue> is ignored. It is not implemented to set the original key, because i need help from a perl-guru
for this advanced stuff.

=head3 VALUE( $newvalue )

Returns the current key (HASHs only). B<$newvalue> is optional, but when given sets the original key.

Same as $_->value( $newvalue )

=head3 COUNTER()

 $_->counter()

Returns the current counter (starting at 0).

=head3 LAST_COUNTER()

Returns the highest counter. Its a synonmy for the length of the list-1.

=head3 IS_LAST(), IS_FIRST()

Returns true if is the highest or first counter, respectively.

=head3 getvalue( index )

Returns the value at index. It behaves like an array index.

=head3 GET( index )

Returns the Data::Iter object at index. It behaves like an array index.

Same as $_->get( index )

CAVE: Future variables are read-only ! It is the common "foreach( @something ) not change during iteration through it" story.

Example: 

	get(-1) will return the last iterator object. 
	
	get(-1)->counter will return the position of the last

	get(-1)->value will return the value of the last
	
	get(1+counter) will return the next object (same as getnext())

=head3 GETNEXT()

Returns the next Data::Iter object. It is a shortcut for get(1+counter).

Same as $_->getnext;

=head3 GETPREV()

Returns the prev Data::Iter object. It is a shortcut for get(counter-1).

=head3 PAIR()

Hash's can be imitated by arrays. The advantage is that then you can imitate an ordered hash. PAIR returs and array of

 ( KEY, VALUE )

pair when the iteration is at the right element or undef when it isnt. See here

    foreach my $r ( iter [qw(b red a white)] )
    {
       my ( $key, $value ) = $r->PAIR() 

       if( defined $value )
       {
       }
    }

Note: You have to test for undef of $key or $value, as pair returns every 2nd time a valid result.

=head1 $Data::Iter::Sort

This is per default { $a cmp $b } as you know it from C<sort>. One may set a it to an arbitrary sub ref that would normally given to C<sort>.
Two function are defined in the Data::Iter namespace per default.

    sub sort_alpha($$) { $_[0] cmp $_[1] }
    sub sort_num($$) { $_[0] <=> $_[1] }

As to use on of these, just set
 
 $Data::Iter::Sort = 'sort_alpha'

for alphanumeric sorting. 

[NOTE] Note that the $Sort var holds only a subroutine name, and not any reference ! As the $Data::Iter::Sort variable
is evaluated in its namespace the value "sort_alpha" will be expanded to the namespace "Data::Iter::sort_alpha" which indeed is the right
place of the function.

If you have really an own sort routine, than place it somewhere and set its name (with full namespace) to the $Sort variable:

 my $str3;

 sub sort_wild($$) { $_[0]+$_[1] <=> $_[1] }

 $Data::Iter::Sort = "::sort_wild";

	foreach ( iter \%numbers )
	{	
		$str3.=key;
	}

 println $str3;

[Note] "::sort_wild" refers to the 'main::' namespace, where this snippet was placed.

=head1 HIGHER FUNCTIONS

=head2 $hash_ref = transform_array_to_hash( $array_ref )

 $array_ref =
    [
    tcf1 => 28.44
    tcf1 => 28.13
    tcf3 => 26.92
    tcf3 => 26.09
    gapdh => 17.08
    gapdh => 16.1
    ];

Then a call

  transform_array_to_hash( $array_ref )

will return this hash

 {
   gapdh => ["17.08", "16.1"],
   tcf1  => ["28.44", "28.13"],
   tcf3  => ["26.92", "26.09"],
 }

=head1 BUGS

Not get(counter+1), but get(1+counter) will function correctly (under perl 5.6.0).

And get(counter - 1) does not work.

=head1 FUTURE

Add some decent $Data::Iter::options

=over 4

=item *
counter base value (for example start from 1 instead of 0).

=back

=head1 EXPORT

none by default.

'all' => (iter counter COUNTER LAST_COUNTER value VALUE key KEY get GET getnext GETNEXT)

=head1 PITFALLS

You should use L<iter()> only on 'quite' static structures. Since the static precalculated iterations
are not tied to the original data structure. So its changes will not be updated.

=head1 AUTHOR

Murat Uenalan, E<lt>muenalan@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::Iter>, L<Tie::Array::Iterable>, L<Object::Data::Iterate>

=cut
