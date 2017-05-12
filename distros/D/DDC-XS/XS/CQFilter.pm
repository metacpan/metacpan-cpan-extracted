##-*- Mode: CPerl -*-

##======================================================================
package DDC::XS::CQFilter;
use strict;

package DDC::XS::CQFSort;
*setMin = __PACKAGE__->can('setArg1');
*setMax = __PACKAGE__->can('setArg2');
*setField = __PACKAGE__->can('setArg0');
*setValue = __PACKAGE__->can('setArg1');
sub setFilterType { $_[0]->setType($DDC::XS::HitSortEnum{$_[1]}); }

package DDC::XS::CQFRandomSort;
*setSeed = __PACKAGE__->can('setArg1');

1; ##-- be happy
