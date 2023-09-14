#!perl -T

use 5.008;
use strict;
use warnings;

my $verbose = 0;

#### nothing to change below
use Data::Dump qw/pp/;
use utf8;

our $VERSION='0.18';

use File::Temp;
use File::Spec;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

use Data::Random::Structure;
use Data::Random::Structure::UTF8;

use Data::Roundtrip qw/:all/;

my $tmpdir = File::Temp::tempdir(CLEANUP=>1);

my $randomiser = Data::Random::Structure->new(
	max_depth => 50,
	max_elements => 200,
);
ok(defined $randomiser, 'Data::Random::Structure->new()'." called.") or BAIL_OUT;

my $randomiser_utf8 = Data::Random::Structure::UTF8->new(
	max_depth => 50,
	max_elements => 200,
);
ok(defined $randomiser, 'Data::Random::Structure->new()'." called.") or BAIL_OUT;

my ($outfile, $FH, $perl_data_structure, $json_string, $yaml_string, $perl_data_structure_from_file);

for my $trials (1..2){
  for $perl_data_structure ($randomiser->generate(), $randomiser_utf8->generate()){
	ok(defined $perl_data_structure, "random perl data structure created.");

	$json_string = Data::Roundtrip::perl2json($perl_data_structure);
	ok(defined($json_string), "json string created from perl data structure.");

	$yaml_string = Data::Roundtrip::perl2yaml($perl_data_structure);	ok(defined($json_string), "json string created from perl data structure.");
	ok(defined($yaml_string), "yaml string created from perl data structure.");

	# write JSON to file
	$outfile = File::Spec->catdir($tmpdir, 'out.json');
	ok(open($FH, '>:utf8', $outfile), "open tmp file '${outfile}' for writing JSON string.") or BAIL_OUT;
	print $FH $json_string;
	close $FH;

	# read JSON from file
	$perl_data_structure_from_file = Data::Roundtrip::jsonfile2perl($outfile);
	ok(defined($perl_data_structure_from_file), "jsonfile2perl() : called and got defined result.");
	is_deeply($perl_data_structure, $perl_data_structure_from_file, "jsonfile2perl() : result agrees with what we saved before.");

	# write YAML to file
	$outfile = File::Spec->catdir($tmpdir, 'out.yaml');
	ok(open($FH, '>:utf8', $outfile), "open tmp file '${outfile}' for writing yaml string.") or BAIL_OUT;
	print $FH $yaml_string;
	close $FH;

	# read YAML from file
	$perl_data_structure_from_file = Data::Roundtrip::yamlfile2perl($outfile);
	ok(defined($perl_data_structure_from_file), "yamlfile2perl() : called and got defined result.");
	is_deeply($perl_data_structure, $perl_data_structure_from_file, "yamlfile2perl() : result agrees with what we saved before.");

	if( $verbose == 0 ){
		my @tests = Test::More->builder->details;
		for my $test (@tests) {
			if(! $test->{ok} ){
				# a test failed, rerun with verbose on
				$verbose = 1;
				last;
			}
		}
	} else { last }
  }
}	

done_testing;
