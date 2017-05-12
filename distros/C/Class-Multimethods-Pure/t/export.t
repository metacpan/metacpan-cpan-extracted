package NumberOne;

use Test::More tests => 10;

use Class::Multimethods::Pure;

ok(exists(&multi), "multi default");
ok(exists(&all),   "All default");
ok(exists(&any),   "Any default");
ok(exists(&none),  "None default");

package NumberTwo;

use Test::More;

use Class::Multimethods::Pure import => qw<multi none>;

ok(exists(&multi), "multi explicit");
ok(!exists(&all),  "All explicit");
ok(!exists(&any),  "Any explicit");
ok(exists(&none),  "None explicit");

package NumberThree;

use Test::More;

use Class::Multimethods::Pure multi => 
        foo => qw<ARRAY> => sub { "Calloh Callay" };

ok(!exists(&multi), "no exports on use-time multi");
is(foo([]), "Calloh Callay", "Actually defines the multi");
