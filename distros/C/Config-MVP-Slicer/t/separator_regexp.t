use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Config::MVP::Slicer';
eval "require $mod" or die $@;

my $regexp = new_ok($mod)->separator_regexp;

is_deeply
  ['goober' =~ $regexp],
  [],
  'not matched';

is_deeply
  [  'Class::Name.attr' =~ $regexp],
  [qw(Class::Name attr), undef],
  'simple name.attr match';

is_deeply
  [  'Class::Name.attr[]' =~ $regexp],
  [qw(Class::Name attr), '[]'],
  'simple match with empty brackets';

is_deeply
  [  'Class::Name.attr[hooey]' =~ $regexp],
  [qw(Class::Name attr), '[hooey]'],
  'simple match with subscript';

is_deeply
  [  'Class::Name.attr.ibute' =~ $regexp],
  [qw(Class::Name attr.ibute), undef],
  'attribute with dot';

is_deeply
  [  'Class::Name.-attr' =~ $regexp],
  [qw(Class::Name -attr), undef],
  'attribute with leading dash';

is_deeply
  [  'Class::Name.-attr[1]' =~ $regexp],
  [qw(Class::Name -attr), '[1]'],
  'attribute with leading dash and brackets';

is_deeply
  [  '-Class::Name.attr' =~ $regexp],
  [qw(-Class::Name attr), undef],
  'plugin class has string prefix';

$regexp = new_ok($mod, [{prefix => 'slice.'}])->separator_regexp;

is_deeply
  [  'slice.Class::Name.attr.ibute' =~ $regexp],
  [qw(Class::Name attr.ibute), undef],
  'prefix has a dot';

is_deeply
  [  'sliceXClass::Name.attr.ibute' =~ $regexp],
  [qw(Class::Name attr.ibute), undef],
  'prefix is a regexp';

is_deeply
  [  'sliceX-Class::Name.attr.ibute' =~ $regexp],
  [qw(-Class::Name attr.ibute), undef],
  'regexp prefix followed by class name with string prefix';

$regexp = new_ok($mod, [{separator => '(.+?)\W+(\w+)'}])->separator_regexp;

is_deeply
  [  'Class::Name->attr' =~ $regexp],
  [qw(Class::Name attr), undef],
  'alternate separator';

$regexp = new_ok($mod, [{prefix => qr/foo./, separator => '(.+?)\W+(\w+)'}])->separator_regexp;

is_deeply
  [  'foo:Class::Name->attr' =~ $regexp],
  [qw(Class::Name attr), undef],
  'alternate separator and prefix';

done_testing;
