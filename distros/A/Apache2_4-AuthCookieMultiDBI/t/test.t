

# use Test;
# BEGIN { plan tests => 1 };
# use Finance::Currency::Convert::ECBdaily;
# ok(1); # If we made it this far, we're ok.

# warn "# Don't want to go online to test\n# so try something like\n";
# warn '# $Finance::Currency::Convert::ECBdaily::CHAT=1;'."\n";
# warn '# print Finance::Currency::Convert::ECBdaily::convert(1,\'EUR\',\'GBP\');'."\n";


# # $Finance::Currency::Convert::ECBdaily::CHAT=1;
# # print Finance::Currency::Convert::ECBdaily::convert(10,'GBP','HUF');

# exit;

use strict;
use warnings;
 
use Test::More tests => 1;
 
use_ok 'Apache2_4::AuthCookieMultiDBI';
