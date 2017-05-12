use strict;
use warnings;

use Test::More;
use B qw/svref_2object/;

use_ok('Class::Accessor::Grouped');

# ensure core accessor types are properly named
#
for (qw/simple inherited component_class/) {
  for my $meth ("get_$_", "set_$_") {
    my $cv = svref_2object( Class::Accessor::Grouped->can($meth) );
    is($cv->GV->NAME, $meth, "$meth accessor is named");
    is($cv->GV->STASH->NAME, 'Class::Accessor::Grouped', "$meth class correct");
  }
}

done_testing;
