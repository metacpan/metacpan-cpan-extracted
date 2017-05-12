package ExtraInheritedGroups;
use strict;
use warnings;
use base 'AccessorInstaller';

__PACKAGE__->mk_inherited_accessors('basefield');
__PACKAGE__->basefield('your extra base!');

1;
