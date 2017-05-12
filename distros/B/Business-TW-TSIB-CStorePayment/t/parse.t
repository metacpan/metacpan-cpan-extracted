use Test::More tests => 19;
use DateTime;
use_ok('Business::TW::TSIB::CStorePayment');

is(Business::TW::TSIB::CStorePayment->_compute_checksum('991231Y01', 'ABCDEFGHIKLMNPQR', '123400000007890'), '9Y');

my $csp = Business::TW::TSIB::CStorePayment->new({ corp_code => 'AIIN' });
my @bar = $csp->generate( { due    => DateTime->new( year => 2007, month => 4, day => 2 ),
                           amount => 3900,
                           ar_id  => '20892' } );
is_deeply( \@bar,
           [qw(960402627 AIIN000000020892 040265000003900)] );


# debit date (8)  
# paid date (8)  
# payment id (16)  
# amount (9) 
# due (4)  
# collection agent (8)  
# payee account (14) 
my $content =<<EOF;
2007110520071104AIIN0000000000900000005201101TFM     20760100002047
2007110520071104AIIN00000000009100000378011017111111 20760100002047
2007110520071105AIIN0000000001130000001301101TFM     20760100002047
2007110520071105AIIN00000000012200000001111017111111 20760100002047
2007110520071105AIIN0000000001240000001421101TFM     20760100002047
EOF

open my $fh , '<' , \$content or die $!;
my $entries = Business::TW::TSIB::CStorePayment->parse_summary( $fh );

is( $entries->[0]->debit_date,       '20071105' );
is( $entries->[0]->paid_date,        '20071104' );
is( $entries->[0]->payment_id,       'AIIN000000000090' );
is( $entries->[0]->amount,           520 );
is( $entries->[0]->due,              '1101' );
is( $entries->[0]->collection_agent, 'TFM' );
is( $entries->[0]->payee_account,    '20760100002047' );
is( $entries->[0]->ar_id, 90 );

is( $entries->[1]->debit_date,       '20071105' );
is( $entries->[1]->paid_date,        '20071104' );
is( $entries->[1]->payment_id,       'AIIN000000000091' );
is( $entries->[1]->amount,           3780 );
is( $entries->[1]->due,              '1101' );
is( $entries->[1]->collection_agent, '7111111' );
is( $entries->[1]->payee_account,    '20760100002047' );
is( $entries->[1]->ar_id, 91 );



