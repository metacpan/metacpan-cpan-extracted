package Carp::Assert::More;

use warnings;
use strict;

use Exporter;
use Scalar::Util;

use vars qw( $VERSION @ISA @EXPORT );

=head1 NAME

Carp::Assert::More - Convenience assertions for common situations

=head1 VERSION

Version 2.0.1

=cut

BEGIN {
    $VERSION = '2.0.1';
    @ISA = qw(Exporter);
    @EXPORT = qw(
        assert_all_keys_in
        assert_aoh
        assert_arrayref
        assert_arrayref_nonempty
        assert_coderef
        assert_context_nonvoid
        assert_context_scalar
        assert_datetime
        assert_defined
        assert_empty
        assert_exists
        assert_fail
        assert_hashref
        assert_hashref_nonempty
        assert_in
        assert_integer
        assert_is
        assert_isa
        assert_isa_in
        assert_isnt
        assert_keys_are
        assert_lacks
        assert_like
        assert_listref
        assert_negative
        assert_negative_integer
        assert_nonblank
        assert_nonempty
        assert_nonnegative
        assert_nonnegative_integer
        assert_nonref
        assert_nonzero
        assert_nonzero_integer
        assert_numeric
        assert_positive
        assert_positive_integer
        assert_undefined
        assert_unlike
    );
}

my $INTEGER = qr/^-?\d+$/;

=head1 SYNOPSIS

A set of convenience functions for common assertions.

    use Carp::Assert::More;

    my $obj = My::Object;
    assert_isa( $obj, 'My::Object', 'Got back a correct object' );

=head1 DESCRIPTION

Carp::Assert::More is a convenient set of assertions to make the habit
of writing assertions even easier.

Everything in here is effectively syntactic sugar.  There's no technical
difference between calling one of these functions:

    assert_datetime( $foo );
    assert_isa( $foo, 'DateTime' );

that are provided by Carp::Assert::More and calling these assertions
from Carp::Assert

    assert( defined $foo );
    assert( ref($foo) eq 'DateTime' );

My intent here is to make common assertions easy so that we as programmers
have no excuse to not use them.

=head1 SIMPLE ASSERTIONS

=head2 assert_is( $string, $match [,$name] )

Asserts that I<$string> matches I<$match>.

=cut

sub assert_is($$;$) {
    my $string = shift;
    my $match = shift;
    my $name = shift;

    if ( defined($string) ) {
        return if defined($match) && ($string eq $match);
    }
    else {
        return if !defined($match);
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_isnt( $string, $unmatch [,$name] )

Asserts that I<$string> does NOT match I<$unmatch>.

=cut

sub assert_isnt($$;$) {
    my $string = shift;
    my $unmatch = shift;
    my $name = shift;

    # undef only matches undef
    return if defined($string) xor defined($unmatch);

    return if defined($string) && defined($unmatch) && ($string ne $unmatch);

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_like( $string, qr/regex/ [,$name] )

Asserts that I<$string> matches I<qr/regex/>.

The assertion fails either the string or the regex are undef.

=cut

sub assert_like($$;$) {
    my $string = shift;
    my $regex = shift;
    my $name = shift;

    if ( defined($string) && !ref($string) ) {
        if ( ref($regex) ) {
            return if $string =~ $regex;
        }
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_unlike( $string, qr/regex/ [,$name] )

Asserts that I<$string> matches I<qr/regex/>.

The assertion fails if the regex is undef.

=cut

sub assert_unlike($$;$) {
    my $string = shift;
    my $regex  = shift;
    my $name   = shift;

    return if !defined($string);

    if ( ref($regex) eq 'Regexp' ) {
        return if $string !~ $regex;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_defined( $this [, $name] )

Asserts that I<$this> is defined.

=cut

sub assert_defined($;$) {
    return if defined( $_[0] );

    require Carp;
    &Carp::confess( _fail_msg($_[1]) );
}


=head2 assert_undefined( $this [, $name] )

Asserts that I<$this> is not defined.

=cut

sub assert_undefined($;$) {
    return unless defined( $_[0] );

    require Carp;
    &Carp::confess( _fail_msg($_[1]) );
}

=head2 assert_nonblank( $this [, $name] )

Asserts that I<$this> is not a reference and is not an empty string.

=cut

sub assert_nonblank($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) && !ref($this) ) {
        return if $this ne '';
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head1 NUMERIC ASSERTIONS

=head2 assert_numeric( $n [, $name] )

Asserts that C<$n> looks like a number, according to C<Scalar::Util::looks_like_number>.
C<undef> will always fail.

=cut

sub assert_numeric {
    my $n    = shift;
    my $name = shift;

    return if Scalar::Util::looks_like_number( $n );

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_integer( $this [, $name ] )

Asserts that I<$this> is an integer, which may be zero or negative.

    assert_integer( 0 );      # pass
    assert_integer( 14 );     # pass
    assert_integer( -14 );    # pass
    assert_integer( '14.' );  # FAIL

=cut

sub assert_integer($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) ) {
        return if $this =~ $INTEGER;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_nonzero( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined and is not zero.

    assert_nonzero( 0 );    # FAIL
    assert_nonzero( -14 );  # pass
    assert_nonzero( '14.' );  # pass

=cut

sub assert_nonzero($;$) {
    my $this = shift;
    my $name = shift;

    if ( Scalar::Util::looks_like_number($this) ) {
        return if $this != 0;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_positive( $this [, $name ] )

Asserts that I<$this> is defined, numeric and greater than zero.

    assert_positive( 0 );    # FAIL
    assert_positive( -14 );  # FAIL
    assert_positive( '14.' );  # pass

=cut

sub assert_positive($;$) {
    my $this = shift;
    my $name = shift;

    if ( Scalar::Util::looks_like_number($this) ) {
        return if ($this+0 > 0);
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_nonnegative( $this [, $name ] )

Asserts that I<$this> is defined, numeric and greater than or equal
to zero.

    assert_nonnegative( 0 );      # pass
    assert_nonnegative( -14 );    # FAIL
    assert_nonnegative( '14.' );  # pass
    assert_nonnegative( 'dog' );  # pass

=cut

sub assert_nonnegative($;$) {
    my $this = shift;
    my $name = shift;

    if ( Scalar::Util::looks_like_number( $this ) ) {
        return if $this >= 0;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_negative( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined and less than zero.

    assert_negative( 0 );       # FAIL
    assert_negative( -14 );     # pass
    assert_negative( '14.' );   # FAIL

=cut

sub assert_negative($;$) {
    my $this = shift;
    my $name = shift;

    no warnings;
    return if defined($this) && ($this+0 < 0);

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_nonzero_integer( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined, an integer, and not zero.

    assert_nonzero_integer( 0 );      # FAIL
    assert_nonzero_integer( -14 );    # pass
    assert_nonzero_integer( '14.' );  # FAIL

=cut

sub assert_nonzero_integer($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) && ($this =~ $INTEGER) ) {
        return if $this != 0;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_positive_integer( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined, an integer and greater than zero.

    assert_positive_integer( 0 );     # FAIL
    assert_positive_integer( -14 );   # FAIL
    assert_positive_integer( '14.' ); # FAIL
    assert_positive_integer( '14' );  # pass

=cut

sub assert_positive_integer($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) && ($this =~ $INTEGER) ) {
        return if $this > 0;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_nonnegative_integer( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined, an integer, and not less than zero.

    assert_nonnegative_integer( 0 );      # pass
    assert_nonnegative_integer( -14 );    # FAIL
    assert_nonnegative_integer( '14.' );  # FAIL

=cut

sub assert_nonnegative_integer($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) && ($this =~ $INTEGER) ) {
        return if $this >= 0;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_negative_integer( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined, an integer, and less than zero.

    assert_negative_integer( 0 );      # FAIL
    assert_negative_integer( -14 );    # pass
    assert_negative_integer( '14.' );  # FAIL

=cut

sub assert_negative_integer($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) && ($this =~ $INTEGER) ) {
        return if $this < 0;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head1 REFERENCE ASSERTIONS

=head2 assert_isa( $this, $type [, $name ] )

Asserts that I<$this> is an object of type I<$type>.

=cut

sub assert_isa($$;$) {
    my $this = shift;
    my $type = shift;
    my $name = shift;

    # The assertion is true if
    # 1) For objects, $this is of class $type or of a subclass of $type
    # 2) For non-objects, $this is a reference to a HASH, SCALAR, ARRAY, etc.

    return if Scalar::Util::blessed( $this ) && $this->isa( $type );
    return if ref($this) eq $type;

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_isa_in( $obj, \@types [, $description] )

Assert that the blessed C<$obj> isa one of the types in C<\@types>.

    assert_isa_in( $obj, [ 'My::Foo', 'My::Bar' ], 'Must pass either a Foo or Bar object' );

=cut

sub assert_isa_in($$;$) {
    my $obj   = shift;
    my $types = shift;
    my $name  = shift;

    if ( Scalar::Util::blessed($obj) ) {
        for ( @{$types} ) {
            return if $obj->isa($_);
        }
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_empty( $this [, $name ] )

I<$this> must be a ref to either a hash or an array.  Asserts that that
collection contains no elements.  Will assert (with its own message,
not I<$name>) unless given a hash or array ref.   It is OK if I<$this> has
been blessed into objecthood, but the semantics of checking an object to see
if it does not have keys (for a hashref) or returns 0 in scalar context (for
an array ref) may not be what you want.

    assert_empty( 0 );       # FAIL
    assert_empty( 'foo' );   # FAIL
    assert_empty( undef );   # FAIL
    assert_empty( {} );      # pass
    assert_empty( [] );      # pass
    assert_empty( {foo=>1} );# FAIL
    assert_empty( [1,2,3] ); # FAIL

=cut

sub assert_empty($;$) {
    my $ref = shift;
    my $name = shift;

    my $underlying_type;
    if ( Scalar::Util::blessed( $ref ) ) {
        $underlying_type = Scalar::Util::reftype( $ref );
    }
    else {
        $underlying_type = ref( $ref );
    }

    if ( $underlying_type eq 'HASH' ) {
        return if scalar keys %{$ref} == 0;
    }
    elsif ( $underlying_type eq 'ARRAY' ) {
        return if @{$ref} == 0;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_nonempty( $this [, $name ] )

I<$this> must be a ref to either a hash or an array.  Asserts that that
collection contains at least 1 element.  Will assert (with its own message,
not I<$name>) unless given a hash or array ref.   It is OK if I<$this> has
been blessed into objecthood, but the semantics of checking an object to see
if it has keys (for a hashref) or returns >0 in scalar context (for an array
ref) may not be what you want.

    assert_nonempty( 0 );       # FAIL
    assert_nonempty( 'foo' );   # FAIL
    assert_nonempty( undef );   # FAIL
    assert_nonempty( {} );      # FAIL
    assert_nonempty( [] );      # FAIL
    assert_nonempty( {foo=>1} );# pass
    assert_nonempty( [1,2,3] ); # pass

=cut

sub assert_nonempty($;$) {
    my $ref = shift;
    my $name = shift;

    my $underlying_type;
    if ( Scalar::Util::blessed( $ref ) ) {
        $underlying_type = Scalar::Util::reftype( $ref );
    }
    else {
        $underlying_type = ref( $ref );
    }

    if ( $underlying_type eq 'HASH' ) {
        return if scalar keys %{$ref} > 0;
    }
    elsif ( $underlying_type eq 'ARRAY' ) {
        return if scalar @{$ref} > 0;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_nonref( $this [, $name ] )

Asserts that I<$this> is not undef and not a reference.

=cut

sub assert_nonref($;$) {
    my $this = shift;
    my $name = shift;

    assert_defined( $this, $name );
    return unless ref( $this );

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_hashref( $ref [,$name] )

Asserts that I<$ref> is defined, and is a reference to a (possibly empty) hash.

B<NB:> This method returns I<false> for objects, even those whose underlying
data is a hashref. This is as it should be, under the assumptions that:

=over 4

=item (a)

you shouldn't rely on the underlying data structure of a particular class, and

=item (b)

you should use C<assert_isa> instead.

=back

=cut

sub assert_hashref($;$) {
    my $ref = shift;
    my $name = shift;

    if ( ref($ref) eq 'HASH' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'HASH' )) ) {
        return;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_hashref_nonempty( $ref [,$name] )

Asserts that I<$ref> is defined and is a reference to a hash with at
least one key/value pair.

=cut

sub assert_hashref_nonempty($;$) {
    my $ref = shift;
    my $name = shift;

    if ( ref($ref) eq 'HASH' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'HASH' )) ) {
        return if scalar keys %{$ref} > 0;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_arrayref( $ref [, $name] )

=head2 assert_listref( $ref [,$name] )

Asserts that I<$ref> is defined, and is a reference to an array, which
may or may not be empty.

B<NB:> The same caveat about objects whose underlying structure is a
hash (see C<assert_hashref>) applies here; this method returns false
even for objects whose underlying structure is an array.

C<assert_listref> is an alias for C<assert_arrayref> and may go away in
the future.  Use C<assert_arrayref> instead.

=cut

sub assert_arrayref($;$) {
    my $ref  = shift;
    my $name = shift;

    if ( ref($ref) eq 'ARRAY' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'ARRAY' )) ) {
        return;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}
*assert_listref = *assert_arrayref;


=head2 assert_arrayref_nonempty( $ref [, $name] )

Asserts that I<$ref> is reference to an array that has at least one element in it.

=cut

sub assert_arrayref_nonempty($;$) {
    my $ref  = shift;
    my $name = shift;

    if ( ref($ref) eq 'ARRAY' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'ARRAY' )) ) {
        return if scalar @{$ref} > 0;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_aoh( $ref [, $name ] )

Verifies that C<$array> is an arrayref, and that every element is a hashref.

The array C<$array> can be an empty arraref and the assertion will pass.

=cut

sub assert_aoh {
    my $ref  = shift;
    my $name = shift;

    my $ok = 0;
    if ( ref($ref) eq 'ARRAY' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'ARRAY' )) ) {
        $ok = 1;
        for my $val ( @{$ref} ) {
            if ( not ( ref($val) eq 'HASH' || (Scalar::Util::blessed( $val) && $val->isa( 'HASH' )) ) ) {
                $ok = 0;
                last;
            }
        }
    }

    return if $ok;

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_coderef( $ref [,$name] )

Asserts that I<$ref> is defined, and is a reference to a closure.

=cut

sub assert_coderef($;$) {
    my $ref = shift;
    my $name = shift;

    if ( ref($ref) eq 'CODE' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'CODE' )) ) {
        return;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head1 TYPE-SPECIFIC ASSERTIONS

=head2 assert_datetime( $date )

Asserts that C<$date> is a DateTime object.

=cut

sub assert_datetime($;$) {
    my $ref  = shift;
    my $name = shift;

    if ( ref($ref) eq 'DateTime' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'DateTime' )) ) {
        return;
    }

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head1 SET AND HASH MEMBERSHIP

=head2 assert_in( $string, \@inlist [,$name] );

Asserts that I<$string> matches one of the elements of I<\@inlist>.
I<$string> may be undef.

I<\@inlist> must be an array reference of non-ref strings.  If any
element is a reference, the assertion fails.

=cut

sub assert_in($$;$) {
    my $needle = shift;
    my $haystack = shift;
    my $name = shift;

    my $found = 0;

    # String has to be a non-ref scalar, or undef.
    if ( !ref($needle) ) {

        # Target list has to be an array...
        if ( ref($haystack) eq 'ARRAY' || (Scalar::Util::blessed( $haystack ) && $haystack->isa( 'ARRAY' )) ) {

            # ... and all elements have to be non-refs.
            my $elements_ok = 1;
            foreach my $element (@{$haystack}) {
                if ( ref($element) ) {
                    $elements_ok = 0;
                    last;
                }
            }

            # Now we can actually do the search.
            if ( $elements_ok ) {
                if ( defined($needle) ) {
                    foreach my $element (@{$haystack}) {
                        if ( $needle eq $element ) {
                            $found = 1;
                            last;
                        }
                    }
                }
                else {
                    foreach my $element (@{$haystack}) {
                        if ( !defined($element) ) {
                            $found = 1;
                            last;
                        }
                    }
                }
            }
        }
    }

    return if $found;

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_exists( \%hash, $key [,$name] )

=head2 assert_exists( \%hash, \@keylist [,$name] )

Asserts that I<%hash> is indeed a hash, and that I<$key> exists in
I<%hash>, or that all of the keys in I<@keylist> exist in I<%hash>.

    assert_exists( \%custinfo, 'name', 'Customer has a name field' );

    assert_exists( \%custinfo, [qw( name addr phone )],
                            'Customer has name, address and phone' );

=cut

sub assert_exists($$;$) {
    my $hash = shift;
    my $key = shift;
    my $name = shift;

    my $ok = 0;

    if ( ref($hash) eq 'HASH' || (Scalar::Util::blessed( $hash ) && $hash->isa( 'HASH' )) ) {
        if ( defined($key) ) {
            if ( ref($key) eq 'ARRAY' ) {
                $ok = (@{$key} > 0);
                for ( @{$key} ) {
                    if ( !exists( $hash->{$_} ) ) {
                        $ok = 0;
                        last;
                    }
                }
            }
            elsif ( !ref($key) ) {
                $ok = exists( $hash->{$key} );
            }
            else {
                $ok = 0;
            }
        }
    }

    return if $ok;

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_lacks( \%hash, $key [,$name] )

=head2 assert_lacks( \%hash, \@keylist [,$name] )

Asserts that I<%hash> is indeed a hash, and that I<$key> does NOT exist
in I<%hash>, or that none of the keys in I<@keylist> exist in I<%hash>.
The list C<@keylist> cannot be empty.

    assert_lacks( \%users, 'root', 'Root is not in the user table' );

    assert_lacks( \%users, [qw( root admin nobody )], 'No bad usernames found' );

=cut

sub assert_lacks($$;$) {
    my $hash = shift;
    my $key = shift;
    my $name = shift;

    my $ok = 0;

    if ( ref($hash) eq 'HASH' || (Scalar::Util::blessed( $hash ) && $hash->isa( 'HASH' )) ) {
        if ( defined($key) ) {
            if ( ref($key) eq 'ARRAY' ) {
                $ok = (@{$key} > 0);
                for ( @{$key} ) {
                    if ( exists( $hash->{$_} ) ) {
                        $ok = 0;
                        last;
                    }
                }
            }
            elsif ( !ref($key) ) {
                $ok = !exists( $hash->{$key} );
            }
            else {
                $ok = 0;
            }
        }
    }

    return if $ok;

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_all_keys_in( \%hash, \@names [, $name ] )

Asserts that each key in C<%hash> is in the list of C<@names>.

This is used to ensure that there are no extra keys in a given hash.

    assert_all_keys_in( $obj, [qw( height width depth )], '$obj can only contain height, width and depth keys' );

You can pass an empty list of C<@names>.

=cut

sub assert_all_keys_in($$;$) {
    my $hash = shift;
    my $keys = shift;
    my $name = shift;

    my $ok = 0;
    if ( ref($hash) eq 'HASH' || (Scalar::Util::blessed( $hash ) && $hash->isa( 'HASH' )) ) {
        if ( ref($keys) eq 'ARRAY' ) {
            $ok = 1;
            my %keys = map { $_ => 1 } @{$keys};
            for my $key ( keys %{$hash} ) {
                if ( !exists $keys{$key} ) {
                    $ok = 0;
                    last;
                }
            }
        }
    }

    return if $ok;

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_keys_are( \%hash, \@keys [, $name ] )

Asserts that the keys for C<%hash> are exactly C<@keys>, no more and no less.

=cut

sub assert_keys_are($$;$) {
    my $hash = shift;
    my $keys = shift;
    my $name = shift;

    my $ok = 0;
    if ( ref($hash) eq 'HASH' || (Scalar::Util::blessed( $hash ) && $hash->isa( 'HASH' )) ) {
        if ( ref($keys) eq 'ARRAY' ) {
            my %keys = map { $_ => 1 } @{$keys};

            my @hashkeys = keys %{$hash};
            if ( scalar @hashkeys == scalar keys %keys ) {
                $ok = 1;
                for my $key ( @hashkeys ) {
                    if ( !exists $keys{$key} ) {
                        $ok = 0;
                        last;
                    }
                }
            }
        }
    }

    return if $ok;

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head1 CONTEXT ASSERTIONS

=head2 assert_context_nonvoid( [$name] )

Verifies that the function currently being executed has not been called
in void context.  This is to ensure the calling function is not ignoring
the return value of the executing function.

Given this function:

    sub something {
        ...

        assert_context_scalar();

        return $important_value;
    }

These calls to C<something> will pass:

    my $val = something();
    my @things = something();

but this will fail:

    something();

=cut

sub assert_context_nonvoid(;$) {
    my $name = shift;

    my $wantarray = (caller(1))[5];

    return if defined($wantarray);

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head2 assert_context_scalar( [$name] )

Verifies that the function currently being executed has been called in
scalar context.  This is to ensure the calling function is not ignoring
the return value of the executing function.

Given this function:

    sub something {
        ...

        assert_context_scalar();

        return $important_value;
    }

This call to C<something> will pass:

    my $val = something();

but these will fail:

    something();
    my @things = something();

=cut

sub assert_context_scalar(;$) {
    my $name = shift;

    my $wantarray = (caller(1))[5];

    return if defined($wantarray) && !$wantarray;

    require Carp;
    &Carp::confess( _fail_msg($name) );
}


=head1 UTILITY ASSERTIONS

=head2 assert_fail( [$name] )

Assertion that always fails.  C<assert_fail($msg)> is exactly the same
as calling C<assert(0,$msg)>, but it eliminates that case where you
accidentally use C<assert($msg)>, which of course never fires.

=cut

sub assert_fail(;$) {
    require Carp;
    &Carp::confess( _fail_msg($_[0]) );
}


# Can't call confess() here or the stack trace will be wrong.
sub _fail_msg {
    my($name) = shift;
    my $msg = 'Assertion';
    $msg   .= " ($name)" if defined $name;
    $msg   .= " failed!\n";
    return $msg;
}


=head1 COPYRIGHT & LICENSE

Copyright 2005-2021 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=head1 ACKNOWLEDGEMENTS

Thanks to
Eric A. Zarko,
Bob Diss,
Pete Krawczyk,
David Storrs,
Dan Friedman,
Allard Hoeve,
Thomas L. Shinnick,
and Leland Johnson
for code and fixes.

=cut

1;
