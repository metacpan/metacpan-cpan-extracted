#!perl
use lib 'lib';
use blib;

use Test2::V0 -target => 'Archive::SCS::DirIndex';

# DirIndex constructor, accessors

my $index = CLASS->new( dirs => ['foo'], files => ['bar'] );
is [$index->dirs],  ['foo'], 'index dirs';
is [$index->files], ['bar'], 'index files';

is [CLASS->new()->dirs],  [], 'index empty dirs';
is [CLASS->new()->files], [], 'index empty files';

# Auto index

my $list = CLASS->auto_index([qw(
  aa/xx/y1
  aa/xx/y2
  zz
)], [qw(
  aa
  bb/cc/d1
  bb/cc/d2
)]);

is [sort keys $list->%*], ['', qw(
  aa  aa/xx
  bb  bb/cc  bb/cc/d1  bb/cc/d2
)], 'auto new';

is [$list->{''}->dirs],          ['aa', 'bb'], 'auto root dirs';
is [$list->{''}->files],         ['zz'],       'auto root files';
is [$list->{'aa'}->dirs],        ['xx'],       'auto aa dirs';
is [$list->{'aa'}->files],       [],           'auto aa files';

# files without explicit parent dir
is [$list->{'aa/xx'}->dirs],     [],           'auto aa/xx dirs';
is [$list->{'aa/xx'}->files],    ['y1', 'y2'], 'auto aa/xx files';

# subdirs without explicit parent dir and without files
is [$list->{'bb'}->dirs],        ['cc'],       'auto bb dirs';
is [$list->{'bb'}->files],       [],           'auto bb files';
is [$list->{'bb/cc'}->dirs],     ['d1', 'd2'], 'auto bb/cc dirs';
is [$list->{'bb/cc'}->files],    [],           'auto bb/cc files';

# empty subdirs
is [$list->{'bb/cc/d1'}->dirs],  [],           'auto bb/cc/d1 dirs';
is [$list->{'bb/cc/d1'}->files], [],           'auto bb/cc/d1 files';
is [$list->{'bb/cc/d2'}->dirs],  [],           'auto bb/cc/d2 dirs';
is [$list->{'bb/cc/d2'}->files], [],           'auto bb/cc/d2 files';

# Auto index, dirs are optional

my $list_f = CLASS->auto_index(['ee', 'ff/gg']);

is [sort keys $list_f->%*],      ['', 'ff'],   'auto no dirs new';
is [$list_f->{''}->dirs],        ['ff'],       'auto no dirs root dirs';
is [$list_f->{''}->files],       ['ee'],       'auto no dirs root files';
is [$list_f->{'ff'}->dirs],      [],           'auto no dirs ff dirs';
is [$list_f->{'ff'}->files],     ['gg'],       'auto no dirs ff files';

# Auto index, no files

my $list_d = CLASS->auto_index([], ['hh']);

is [sort keys $list_d->%*],      ['', 'hh'],   'auto no files new';
is [$list_d->{''}->dirs],        ['hh'],       'auto no files root dirs';
is [$list_d->{''}->files],       [],           'auto no files root files';
is [$list_d->{'hh'}->dirs],      [],           'auto no files hh dirs';
is [$list_d->{'hh'}->files],     [],           'auto no files hh files';

done_testing;
