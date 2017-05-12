package t::Crypt::Perl::ECDSA::Math;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use Crypt::Format ();
use Digest::SHA ();
use File::Slurp ();
use File::Temp ();
use MIME::Base64 ();

use lib "$FindBin::Bin/lib";

use parent qw( TestClass );

use Crypt::Perl::BigInt ();

use Crypt::Perl::ECDSA::Math ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new();

    $self->num_method_tests( 'test_jacobi', 2 * @{ [_JACOBI_TESTS()] } );
    $self->num_method_tests( 'test_tonelli_shanks', 0 + @{ [_TONELLI_SHANKS_TESTS()] } );

    return $self;
}

sub _TONELLI_SHANKS_TESTS {
    return (

        #From libtom’s own tests
        { n => 14, p => 5, r => 3 },    #or 2
        { n => 9, p => 7, r => 4 },     #or 3
        { n => 2, p => 113, r => 62 },  #or 51

        #https://rosettacode.org/wiki/Tonelli-Shanks_algorithm
        { n => 10, p => 13, r => 7 },
        { n => 56, p => 101, r => 37 },
        { n => 1030, p => 10009, r => 1632 },
        { n => 44402, p => 100049, r => 30468 },
        { n => 665820697, p => 1000000009, r => 378633312 },

        { n => _bi('881398088036'), p => _bi('1000000000039'), r => _bi('791399408049') },
        { n => _bi('41660815127637347468140745042827704103445750172002'), p => _bi('100000000000000000000000000000000000000000000000577'), r => _bi('32102985369940620849741983987300038903725266634508') },
    );
}

sub test_tonelli_shanks : Tests(9) {
    my ($self) = @_;

    #cf. libtomcrypt demo/demo.c
    my @tests = $self->_TONELLI_SHANKS_TESTS();

    for my $t (@tests) {
        is(
            Crypt::Perl::ECDSA::Math::tonelli_shanks( @{$t}{ qw( n p ) } ),
            $t->{'r'},
            "N=$t->{'n'}, P=$t->{'p'}",
        );
    }

    return;
}

sub _JACOBI_TESTS {
    return (
        #From: https://en.wikipedia.org/wiki/Legendre_symbol
        [ 0, 3 => 0 ],
        [ 1, 3 => 1 ],
        [ 2, 3 => -1 ],
        [ 0, 5 => 0 ],
        [ 1, 5 => 1 ],
        [ 2, 5 => -1 ],
        [ 3, 5 => -1 ],
        [ 4, 5 => 1 ],
        [ 0, 7 => 0 ],
        [ 1, 7 => 1 ],
        [ 2, 7 => 1 ],
        [ 3, 7 => -1 ],
        [ 4, 7 => 1 ],
        [ 5, 7 => -1 ],
        [ 6, 7 => -1 ],
        [ 0, 11 => 0 ],
        [ 1, 11 => 1 ],
        [ 2, 11 => -1 ],
        [ 3, 11 => 1 ],
        [ 4, 11 => 1 ],
        [ 5, 11 => 1 ],
        [ 6, 11 => -1 ],
        [ 7, 11 => -1 ],
        [ 8, 11 => -1 ],
        [ 9, 11 => 1 ],
        [ 10, 11 => -1 ],

        #Just random others
        [ 23, 478 => 1 ],
        [123123, 23423400 => 0],
        [470, 12071, => 1],
        [193136, 278103 => -1 ],
        [47000, 123123 => 1 ],
        [73564, 98741 => 1 ],
    );
}

sub test_jacobi : Tests() {
    my ($self) = @_;

    my @t = $self->_JACOBI_TESTS();

    #is( _count_lsb(8), 3, 'count LSB' );
    #is( _count_lsb(3072), 10, 'count LSB 3072' );

    for my $tt (@t) {
        my $ret = Crypt::Perl::ECDSA::Math::jacobi( map { Crypt::Perl::BigInt->new($_) } @{$tt}[0, 1] );
        is( $ret, $tt->[2], "@{$tt}[0,1] => $tt->[2]" );
        is( ref($ret), q<>, '… and it’s not a reference' );
    }

    return;
}

sub _bi { return Crypt::Perl::BigInt->new(@_) }
