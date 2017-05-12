#!perl -T

use strict;
use Test::More qw(no_plan); #tests => 1;
use Test::Exception;
use File::stat;
use File::Spec;

BEGIN {
	use_ok( 'DBIx::Changeset::Record' );
}

BEGIN {
	use_ok( 'DBIx::Changeset::Record::Disk' );
}

diag( "Testing DBIx::Changeset::Record::Disk $DBIx::Changeset::Record::Disk::VERSION, Perl $], $^X" );

### clean up tmp file if exists
my $datafile = File::Spec->catfile(qw(t data), 'blank_valid_out.sql');
unlink($datafile);

my $invalid_disk = DBIx::Changeset::Record->new('disk',{ uri => 'mowmdomwqodm', 'changeset_location' => './t/data' });
isa_ok($invalid_disk, 'DBIx::Changeset::Record::Disk', 'get correct object type');
can_ok($invalid_disk,qw(read write md5));

### test read with invalid file
throws_ok(sub { $invalid_disk->read() }, 'DBIx::Changeset::Exception::ReadRecordException', 'Throw read record error with invalid file');

### test read
my $disk = DBIx::Changeset::Record->new('disk',{ uri => '20020505_blank_valid.sql', 'changeset_location' => './t/data' });
my $data;
lives_ok(sub { $data = $disk->read() }, 'Can read without exception');
isnt($data, undef, 'Got the file data');

### is it valid
is($disk->valid, 1, 'File is valid');

### is the id correct
is($disk->id, '32323232323', 'File has expected Id');

### is the md5 correct
is($disk->md5,'dae960c64dc9a7a8cd9ec3f4efc7d02e','Correct MD5');

### test write
my $write_disk = DBIx::Changeset::Record->new('disk',{ uri => 'blank_valid_out.sql', 'changeset_location' => './t/data' });
lives_ok(sub { $write_disk->write($data) },'Write succesful');

### is it valid
is($write_disk->valid, 1, 'File is valid');

### clean up tmp file
unlink($datafile);

### try to create 2 changeset files of the same name
my $duplicate_name = 'blank_duplicate.sql';
my $dupfile = File::Spec->catfile(qw(t data), $duplicate_name);
unlink($dupfile) if -e $dupfile;

my $duplicate_disk = DBIx::Changeset::Record->new('disk',{ uri => $duplicate_name, 'changeset_location' => './t/data' });
lives_ok(sub { $duplicate_disk->write($data) },'Write of first duplicate succesful');

my $duplicate_disk2 = DBIx::Changeset::Record->new('disk',{ uri => $duplicate_name, 'changeset_location' => './t/data' }); 
throws_ok(sub { $duplicate_disk2->write($data) }, 'DBIx::Changeset::Exception::DuplicateRecordNameException', 'Create duplicate unsucessful' );

unlink($dupfile);
