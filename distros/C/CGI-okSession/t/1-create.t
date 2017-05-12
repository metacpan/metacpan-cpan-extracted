# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 7;
BEGIN {
	use_ok(CGI::okSession);
}
ok($Session = new CGI::okSession(dir=>'tmp',timeout=>30));
$t = [1,2,3,4,5];
%h = (one=>1,two=>2,three=>3);
open OUT, "> tmp/ID";
print OUT $Session->get_ID,"\n";
close OUT;
ok($Session->{test} = $t);
ok($Session->{hash} = \%h);
ok($Session->{scal} = 'test');
ok($Session->{client}->{email} = 'some@email.com');
ok($Session->{client}->{name} = 'some@email.com');

undef $Session;