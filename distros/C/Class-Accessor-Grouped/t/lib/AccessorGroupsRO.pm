package AccessorGroupsRO;
use strict;
use warnings;
use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_ro_accessors('simple', 'singlefield');
__PACKAGE__->mk_group_ro_accessors('multiple', qw/multiple1 multiple2/);
__PACKAGE__->mk_group_ro_accessors('listref', [qw/lr1name lr1;field/], [qw/lr2name lr2'field/]);
__PACKAGE__->mk_group_ro_accessors('simple', [ fieldname_torture => join ('', map { chr($_) } (0..255) ) ]);

sub new {
  return bless {}, shift;
};

foreach (qw/multiple listref/) {
  no strict 'refs';
  *{"get_$_"} = __PACKAGE__->can ('get_simple');
};

1;
