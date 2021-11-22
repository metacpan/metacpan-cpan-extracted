package t::Crypt::Perl::ECDSA::PublicKey;

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
use Test::FailWarnings;
use Test::Deep;
use Test::Exception;

use lib "$FindBin::Bin/lib";

use parent qw(
    TestClass
);

use Math::BigInt ();

use Crypt::Perl::Math ();

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

#sub test_create_random_bit_length : Tests(745) {
#    my ($self) = @_;
#
#    for ( 24 .. 768 ) {
#        my $num = Crypt::Perl::Math::create_random_bit_length($_);
#        is(
#            $num->bit_length(),
#            $_,
#            "$_-bit random number created correctly: " . $num->as_hex(),
#        );
#    }
#
#    return;
#}

sub test_randint : Tests(30) {
    for my $lim ( 234, 0x111fffff, Math::BigInt->from_hex('1111ffffffffffff') ) {
        for ( 1 .. 10 ) {
            my $randint = Crypt::Perl::Math::randint($lim);
            cmp_ok( $randint, '<=', $lim, "$randint <= $lim (test $_)" );
        }
    }
}

sub test_ceil : Tests(10) {
    my ($self) = @_;

    for ( map { $_ / 10 } 11 .. 20 ) {
        is(
            Crypt::Perl::Math::ceil($_),
            2,
            "ceil($_)",
        );
    }

    return;
}
