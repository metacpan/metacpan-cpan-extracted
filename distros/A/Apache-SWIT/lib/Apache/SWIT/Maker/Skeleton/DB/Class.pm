use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::DB::Class;
use base 'Apache::SWIT::Maker::Skeleton::Class';
use Apache::SWIT::Maker::Config;
use Apache::SWIT::Maker::Conversions;

__PACKAGE__->mk_accessors('table');

sub table_v { return shift()->table; }
sub class_v {
	return Apache::SWIT::Maker::Config->instance->root_class
		. "::DB::" . conv_table_to_class(shift()->table);
}

sub template { return <<'ENDS' };
use strict;
use warnings FATAL => 'all';

package [% class_v %];
use base 'Apache::SWIT::DB::Base';

__PACKAGE__->set_up_table('[% table_v %]', { ColumnGroup => 'Essential' });

1;
ENDS

1;
