use strict;
use warnings;
use Test::More;

{
	package T::None;
	use Bijection::XS;
}
ok(!T::None->can('biject'), 'nothing by default');

{
	package T::Names;
	use Bijection::XS qw/biject inverse/;
}
ok(T::Names->can('biject') && T::Names->can('inverse'), 'names');
ok(!T::Names->can('offset_set'), 'only the names asked for');

{
	package T::Bare;
	use Bijection::XS qw/set/;
}
ok(T::Bare->can('bijection_set') && T::Bare->can('offset_set'), 'bare tag');
ok(!T::Bare->can('biject'), 'bare tag brings only its names');

{
	package T::Colon;
	use Bijection::XS qw/:main/;
}
ok(T::Colon->can('biject') && T::Colon->can('inverse'), 'colon tag');
ok(!T::Colon->can('bijection_set'), 'colon tag brings only its names');

{
	package T::All;
	use Bijection::XS qw/all !offset_set/;
}
ok(T::All->can('biject') && T::All->can('bijection_set'), 'all');
ok(!T::All->can('offset_set'), 'negation after a bare tag');

is(T::Names::inverse(T::Names::biject(42)), 42, 'imported subs work');

ok(!eval "package T::Bad; use Bijection::XS qw/nope/; 1", 'unknown name dies');
like($@, qr/"nope" is not exported by the Bijection::XS module/, 'unknown name message');

ok(!eval "package T::Ver; use Bijection::XS 99; 1", 'version check dies');
like($@, qr/Bijection::XS version 99 required/, 'version check message');

done_testing();
