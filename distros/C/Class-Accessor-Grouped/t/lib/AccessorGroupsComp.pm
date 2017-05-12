package AccessorGroupsComp;
use strict;
use warnings;
use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors('component_class', 'result_class');

sub new {
  return bless {}, shift;
};

1;
