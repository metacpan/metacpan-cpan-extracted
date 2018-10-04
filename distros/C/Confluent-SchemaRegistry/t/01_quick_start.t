#!/bin/env perl

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Purity = 1;
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;

#use Test::More qw( no_plan );
use Test::More tests => 44;

BEGIN { use_ok('Confluent::SchemaRegistry', qq/Using/); }

my $class = 'Confluent::SchemaRegistry';

# Main AVRO schema
my $main_schema = {
	name => 'test_contacts',
	type => 'record',
	fields => [
		{
			name => 'name',
			type => 'string'
		},
		{
			name => 'age',
			type => 'int'
		}
	]
};
# Invalid AVRO schema
my $invalid_schema = {
};
# Backward compatible AVRO schema
my $compliant_schema = {
	name => 'test_contacts',
	type => 'record',
	fields => [
		{
			name => 'name',
			type => 'string'
		},
		{
			name => 'age',
			type => 'int'
		},
		{
			name => 'gender',
			type => 'string',
			default => 'XXX'
		}
	]
};
# Non backward compatible AVRO schema (due to non-nullable new field)
my $non_compliant_schema = {
	name => 'test_contacts',
	type => 'record',
	fields => [
		{
			name => 'name',
			type => 'string'
		},
		{
			name => 'age',
			type => 'int'
		},
		{
			name => 'gender',
			type => 'string'
		}
	]
};

my $subject = 'confluent-schema-registry-' . time;
my $type = 'value';

my $sr;

SKIP: {

	$sr = new_ok($class => [ 'host', 'http://localhost:8081' ], qq/Valid REST client config/);
	
	skip qq/Confluent Schema Registry service is not up or isn't running on localhost:8081/, 30 unless defined $sr;
	
	$sr = undef;

	$sr = new_ok($class => [], qq/Default host and port/);

	ok(!defined $sr->add_schema(), qq/Bad call to add_schema/);
	ok(!defined $sr->add_schema(SUBJECT => $subject), qq/Bad call to add_schema/);
	ok(!defined $sr->add_schema(SUBJECT => $subject, TYPE => ''), qq/Bad empty TYPE in call to add_schema/);
	ok(!defined $sr->add_schema(SUBJECT => $subject, TYPE => 'foo'), qq/Bad TYPE in call to add_schema/);
	ok(!defined $sr->add_schema(SUBJECT => $subject, TYPE => $type), qq/Bad call to add_schema/);

	ok(!defined $sr->add_schema(SUBJECT => $subject, TYPE => $type, SCHEMA => $invalid_schema), qq/Invalid schema/);

	my $new_id = $sr->add_schema(SUBJECT => $subject, TYPE => $type, SCHEMA => $main_schema);
	like($new_id, qr/^\d+$/, qq/Good call to add_schema(SUBJECT=>'$subject', TYPE=>'$type', SCHEMA=>'...') returns $new_id/);

	my $subjects = $sr->get_subjects();
	isa_ok($subjects, 'ARRAY', qq/Subjects/);
	#print STDERR Dumper $subjects;

	my $versions = $sr->get_schema_versions(SUBJECT => $subject, TYPE => $type);
	isa_ok($versions, 'ARRAY', qq/Schema versions/);
	ok(scalar(@$versions)==1, qq/Only one version for current subject/);

	my $loaded_schema = $sr->get_schema_by_id(SCHEMA_ID => $new_id);
	is_deeply($loaded_schema, Avro::Schema->parse_struct($main_schema), qq/Comparison between main & loaded by id schema/);
	$loaded_schema = $sr->get_schema(SUBJECT => $subject, TYPE => $type, VERSION => $versions->[$#$versions]);
	is_deeply($loaded_schema->{schema}, Avro::Schema->parse_struct($main_schema), qq/Comparison between main & loaded by version number schema/);
	$loaded_schema = $sr->get_schema(SUBJECT => $subject, TYPE => $type);
	is_deeply($loaded_schema->{schema}, Avro::Schema->parse_struct($main_schema), qq/Comparison between main & loaded by latest schema/);
	ok(!defined $sr->get_schema(SUBJECT => 'unknown subject', TYPE => $type), qq/Unknown schema/);
	ok($sr->get_error()->{error_code} == 40401, qq/Unknown schema/);

	my $schema_info = $sr->check_schema(SUBJECT => $subject, TYPE => $type);
	ok(!defined($schema_info), 'Missing parameter SCHEMA calling check_schema() method');

	$schema_info = $sr->check_schema(SUBJECT => $subject, TYPE => $type, SCHEMA => $main_schema);
	isa_ok($schema_info, 'HASH', 'Valid check_schema() call');
	ok($schema_info->{subject} eq $subject.'-'.$type, 'Positive schema check');

	$schema_info = $sr->check_schema(SUBJECT => $subject, TYPE => $type, SCHEMA => $compliant_schema);
	ok(!exists $schema_info->{subject}, 'Negative schema check');


	my $is_compliant = $sr->test_schema(SUBJECT => $subject, TYPE => $type);
	ok(!defined($is_compliant), 'Missing parameter SCHEMA calling test_schema() method');

	$is_compliant = $sr->test_schema(SUBJECT => $subject, TYPE => $type, SCHEMA => $compliant_schema);
	ok($is_compliant, 'Positive schema test');

	$is_compliant = $sr->test_schema(SUBJECT => $subject, TYPE => $type, SCHEMA => $non_compliant_schema);
	ok(!$is_compliant, 'Negative schema test');

	my $newest_id = $sr->add_schema(SUBJECT => $subject, TYPE => $type, SCHEMA => $compliant_schema);
	like($newest_id, qr/^\d+$/, qq/Add new schema/);

	my $new_versions = $sr->get_schema_versions(SUBJECT => $subject, TYPE => $type); 
	ok(scalar(@$new_versions)==scalar(@$versions)+1, qq/Expected +1 version/); 


	my $original_cl = $sr->get_top_level_config();
	ok(grep(/^$original_cl$/, @{$Confluent::SchemaRegistry::COMPATIBILITY_LEVELS}), 'Get top-level compatibility level');

	my $cl = $sr->set_top_level_config(COMPATIBILITY_LEVEL => 'FULL');
	ok($cl eq 'FULL', 'Update top-level compatibility level');

	$cl = $sr->get_top_level_config();
	ok($cl eq 'FULL', 'Verify top-level compatibility level');

	$cl = $sr->set_top_level_config(COMPATIBILITY_LEVEL => $original_cl);
	ok($cl eq $original_cl, 'Restore top-level compatibility level');

	$cl = $sr->get_top_level_config();
	ok($cl eq $original_cl, 'Verify restored top-level compatibility level');


	$cl = $sr->get_config(SUBJECT => $subject, TYPE => $type);
	ok(!defined $cl, 'Get default compatibility level'); # When fresh, returns undef because inherits top-level compatibility level

	$cl = $sr->set_config(SUBJECT => $subject, TYPE => $type, COMPATIBILITY_LEVEL => 'NONE');
	ok($cl eq 'NONE', 'Update compatibility level');

	$cl = $sr->get_config(SUBJECT => $subject, TYPE => $type);
	ok($cl eq 'NONE', 'Verify compatibility level');

	$cl = $sr->set_config(SUBJECT => $subject, TYPE => $type, COMPATIBILITY_LEVEL => 'BACKWARD');
	ok($cl eq 'BACKWARD', 'Restore BACKWARD compatibility level');

	$cl = $sr->get_config(SUBJECT => $subject, TYPE => $type);
	ok($cl eq 'BACKWARD', 'Verify BACKWARD compatibility level');

	my $deleted_version;
	ok(!defined $sr->delete_schema(SUBJECT => $subject, TYPE => $type, VERSION => 9999), qq/Previous schema deletion failure due to unknown version/);

	$deleted_version = $sr->delete_schema(SUBJECT => $subject, TYPE => $type); 
	ok(!defined $deleted_version, qq/Previous schema deletion failure due to unspecified version/);

	$deleted_version = $sr->delete_schema(SUBJECT => $subject, TYPE => $type, VERSION => $new_versions->[0]); 
	ok($deleted_version == $new_versions->[0], qq/Previous schema deletion/);

	$deleted_version = $sr->delete_all_schemas(SUBJECT => $subject, TYPE => $type);
	isa_ok($deleted_version, 'ARRAY', qq/Delete all schemas/);

	$newest_id = $sr->add_schema(SUBJECT => $subject, TYPE => $type, SCHEMA => $compliant_schema);
	like($newest_id, qr/^\d+$/, qq/Add new schema/);

	my $deleted;
	ok(!defined $sr->delete_subject(SUBJECT => 'UNKNOWN-SUBJECT', TYPE => $type), qq/Unknown subject deletion/);

	$deleted = $sr->delete_subject(SUBJECT => $subject, TYPE => $type);
	isa_ok($deleted, 'ARRAY', qq/Subject deletion/);

}
;
