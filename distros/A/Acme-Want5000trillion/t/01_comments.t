use strict;
use warnings;

use Acme::Want5000trillion;

use Test::More;

subtest 'lines' => sub{
    subtest 'ja' => sub{
        my $want = Acme::Want5000trillion->new;
        is $want->say(),  "5000兆円欲しい！";
    };

    subtest 'en' => sub{
        my $want = Acme::Want5000trillion->new;
        is $want->say('en'),  "I want 5000 trillion yen!";
    };

    subtest 'th' => sub{
        my $want = Acme::Want5000trillion->new;
        is $want->say('th'),  "ฉันต้องการ 5000000000000000 เยน!";
    };

    subtest 'cn' => sub{
        my $want = Acme::Want5000trillion->new;
        is $want->say('cn'), "我想五千万亿日元!";
    };

    subtest 'it' => sub{
        my $want = Acme::Want5000trillion->new;
        is $want->say('it'), "Voglio 5000 trilioni di yen!";
    };
};

done_testing;
