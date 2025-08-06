#!/opt/tools/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;

my $class = 'Business::Westpac::PaymentsPlus::Australian::Payment::Import::Remittance';

use_ok( $class );

my %attr = (
    remittance_delivery_type => 'EMAIL',
    payee_name => 'Payee 01',
    addressee_name => 'Addressee 01',
    street_1 => 'Level 1',
    street_2 => 'Wallsend Plaza',
    city => 'Wallsend',
    state => 'NSW',
    post_code => '2287',
    country => 'AU',
    email => 'test@test.com',
    remittance_layout_code => 1,
    return_to_address_identifier => 1,
    pass_through_data => "Some pass through data",
);

isa_ok(
    my $RemittanceHeader = $class->new( %attr ),
    $class
);

chomp( my @expected = <DATA> );
cmp_deeply(
    [ $RemittanceHeader->to_csv ],
    [ @expected ],
    '->to_csv'
);

subtest 'enum type constraints' => sub {

    throws_ok(
        sub { $class->new( %attr, remittance_delivery_type => 'WRONG' ) },
        qr/Value "WRONG" did not pass/,
    );
};

subtest 'int type constraints' => sub {

    throws_ok(
        sub { $class->new( %attr, remittance_layout_code => $_ ) },
        qr/was not positive/,
    ) for ( 0, -1 );
};

subtest '->remittance_delivery_type requirements' => sub {

    throws_ok(
        sub { $class->new( payee_name => 'foo', remittance_delivery_type => $_ ) },
        qr/street_1 is required when/,
        "$_ requires street_1",
    ) for qw/ POST POST_OS POST_MULTI /;

    throws_ok(
        sub { $class->new(
            payee_name => 'foo',
            street_1 => 'foo',
            remittance_delivery_type => $_
        ) },
        qr/city is required when/,
        "$_ requires city",
    ) for qw/ POST POST_OS POST_MULTI /;

    throws_ok(
        sub { $class->new(
            payee_name => 'foo',
            street_1 => 'foo', city => 'bar',
            remittance_delivery_type => $_
        ) },
        qr/state is required when/,
        "$_ requires state",
    ) for qw/ POST POST_MULTI /;

    throws_ok(
        sub { $class->new(
            payee_name => 'foo',
            street_1 => 'foo', city => 'bar', state => 'NSW',
            remittance_delivery_type => $_
        ) },
        qr/post_code is required when/,
        "$_ requires post_code",
    ) for qw/ POST POST_MULTI /;

    throws_ok(
        sub { $class->new(
            payee_name => 'foo',
            remittance_delivery_type => 'FAX',
        ) },
        qr/fax is required when/,
        "FAX requires fax",
    );

    throws_ok(
        sub { $class->new(
            payee_name => 'foo',
            remittance_delivery_type => 'EMAIL',
        ) },
        qr/email is required when/,
        "EMAIL requires email",
    );
};

done_testing();

__DATA__
"R","EMAIL","Payee 01","Addressee 01","Level 1","Wallsend Plaza",,"Wallsend","NSW","2287","AU",,"test@test.com","1","1"
"RP","Some pass through data"
