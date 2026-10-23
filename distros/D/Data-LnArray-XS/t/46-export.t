use strict;
use warnings;
use Test::More;

{
	package T::None;
	use Data::LnArray::XS;
}
ok(!T::None->can('arr'), 'nothing by default');

{
	package T::Name;
	use Data::LnArray::XS qw/arr/;
}
ok(T::Name->can('arr'), 'by name');

{
	package T::Bare;
	use Data::LnArray::XS qw/all/;
}
ok(T::Bare->can('arr'), 'bare tag');

{
	package T::Colon;
	use Data::LnArray::XS qw/:all/;
}
ok(T::Colon->can('arr'), 'colon tag');

is_deeply([T::Bare::arr(1, 2)->retrieve], [1, 2], 'imported arr works');

ok(!eval "package T::Bad; use Data::LnArray::XS qw/nope/; 1", 'unknown name dies');
like($@, qr/"nope" is not exported by the Data::LnArray::XS module/, 'unknown name message');

ok(!eval "package T::Ver; use Data::LnArray::XS 99; 1", 'version check dies');
like($@, qr/Data::LnArray::XS version 99 required/, 'version check message');

done_testing();
