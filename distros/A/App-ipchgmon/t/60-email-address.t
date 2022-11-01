use strict;
use warnings;
use Test::More;
use FindBin qw( $RealBin );

my $NAME = 'ipchgmon';
my $invoke = "$^X $RealBin/../bin/$NAME";

# This validates the handling of email addresses. Data::Validate::Email is
# used to do the real work, but the modulino should accept multiple email
# addresses and complain if any one of them is wrongly formatted.

my $rtn = qx($invoke --debug --email foo\@bar 2>&1);
like $rtn, qr/Invalid email/m, 'Reject if single email address malformed';

$rtn = qx($invoke --debug --email invalid\@example.com 2>&1);
unlike $rtn, qr/Invalid email/m, 'Well-formed email address accepted';

$rtn = qx($invoke --debug --email invalid\@example.com --email foo\@bar 2>&1);
like $rtn, qr/Invalid email/m, 'Rejected if second email address invalid';

$rtn = qx($invoke --debug --email foo\@bar --email invalid\@example.com 2>&1);
like $rtn, qr/Invalid email/m, 'Rejected if first email address (of two) invalid';

done_testing();