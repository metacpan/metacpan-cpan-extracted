use strict;
use utf8;
use Test::More tests => 2;

use Coro;
use Acme::Coro::Suke;
use IO::Scalar;

my $str = '';
my $fh = IO::Scalar->new(\$str);

{
    local *STDOUT = $fh;

    benzo {
        print "hoge1\n";
        cede;
        print "hoge2\n";
    };

    async {
        print "huga1\n";
        cede;
        print "huga2\n";
    };

    cede;
    is $str => $Acme::Coro::Suke::SERIF . "hoge1\nhuga1\n";
    $str = '';
    cede;
    is $str => $Acme::Coro::Suke::SERIF . "hoge2\nhuga2\n";
}

