use strict;
use warnings;

use Test::More tests => 2;

# ABSTRACT: test module_rel_path

use Asset::Pack;

*module_rel_path = \&Asset::Pack::_module_rel_path;

my %names = (
  'Foo'            => 'Foo.pm',
  'Foo::Bar::B123' => 'Foo/Bar/B123.pm',
);
foreach my $k ( keys %names ) {
  is( module_rel_path($k), $names{$k}, "$k resolves to where it should" );
}
