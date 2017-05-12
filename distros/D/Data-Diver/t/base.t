# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl base.t'
use strict;
BEGIN {
    $^W++;
    if(  -d 'blib'  ) {
        require lib;
        lib->import( qw( blib lib ) );
    }
}

use Test qw( plan ok skip );

sub Ok($;$$) {
    @_= @_ < 3 ? reverse @_ : @_[1,0,2];
    goto &ok;
}

sub Skip($$;$$) {
    my $ok= shift @_;
    @_= reverse @_;
    unshift @_, $ok ? ''
        : 'skip: prior test failed';
    goto &skip;
}

BEGIN {
    $|++;
    plan( tests => 92 );
    require Data::Diver;
    Ok( 1 );
}

use Data::Diver qw( Dive DiveRef DiveVal DiveDie DiveError DiveClear );

Ok( 1 );

# Verify the synopsis:

    my $root= {
        top => [
            {   first => 1 },
            {   second => {
                    key => [
                        0, 1, 2, {
                            three => {
                                exists => 'yes',
                            },
                        },
                    ],
                },
            },
        ],
    };

Ok( 0, ()= DiveError() );
Ok( 0, eval { ()= DiveDie() }, $@ );
Ok( 1, eval { ()= DiveDie(undef) }, $@ );
Ok( 'x', eval { DiveDie('x') }, $@ );

    # Sets $value to 'yes'
    # ( $root->{top}[1]{second}{key}[3]{three}{exists} ):
    my $value= Dive( $root, qw( top 1 second key 3 three exists ) );

Ok( 'yes', $value );
Ok( 0, ()= DiveError() );
    $value= DiveRef( $root, qw( top 1 second key 3 three exists ) );
Skip(
    Ok( 'SCALAR', ref($value) ),
    'yes', $$value );
Ok( 'yes', eval {
    DiveDie( $root, qw( top 1 second key 3 three exists ) );
}, $@ );

    # Sets $value to undef() because "missing" doesn't exist:
    $value= Dive( $root, qw( top 1 second key 3 three missing ) );

Ok( undef, $value );
Ok( 3, ()= DiveError() );
Ok( '/Key not present/', ( DiveError() )[0] );
Ok( $root->{top}[1]{second}{key}[3]{three},
    ( DiveError() )[1] );
Skip(
    Ok( 'SCALAR', ref( ( DiveError() )[2] ) ),
    'missing', ${ ( DiveError() )[2] } );
Ok( undef, eval { DiveDie(); 1 } );
Ok( '/Key not present/', $@ );
Ok( 1, eval { ()= DiveDie(undef) }, $@ );
Ok( 'x', eval { DiveDie('x') }, $@ );
Ok( 'yes', eval {
    DiveDie( $root, qw( top 1 second key 3 three exists ) );
}, $@ );

    # Sets $value to undef() because
    # $root->{top}[1]{second}{key}[4] is off the end of the array:
    $value= Dive( $root, qw( top 1 second key 4 ... ) );

Ok( undef, $value );
Ok( 3, ()= DiveError() );
Ok( '/out of range/', ( DiveError() )[0] );
Ok( $root->{top}[1]{second}{key},
    ( DiveError() )[1] );
Skip(
    Ok( 'SCALAR', ref( ( DiveError() )[2] ) ),
    4, ${ ( DiveError() )[2] } );

    # Sets $value to undef() because
    # $root->{top}[1]{second}{key}[-5] would be a fatal error:
    $value= Dive( $root, qw( top 1 second key -5 ... ) );

Ok( undef, $value );
Ok( 3, ()= DiveError() );
Ok( '/out of range/', ( DiveError() )[0] );
Ok( $root->{top}[1]{second}{key},
    ( DiveError() )[1] );
Skip(
    Ok( 'SCALAR', ref( ( DiveError() )[2] ) ),
    -5, ${ ( DiveError() )[2] } );

    # Sets $ref to \$root->{top}[9]{new}{sub} (which grows
    # @{ $root->{top} } and autovifies two anonymous hashes):
    my $ref= DiveRef( $root, qw( top 9 new sub ) );

Ok( 10, @{ $root->{top} } );
Ok( exists $root->{top}[9]{new} );
Ok( exists $root->{top}[9]{new}{sub} );
Ok( \$root->{top}[9]{new}{sub}, $ref );

    # die()s because "other" isn't a valid number:
Ok( undef, eval {
    $ref= DiveRef( $root, qw( top other ... ) );
    1
} );

    # Does: $root->{num}{1}{2}= 3;
    # (Autovivifies hashes despite the numeric keys.)
Ok( 3, eval {
    DiveVal( $root, \( qw( num 1 2 ) ) ) = 3;
}, $@ );
Ok( 3, eval { $root->{num}{1}{2} }, $@ );
    delete $root->{num};

    # Same thing:
Ok( 3, eval {
    ${ DiveRef( $root, 'num', \1, \2 ) } = 3;
}, $@ );
Ok( 3, $root->{num}{1}{2} );

    # Retrieves above value, $value= 3:
Ok( 3, eval {
    $value= DiveVal( $root, 'num', \1, \2 );
}, $@ );
    # Same thing:
Ok( 3, eval {
    $value= ${ DiveRef( $root,  \( qw( num 1 2 ) ) ) };
}, $@ );

    # Tries to do $root->{top}{1} and dies
    # because $root->{top} is an array reference:
Ok( undef, eval {
    DiveRef( $root, 'top', \1 );
}, $@ );

    # To only autovivify at the last step:
    $ref= DiveRef(
        Dive( $root, qw( top 1 second key 3 three ) ),
        'missing' );
Ok( exists $root->{top}[1]{second}{key}[3]{three}{missing} );
Ok( \$root->{top}[1]{second}{key}[3]{three}{missing}, $ref );
Ok( 1, eval {
    if(  $ref  ) {
        $$ref= 'me too'
    } else {
        my( $nestedRef, $svKey, $errDesc )= DiveError();
        die "Couldn't dereference $nestedRef via $$svKey: $errDesc\n";
    }
1 }, $@ );

Ok( 'me too', $root->{top}[1]{second}{key}[3]{three}{missing} );

    DiveClear();
Ok( 0, ()= DiveError() );
Ok( 0, eval { ()= DiveDie() }, $@ );

# Data::Diver does C<use strict;>
Ok( undef, eval { DiveRef( { foo=>'bar' }, 'foo', 'bar' ); 1 } );
Ok( '/strict refs/', $@ );
Ok( undef, eval { DiveDie( { foo=>'bar' }, 'foo', 'bar' ); 1 } );
Ok( '/valid type of ref/', $@ );
Ok( undef, Dive( { foo=>'bar' }, 'foo', 'baz' ) );
Ok( 3, ()= DiveError() );
Ok( '/valid type of ref/', ( DiveError() )[0] );
Ok( 'bar', ( DiveError() )[1] );
Skip(
    Ok( 'SCALAR', ref( ( DiveError() )[2] ) ),
    'baz', ${ ( DiveError() )[2] } );


# to distinguish between C<exists> and C<defined>

my %hashOfHashes= ( first => { second => undef } );

    my @exists= Dive( \%hashOfHashes, 'first', 'second' );
Ok( 1, @exists );
    if(  ! @exists  ) {
        Ok(0);
        warn "\$hashOfHashes{first}{second} does not exists.\n";
    } elsif(  ! defined $exists[0]  ) {
        Ok(1);
    } else {
        Ok(0);
    }

%hashOfHashes= ( first => { x => 1 } );

    @exists= Dive( \%hashOfHashes, 'first', 'second' );
Ok( 0, @exists );
    if(  ! @exists  ) {
        Ok(1);
    } elsif(  ! defined $exists[0]  ) {
        Ok(0);
        warn "\$hashOfHashes{first}{second} exists but is undefined.\n";
    } else {
        Ok(0);
    }

# If $root is undefined, then DiveRef() immediately returns C<( undef )>
Ok( 1, ()= DiveRef(undef) );
Ok( undef, DiveRef(undef) );
Ok( 0, ()= DiveRef() );
# [without overwriting C<DiveError()>].
Ok( '/Key not present/', ( DiveError() )[0] );
Ok( $hashOfHashes{first}, ( DiveError() )[1] );
Skip(
    Ok( 'SCALAR', ref( ( DiveError() )[2] ) ),
    'second', ${ ( DiveError() )[2] } );

# C<DiveRef( Dive( ... ), ... )> to only allow partial autovivifying
#TBD!!!

$root= \[ \'spot' ];
Ok( 'spot', Dive( $root, undef, 0, undef ) );
Ok( 'spot', Dive( DiveRef( $root, undef, 0, undef ), undef ) );
Ok( 0, ()= Dive( $root, 0 ) );
Ok( 0, ()= Dive( $root, undef, undef ) );
Ok( 0, ()= Dive( $root, undef, 0, undef, undef ) );

# For DiveRef(), if C<$ref> is C<undef>, ... autovivified
undef $root;
@exists= DiveRef( \$root, undef );
Ok( 1, @exists );
Ok( \$root, $exists[0] );
Ok( undef, $root );
@exists= DiveRef( \$root, undef, undef );
Ok( 1, @exists );
Skip(
    Ok( 'SCALAR', ref($root) ),
    undef, $$root );
Ok( $root, $exists[0] );
# [that will start out undefined but may quickly
@exists= DiveRef( \$root, undef, undef, 0 );
Ok( 1, @exists );
Ok( 'ARRAY', ref($$root) );
Ok( \$$root->[0], $exists[0] );

$root = [ sub { return Dive( \$root, @_ ) } ];
Ok( $root, Dive( $root, 0, [], undef, undef ) );
Ok( $root, Dive( $root, 0, [], 0, undef ) );
Ok( $root, Dive( $root, 0, [undef], undef ) );
Ok( $root, Dive( $root, 0, [undef], 0 ) );

__END__

=item C<$key =~ m/^-?\d+$/>

For DiveRef(), if C<$ref> is undefined, then it is autovivified into
a reference to anonymous array.  If C<$ref> can act as a reference
to an array, then C<< $ref= $ref->[$key] >> is attempted.  If $key is
larger than $#$ref, then @$ref will grow.  If $key is less than
-@$ref, then Perl will C<die>.

If C<$ref> cannot act as a reference to an array, then $ref might be
used as a reference to a hash as described further down.

=item a reference to an array

If $key can be used as a reference to an array, then it means that
you might expect C<$ref> to be a reference to a subroutine.

If C<UNIVERSAL::isa( $ref, 'CODE' )> is true, then C<< $ref->( @$key ) >>
is attempted.

If $key isn't the last value in @ListOfKeys and the next value is
undefined, then &$ref is called in a scalar context and $ref is set
to refer to the scalar value returned.

Otherwise, &$ref is called in a list context and $ref is set to refer
to an anonymous array containing the value(s) returned.

=item any (defined) string

This means that you might expect C<$ref> to be a reference to a hash.

For Dive(), if C<$ref> can act as a reference to a hash and
C<<exists $ref->{$key} >> is true, then C<< $ref= $ref->{$key}; >> is run
[and this can't fail nor autovivify].

Otherwise, Dive() returns an empty list and DiveError() can tell you
where the problem was.

For DiveRef(), C<< $ref= $ref->{$key} >> is simply attempted.  This may
autovivify a hash entry or even a new hash.  It may also C<die>, for
example, if $ref can't be used as a hash reference.

=back

Note that the order of the above items is significant.  It represents
the order in which cases are tested.  So an undefined $key will only
be for derefencing a scalar reference and a numeric key will prefer
to treat a reference as an array reference.

