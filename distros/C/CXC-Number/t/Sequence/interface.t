#! perl

use Test2::V0;
use Test2::V0 qw( meta );
use Test::Lib;
use CXC::Number::Sequence;

sub Sequence { join( '::', 'CXC::Number::Sequence', @_ ) }

sub Failure { join( '::', 'CXC::Number::Sequence::Failure', @_ ) }

subtest 'new' => sub {

    is(
        Sequence->new( elements => [ 0 .. 11 ] ),
        object {
            prop blessed => Sequence;
            call min      => 0;
            call max      => 11;
            call nelem    => 12;
            call elements => [ 0 .. 11 ];
        },
        'baseline'
    );

    subtest constraints => sub {

        subtest 'out of order' => sub {
            my $err = dies { Sequence->new( elements => [ 1, 0, 2 ] ) };
            isa_ok( $err, 'Error::TypeTiny::Assertion' );
            like( $err, qr/array of monotonically increasing numbers/ );
        };

        subtest 'duplicate' => sub {
            my $err = dies { Sequence->new( elements => [ 1, 1, 2 ] ) };
            isa_ok( $err, 'Error::TypeTiny::Assertion' );
            like( $err, qr/array of monotonically increasing numbers/ );
        };

        subtest 'not numbers' => sub {
            my $err = dies { Sequence->new( elements => [ 'foo', 'bar' ] ) };
            isa_ok( $err, 'Error::TypeTiny::Assertion' );
            # $err stringifies via validate_explain?
            like( $err, qr/constrains .* with "BigNum"/ );
        };

        subtest 'empty sequence' => sub {
            my $err = dies { Sequence->new( elements => [] ) };
            isa_ok( $err, 'Error::TypeTiny::Assertion' );
            like( $err, qr/array length/ );
        };
    };

};

subtest bignum => sub {

    my $seq;

    ok( lives { $seq = Sequence->new( elements => [ 0 .. 11 ] )->bignum } )
      or diag $@;

    my $isa_bignum          = meta { prop blessed => 'Math::BigFloat' };
    my $isa_array_of_bignum = array { all_items( $isa_bignum ); etc; };

    is( $seq->min,      $isa_bignum,          'min' );
    is( $seq->max,      $isa_bignum,          'max' );
    is( $seq->spacing,  $isa_array_of_bignum, 'spacing' );
    is( $seq->elements, $isa_array_of_bignum, 'elements' );

};

subtest PDL => sub {

  SKIP: {
        skip( q[PDL isn't installed; skipping tests] )
          unless eval "require PDL; 1;";

        my $pdl = sub { PDL->pdl( @_ ) };

        my $seq;

        ok( lives { $seq = Sequence->new( elements => [ 0 .. 11 ] )->pdl } )
          or diag $@;

        my $isa_PDL = meta { prop blessed => 'PDL' };

        isnt( $seq->min, $isa_PDL, 'min' );
        isnt( $seq->max, $isa_PDL, 'max' );

        is( $seq->spacing,        $isa_PDL, 'spacing' );
        is( $seq->spacing->nelem, 11,       'spacing has correct shape' );

        is( $seq->elements,        $isa_PDL, 'elements' );
        is( $seq->elements->nelem, 12,       'elements has correct shape' );
    }

};


subtest build => sub {

    is(
        Sequence->build( fixed =>, elements => [ 0 .. 11 ] ),
        object {
            prop blessed => Sequence( 'Fixed' );
            call min      => 0;
            call max      => 11;
            call nelem    => 12;
            call elements => [ 0 .. 11 ];
        },
        "class in @{[ Sequence ]} namespace"
    );

    isa_ok(
        dies { Sequence->build( fixedButNotInNamespace => ) },
        [ Failure( 'loadclass::NoClass' ) ],
        'Not in namespace'
    );

    is(
        Sequence->build( 'My::Sequence::Lives' ),
        object {
            prop blessed => 'My::Sequence::Lives';
        },
        'absolute sequence class path'
    );

    isa_ok(
        dies { Sequence->build( 'My::Sequence::Fails' ) },
        [ Failure( 'loadclass::CompileError' ) ],
        'compile error'
    );


};

done_testing;
