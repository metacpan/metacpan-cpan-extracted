package BaseInheritedGroups;
use strict;
use warnings;
use parent 'AccessorInstaller';

__PACKAGE__->mk_inherited_accessors('basefield', 'undefined', ['refacc','reffield']);

sub new {
    return bless {}, shift;
};

1;
