package ExtraInheritedGroups;
use strict;
use warnings;
use parent 'AccessorInstaller';

__PACKAGE__->mk_inherited_accessors('basefield');
__PACKAGE__->basefield('your extra base!');

1;
