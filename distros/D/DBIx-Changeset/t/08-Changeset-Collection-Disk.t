#!perl -T

use Test::More qw(no_plan); #tests => 1;
use Test::Exception;
use File::Spec;

use lib qw( ./t/lib );

BEGIN {
	use_ok( 'DBIx::Changeset::Collection' );
}

BEGIN {
	use_ok( 'DBIx::Changeset::Collection::Disk' );
}

diag( "Testing DBIx::Changeset::Collection::Disk $DBIx::Changeset::Collection::VERSION, Perl $], $^X" );

### test with invalid dir
my $bogus_coll = DBIx::Changeset::Collection->new('disk', { changeset_location => './fewfwefewf' });
throws_ok(sub { $bogus_coll->retrieve_all(); }, 
				'DBIx::Changeset::Exception::ReadCollectionException','Get exception with invalid changeset_location');

my $coll; 
lives_ok( sub { $coll = DBIx::Changeset::Collection->new('disk', { changeset_location => './t/data/' })}, 'Can create Disk Collection');
isa_ok($coll, 'DBIx::Changeset::Collection::Disk');
can_ok($coll, qw(
				add_changeset		retrieve_all	retrieve_like
				));

## test retrieve_all
lives_ok(sub { $coll->retrieve_all() },'Can retrieve all');

### is files an array of records
isa_ok($coll->files->[0], 'DBIx::Changeset::Record', 'got an array of DBIx::Changeset::Records');

### is the list sorted from oldest to newest
is($coll->total,4,'Got Correct total of records from retrieve_all');

### sorted right
is($coll->files->[0]->uri, '20010505_1.sql', 'first file in correct order');
is($coll->files->[1]->uri, '20020505_blank_valid.sql', '2nd file in correct order');
is($coll->files->[2]->uri, '320020505_blank_valid_pg.sql', 'last file in correct order');
is($coll->files->[3]->uri, '99990505_2.sql', 'last file in correct order');


## test retrieve_like
lives_ok(sub { $coll->retrieve_like(qr/blank_valid/) },'Can retrieve like');

### is files an array of records
isa_ok($coll->files->[0], 'DBIx::Changeset::Record', 'got an array of DBIx::Changeset::Records');
is($coll->files->[0]->uri, '20020505_blank_valid.sql', 'got expected file from retrieve_like');


is($coll->total,2,'Got Correct total of records from retrieve_like');

## test retrieve
lives_ok(sub { $coll->retrieve('20010505_1.sql') },'Can retrieve all');

### is files an array of records
isa_ok($coll->files->[0], 'DBIx::Changeset::Record', 'got an array of DBIx::Changeset::Records');
is($coll->files->[0]->uri, '20010505_1.sql', 'got expected file from retrieve');

is($coll->total,1,'Got Correct total of records from retrieve');

### test adding a changeset
### first invalid
throws_ok(sub { $coll->add_changeset('5') }, 'DBIx::Changeset::Exception::MissingAddTemplateException', 'Throws missing template exception');
throws_ok(sub { $coll->add_changeset('5') }, qr/template/, 'Throws missing template exception');
$coll->retrieve_all();
my $template = File::Spec->catfile('t', 'add_template.txt');
$coll->create_template($template);
my $filename;
lives_ok(sub { $filename = $coll->add_changeset('5') }, 'Can call add changeset');
### filname starts with date
ok($filename =~ m/^t\/data\/(\d{8}_5.sql)$/, 'Filename in correct format');
my $file = $1;
is($coll->total,5,'Correct total after add');
is($coll->files->[2]->uri(),$file,'File name correct and added in correct place');
ok(-e $filename,'Added changset file exists on disk');

unlink($filename);

### sorted right
is($coll->files->[0]->uri, '20010505_1.sql', 'first file in correct order');
is($coll->files->[1]->uri, '20020505_blank_valid.sql', '2nd file in correct order');
is($coll->files->[2]->uri, $file, 'added file in correct order');
is($coll->files->[3]->uri, '320020505_blank_valid_pg.sql', '3rd file in correct order');
is($coll->files->[4]->uri, '99990505_2.sql', 'last file in correct order');

