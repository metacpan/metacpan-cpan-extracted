# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 2 };

use Auth::Krb5Afs;
ok(1); # If we made it this far, we're ok.

#########################

# printf 'imap\nlogin\ntest_user\ntest_pass\n' | 
# KRB5CCNAME=/tmp/t$RANDOM.krb5cc authkrb5afs klist 3<&1

$ENV{PERL5LIB} = join(":", @INC);
use IPC::Open2;

open2(\*R, \*W, "./authkrb5afs id 2>&1");
print(W "imap\nlogin\ntest_user\ntest_pass\n");
close(W);
read(R, $s, 4096);
ok( $s =~ /no such user/ );
