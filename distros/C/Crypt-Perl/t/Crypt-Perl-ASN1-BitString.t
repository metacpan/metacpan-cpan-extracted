package t::Crypt::Perl::X509v3;

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

use File::Temp;

use lib "$FindBin::Bin/lib";

use OpenSSL_Control ();

use parent qw(
    Test::Class
    NeedsOpenSSL
);

use Crypt::Perl::ASN1::BitString ();

__PACKAGE__->new()->runtests() if !caller;

#----------------------------------------------------------------------

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new();

    $self->num_method_tests( 'test_creation', 0 + @{ [ _creation_tests() ] } );

    return $self;
}

sub _creation_tests {
    return (
        [ [ qw( a ) ] => "\x80\0" ],
        [ [ qw( j a ) ] => "\x80\x40" ],
        [ [ qw( j i a ) ] => "\x80\xc0" ],
        [ [ qw( h j i a ) ] => "\x81\xc0" ],
    );
}

sub _FIELD {
    return 'a' .. 'j';
}

sub test_unknown_flags : Tests(1) {
    my @field = _FIELD();

    throws_ok(
        sub {
            Crypt::Perl::ASN1::BitString::encode(
                \@field,
                [ 'j', 'a', 'c', 'z', 'd', 'x' ],
            );
        },
        qr< z .+ x | x .+ z >x,
        'unknown flags are thrown',
    );

    return;
}

sub test_creation : Tests() {
    my @field = _FIELD();

    my @tt = _creation_tests();

    for my $t (@tt) {
        my $val = Crypt::Perl::ASN1::BitString::encode(
            \@field,
            $t->[0],
        );

        is(
            sprintf( '%v.02x', $val ),
            sprintf( '%v.02x', $t->[1] ),
            "flags: @{$t->[0]}",
        );
    }

    return;
}

1;
