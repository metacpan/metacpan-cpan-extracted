use strict;
use warnings;

use Test::More;
use Crypt::Rijndael::MySQL;

my @tests;

BEGIN {
    @tests = (
        {
            name        => 'ordinary',
            key         => 'A' x 16,
            plain       => 'A' x 16,
            encrypted   => 'f8cba1aa5b5120b4f2fdda1b26ca01580515be1d9afb4c54a20390973f5828d8',
        },
        {
            name        => 'uneven padding',
            key         => 'A' x 16,
            plain       => 'A' x 20,
            encrypted   => 'f8cba1aa5b5120b4f2fdda1b26ca01585c0c2cc2f8fe835c0bf60571a598ce81',
        },
        {
            name        => 'short key',
            key         => 'A' x 12,
            plain       => 'A' x 20,
            encrypted   => 'a5bfa6efd51c3702892af89730627c8a3359bf104d1209cea06da2154ec64df8',
        },
        {
            name        => 'long key',
            key         => 'A 0' x 8,
            plain       => 'A' x 20,
            encrypted   => '68f4418cb81079ba4b329d55fe65829fed304e4b1c68d160a99177f3a7c30da2',
        },
    );

    plan tests => @tests * 3 + 1;

    use_ok('Crypt::Rijndael::MySQL');
}

foreach my $test (@tests) {
    my ($name, $plain, $encrypted) = @$test{ qw/name plain encrypted/ };
    $encrypted = pack('H*', $encrypted);

    my $cipher = eval { Crypt::Rijndael::MySQL->new( $test->{key} ) };
    diag $@ if $@;
    ok( eval { $cipher->isa('Crypt::Rijndael::MySQL') }, "$name - new cipher" );
    diag $@ if $@;
    
    is(eval { $cipher->encrypt( $plain ) }, $encrypted, "$name - encrypt");
    diag $@ if $@;

    is(eval { $cipher->decrypt( $encrypted ) }, $plain, "$name - decrypt");
    diag $@ if $@;
}
