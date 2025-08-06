#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Trailer';

use_ok( $class );

my %attr = (
    total_payment_count => 8,
    total_payment_amount => '2015.42',
);

isa_ok(
    my $Trailer = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $Trailer->to_csv ],
    [ @expected ],
    '->to_csv'
);

done_testing();

__DATA__
"T","8","2015.42"
