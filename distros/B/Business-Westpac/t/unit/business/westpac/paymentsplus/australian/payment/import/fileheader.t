#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::FileHeader';

use_ok( $class );

my %attr = (
    customer_code => 'TESTPAYER',
    customer_name => 'TESTPAYER NAME',
    customer_file_reference => 'TESTFILE001',
    scheduled_date => '26082016',
);

isa_ok(
    my $FileHeader = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $FileHeader->to_csv ],
    [ @expected ],
    '->to_csv'
);

subtest 'string type constraints' => sub {

    throws_ok(
        sub { $class->new( %attr, customer_code => 'longer than 10 chars' ) },
        qr/The string provided for customer_code was outside 1\.\.10 chars/,
    );
};

done_testing();

__DATA__
"H","TESTPAYER","TESTPAYER NAME","TESTFILE001","26082016","AUD","6"
