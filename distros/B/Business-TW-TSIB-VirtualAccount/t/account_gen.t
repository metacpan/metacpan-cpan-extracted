#!/usr/bin/perl -T
use Test::More tests => 2;

BEGIN {
	use_ok( 'Business::TW::TSIB::VirtualAccount' );
}

diag( "Testing Business::TW::TSIB::VirtualAccount $Business::TW::TSIB::VirtualAccount::VERSION, Perl $], $^X" );

use DateTime;
my $va = Business::TW::TSIB::VirtualAccount->new(
    { corp_code => '95678' } );

my $acc = $va->generate(
    {   due    => DateTime->new( year => 2007, month => 4, day => 2 ),
        amount => 3900,
        ar_id  => '2089'
    }
);

# total 14 columns
is( $acc , '95678609220898' );

