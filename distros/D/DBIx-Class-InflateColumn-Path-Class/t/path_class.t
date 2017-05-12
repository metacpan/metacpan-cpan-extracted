#!perl -wT
use strict;
use warnings;
use Test::More;

BEGIN {
    use lib 't/lib';
    use TestDB;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
      } else {
        plan tests => 15;
      };

    use_ok('Path::Class');
  };

my $schema = TestDB->init_schema;

my $rel_file = Path::Class::file('rel','file.txt');
my $abs_file = Path::Class::file('/','abs','file.txt');
ok(  $abs_file->is_absolute );
ok( !$rel_file->is_absolute );

my $rs = $schema->resultset('Foo');

my $row = $rs->create({
             id => 1,
             file_path => $rel_file,
             dir_path => $rel_file->dir,
            });

$rs->create({
             id => 2,
             file_path => $abs_file,
             dir_path => $abs_file->dir,
            });

isa_ok($row->dir_path, 'Path::Class::Dir');
isa_ok($row->file_path, 'Path::Class::File');
is($row->dir_path->stringify, 'rel', 'relative dir' );
is($row->file_path->stringify, 'rel/file.txt', 'relative file' );
ok( !$row->file_path->dir->is_absolute );
ok( !$row->file_path->is_absolute );

my $row2 = $rs->find({id => 2});
isa_ok($row2->dir_path, 'Path::Class::Dir');
isa_ok($row2->file_path, 'Path::Class::File');
is($row2->dir_path->stringify, '/abs', 'relative dir' );
is($row2->file_path->stringify, '/abs/file.txt', 'relative file' );
ok( $row2->file_path->dir->is_absolute );
ok( $row2->file_path->is_absolute );
