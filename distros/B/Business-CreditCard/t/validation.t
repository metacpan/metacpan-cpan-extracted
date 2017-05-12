
use Test::More tests => 1;
use Business::CreditCard;

ok( test_card_validation() );

sub test_card_validation {
        my %test_table=(
                '10830529'  => 'Isracard',
                '010830529' => 'Isracard',
        );
        while( my ($k, $v)=each(%test_table) ){
                if(!validate($k)){
                        warn "Card $k - should be a valid $v but validation failed\n";
                        return;
                }
        }
        return 1;
}

