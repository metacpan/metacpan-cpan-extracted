use Test::More;
use strict;
use warnings;

BEGIN {
  plan skip_all => "Package::Stash required for this test"
    unless eval { require Package::Stash };

  require MRO::Compat if $] < 5.009_005;
}

{
  package AccessorGroups::Clean;
  use strict;
  use warnings;
  use base 'Class::Accessor::Grouped';

  my $obj = bless {};
  for (qw/simple inherited component_class/) {
    __PACKAGE__->mk_group_accessors($_ => "${_}_a");
    $obj->${\ "${_}_a"} ('blah');
  }
}

is_deeply
[ sort keys %{ { map
  { %{Package::Stash->new($_)->get_all_symbols('CODE')} }
  (reverse @{mro::get_linear_isa('AccessorGroups::Clean')})
} } ],
[ sort +(
  (map { ( "$_", "_${_}_accessor" ) } qw/simple_a inherited_a component_class_a/ ),
  (map { ( "get_$_", "set_$_" ) } qw/simple inherited component_class/ ),
  qw/
    _mk_group_accessors
    get_super_paths
    make_group_accessor
    make_group_ro_accessor
    make_group_wo_accessor
    mk_group_accessors
    mk_group_ro_accessors
    mk_group_wo_accessors
    CLONE
  /,
)],
'Expected list of methods in a freshly inheriting class';

done_testing;
