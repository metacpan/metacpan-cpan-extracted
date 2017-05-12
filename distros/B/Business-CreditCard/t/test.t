
use Test::More tests => 1;
use Business::CreditCard;

ok( test_card_identification() );

sub test_card_identification {
        # 
        # For the curious the table of test number aren't real credit card
        # in fact they won't validate but they do obey the rule for the
        # cardtype table to identify the card type.
        #
        my %test_table=(
                '5212345678901234' =>   'MasterCard',
                '5512345678901234' =>   'MasterCard',
                '2512345678901234' => 'MasterCard',
                '4123456789012' =>      'VISA card',
                '4929492492497' =>      'VISA card',
                '4512345678901234' =>   'VISA card',
                '341234567890123' =>    'American Express card',
                '371234567890123' =>    'American Express card',
                #'36123456789012' =>     "Diner's Club/Carte Blanche",
                #'36123456789012' =>     'MasterCard',
                '36123456789012' =>     'Discover card',
                '201412345678901' =>    'enRoute',
                '214912345678901' =>    'enRoute',
                '6011123456789012' =>   'Discover card',
                '3123456789012345' =>   'JCB',
                '213112345678901' =>    'JCB',
                '180012345678901' =>    'JCB',
                '1800123456789012' =>   'Unknown',
                '312345678901234' =>    'Unknown',
                '4111xxxxxxxxxxxx' =>   'VISA card',
                '6599xxxxxxxxxxxx' =>   'Discover card',
                '6222xxxxxxxxxxxx' =>   'Discover card', #China Union Pay
                '6304980000000000004' => 'Laser',
                '6499xxxxxxxxxxxx' =>   'Discover card',
                '5610xxxxxxxxxxxx' =>   'BankCard',
                '6250xxxxxxxxxxxx' =>   'Discover card', #China Union Pay
                '6280xxxxxxxxxxxx' =>   'Discover card', #China Union Pay
                '12345678'  => 'Isracard',
                '123456780' => 'Isracard',
                '60xx xxxx xxxx xxxx' => 'Discover card', #discover w/2 digits
        );
        while( my ($k, $v)=each(%test_table) ){
                if(cardtype($k) ne $v){
                        warn "Card $k - should be $v but cardtype returns ". cardtype($k). "\n";
                        return;
                }
        }
        return 1;
}

