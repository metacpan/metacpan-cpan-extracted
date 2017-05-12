#!perl -T

use Test::More qw(no_plan);#tests => 5;
use Test::Exception;

use lib qw( ./t/lib );

BEGIN {
	require_ok( 'DBIx::Changeset::Record' );
}

diag( "Testing DBIx::Changeset::Record $DBIx::Changeset::Record::VERSION, Perl $], $^X" );

my @registered_classes = DBIx::Changeset::Record->get_registered_classes;
is( scalar @registered_classes, 1, 'Number of classes registered so far' );
is( $registered_classes[0], 'DBIx::Changeset::Record::Disk', 'Default class registered' );

my @registered_types = DBIx::Changeset::Record->get_registered_types;
is( scalar @registered_types, 1, 'Number of types registered so far' );
is( $registered_types[0], 'disk', 'Default type registered' );

### add a simple test factory so we can test the DBIx::Changeset::Record base func
DBIx::Changeset::Record->add_factory_type( 'test' => FactoryFileTest );

### check the create with out uri exception
throws_ok(sub { DBIx::Changeset::Record->new('test') }, 'DBIx::Changeset::Exception::ObjectCreateException', 'Got Object Create Exception');
throws_ok(sub { DBIx::Changeset::Record->new('test') }, qr/without a uri/, 'Got Correct Object Create Exception Message');

my $file; 
lives_ok(sub { $file = DBIx::Changeset::Record->new('test', { uri => '20010505_1.sql' }) }, 'Can create a valid record object.');
isa_ok($file, 'DBIx::Changeset::Record', 'Correct Object Type');
can_ok($file, qw(read write validate generate_uid id uri valid skipped outstanding forced));

## test uri is read only
throws_ok(sub { $file->uri('wefewfwefew') }, qr/cannot alter the value of 'uri'/, 'URI Accessor is readonly');

## test validate
is($file->validate(), undef,'Can run Validate');
$file->valid(undef);
is($file->valid,1,'File is validated when valid is undef');
$file->id(undef);
isnt($file->id,undef,'validate called when id is undef');

## test generate_uid
my $current_id = $file->id;
isnt($current_id, undef, 'File has uid');
is($file->generate_uid(), undef, 'Can run generate_uid');
$file->read();
isnt($current_id, $file->id, 'id is different after generate uid');


