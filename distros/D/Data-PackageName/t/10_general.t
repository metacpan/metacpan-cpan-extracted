#!/usr/bin/perl
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::More tests => 21;

# compilation
use_ok 'Data::PackageName';

# creation
my $foo = Data::PackageName->new(package => 'Foo');
isa_ok $foo, 'Data::PackageName';

# append
my $foo_bar_baz = $foo->append(qw( Bar Baz ));
isa_ok  $foo_bar_baz,           'Data::PackageName';
is      $foo_bar_baz->package,  'Foo::Bar::Baz',    '->append result contains correct package name';
is      "$foo_bar_baz",         'Foo::Bar::Baz',    'stringification to package name works';

# prepend
my $qu_ux_foo = $foo->prepend(qw( Qu Ux ));
isa_ok      $qu_ux_foo,             'Data::PackageName';
is          $qu_ux_foo->package,    'Qu::Ux::Foo',      '->prepend result contains correct package name';

# parts
is_deeply   [ $qu_ux_foo->parts ],      [qw( Qu Ux Foo )],      'object returns correct parts';
my $foo_barbaz = $foo->append('BarBaz');
is_deeply   [ $foo_barbaz->parts_lc ],  [qw( foo bar_baz )],    'object returns correct lowercase parts';

# filename/dirname
my $foo_barbaz_path = $foo_barbaz->filename_lc('.html');
isa_ok  $foo_barbaz_path,   'Path::Class::File';
is      "$foo_barbaz_path", 'foo/bar_baz.html',     'correct lowercase filename returned';
my $foo_barbaz_dir = $foo_barbaz->dirname;
isa_ok  $foo_barbaz_dir,    'Path::Class::Dir';
is      "$foo_barbaz_dir",  'foo/bar_baz',          'correct dirname returned';

# after_start
my $barbaz = $foo_barbaz->after_start('Foo');
isa_ok  $barbaz,    'Data::PackageName';
is      "$barbaz",  'BarBaz',               'after_start returned correct tail';

# package_filename
my $foo_barbaz_packagefile = $foo_barbaz->package_filename;
isa_ok  $foo_barbaz_packagefile,    'Path::Class::File';
is      "$foo_barbaz_packagefile",  'Foo/BarBaz.pm',        'correct package filename returned';

# loading
my $foo_test = Data::PackageName->new(package => 'Foo::Test');
ok     !$foo_test->is_loaded,       'test package not yet loaded';
ok      $foo_test->require,         'package loaded successfully';
ok      $foo_test->is_loaded,       'package is loaded now';
ok     !$foo_test->require,         'second require returns false';

