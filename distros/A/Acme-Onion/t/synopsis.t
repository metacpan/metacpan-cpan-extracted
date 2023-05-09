use strict;
use warnings;

use FindBin;

BEGIN {
    system "mv $FindBin::Bin/../examples/lib/Hello.pm $FindBin::Bin/../examples/lib/Hello.🧅";
}

use Test::More;

use lib 'examples/lib';

use Acme::Onion;
use Hello;

ok +Hello->onion;

system "mv $FindBin::Bin/../examples/lib/Hello.🧅 $FindBin::Bin/../examples/lib/Hello.pm";

done_testing;
