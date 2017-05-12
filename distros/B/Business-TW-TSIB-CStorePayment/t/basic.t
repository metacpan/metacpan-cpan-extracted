use Test::More tests => 3;
use DateTime;
use_ok('Business::TW::TSIB::CStorePayment');

is(Business::TW::TSIB::CStorePayment->_compute_checksum('991231Y01', 'ABCDEFGHIKLMNPQR', '123400000007890'), '9Y');

my $csp = Business::TW::TSIB::CStorePayment->new({ corp_code => 'AIIN' });
my @bar = $csp->generate( { due    => DateTime->new( year => 2007, month => 4, day => 2 ),
                           amount => 3900,
                           ar_id  => '20892' } );
is_deeply( \@bar,
           [qw(960402627 AIIN000000020892 040265000003900)] );

