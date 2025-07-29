#!perl -T

use 5.008;
use strict;
use warnings;

my $verbose = 0;

#### nothing to change below
use utf8;

our $VERSION='0.30';

use Test::More;
use Test2::Plugin::UTF8;
#use Test::Deep;

my $num_tests = 0;

use Data::Roundtrip;

for my $trials (1..2){

	my $abc = "abc-αβγ";
	my $xyz = "χψζ-xyz";

	my $json_string = <<EOS;
{"$abc":"$xyz"}
EOS
	$json_string =~ s/\s*$//;

	my $yaml_string = <<EOS;
---
$abc: $xyz
EOS
	#$yaml_string =~ s/\s*$//;

	my $perl_var = {$abc => $xyz};

	# perl2json
	my $result = Data::Roundtrip::perl2json($perl_var);
	ok(defined $result, "perl2json() called."); $num_tests++;
	ok($result eq $json_string, "perl2json() checked".($verbose?" (got: '$result', expected: '$json_string')":"")."."); $num_tests++;

	# json2perl
	$result = Data::Roundtrip::json2perl($json_string);
	ok(defined $result, "json2perl() called."); $num_tests++;
	for my $k (keys %$result){
		ok(exists $perl_var->{$k}, "json2perl() key exists."); $num_tests++;
		ok($perl_var->{$k} eq $result->{$k}, "json2perl() values are the same."); $num_tests++;
	}
	for my $k (keys %$perl_var){
		ok(exists $result->{$k}, "json2perl() key exists (other way round)."); $num_tests++;
	}

	# perl2yaml
	$result = Data::Roundtrip::perl2yaml($perl_var);
	ok(defined $result, "perl2yaml() called."); $num_tests++;
	ok($result eq $yaml_string, "perl2yaml() checked".($verbose?" (got: '$result', expected: '$yaml_string')":"")."."); $num_tests++;

	# yaml2perl
	$result = Data::Roundtrip::yaml2perl($yaml_string);
	ok(defined $result, "yaml2perl() called."); $num_tests++;
	for my $k (keys %$result){
		ok(exists $perl_var->{$k}, "yaml2perl() key exists."); $num_tests++;
		ok($perl_var->{$k} eq $result->{$k}, "yaml2perl() values are the same."); $num_tests++;
	}
	for my $k (keys %$perl_var){
		ok(exists $result->{$k}, "yaml2perl() key exists (other way round)."); $num_tests++;
	}

	# yaml2json
	$result = Data::Roundtrip::yaml2json($yaml_string);
	ok(defined $result, "yaml2json() called."); $num_tests++;
	ok($result eq $json_string, "perl2yaml() checked".($verbose?" (got: '$result', expected: '$json_string')":"")."."); $num_tests++;

	# json2yaml
	$result = Data::Roundtrip::json2yaml($json_string);
	ok(defined $result, "json2yaml() called."); $num_tests++;
	ok($result eq $yaml_string, "perl2yaml() checked".($verbose?" (got: '$result', expected: '$yaml_string')":"")."."); $num_tests++;

	# perl2dump and dump2perl WITH unicode escaping
	# (that's default Data::Dumper behaviour)
	# this is what you must see: 
	#  "abc-\x{3b1}\x{3b2}\x{3b3}" => "\x{3c7}\x{3c8}\x{3b6}-xyz"
	my $adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>1, 'dont-bloody-escape-unicode'=>0}
	);
	ok(defined $adump, "perl2dump() called."); $num_tests++;
	ok($adump=~/(\\x\{3b1\})/, "perl2dump() unicode not escaped".($verbose?" ($adump)":"")."."); $num_tests++;

	# dump2perl
	$result = Data::Roundtrip::dump2perl($adump);
	ok(defined $result, "dump2perl() called."); $num_tests++;
	for my $k (keys %$result){
		ok(exists $perl_var->{$k}, "perl2dump() and dump2perl() key exists."); $num_tests++;
		ok($perl_var->{$k} eq $result->{$k}, "perl2dump() and dump2perl() values are the same."); $num_tests++;
	}
	for my $k (keys %$perl_var){
		ok(exists $result->{$k}, "perl2dump() and dump2perl() key exists (other way round)."); $num_tests++;
	}

	# perl2dump and dump2perl WITHOUT unicode escaping
	# (that's NOT default Data::Dumper behaviour)
	# that means to get this output: 
	#  "abc-αβγ" => "χψζ-xyz"
	$adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>1, 'dont-bloody-escape-unicode'=>1}
	);
	ok(defined($adump), "perl2dump() called."); $num_tests++;
	ok($adump!~/\\x\{3b1\}/, "perl2dump() unicode not escaped."); $num_tests++;

	# dump2perl
	$result = Data::Roundtrip::dump2perl($adump);
	ok(defined $result, "dump2perl() called".($verbose?" ($adump)":"")."."); $num_tests++;
	for my $k (keys %$result){
		ok(exists $perl_var->{$k}, "perl2dump() and dump2perl() key exists".($verbose?$k:"")."."); $num_tests++;
		ok($perl_var->{$k} eq $result->{$k}, "perl2dump() and dump2perl() values are the same."); $num_tests++;
	}
	for my $k (keys %$perl_var){
		ok(exists $result->{$k}, "perl2dump() and dump2perl() key exists (other way round)."); $num_tests++;
	}

	# perl2dump and dump2perl WITHOUT unicode escaping
	# but complex input.
	# (that's NOT default Data::Dumper behaviour)
	# that means to get this output: 
	#  "abc-αβγ" => "χψζ-xyz"
	$perl_var = {};
	$perl_var->{'key1'} = <<EOP;
\"\\u0398\\u03b5\\u03c4\\u03b9\\u03ba\\u03ac Normalized\\"},\\"Name\\":\\"dashboard_view.\\u0398\\u03b5\\u03c4\\u03b9\\u03ba\\u03ac Normalized\\"},{\\"Measure\\":{\\"Expression\\":{\\"SourceRef\\":{\\"Source\\":\\"d\\"}},\\"Property\\":\\"\\u0394\\u03b5\\u03af\\u03b3\\u03bc\\u03b1\\u03c4\\u03b1 Normalized\\"},\\"Name\\":\\"dashboard_view.\\u0394\\u03b5\\u03af\\u03b3\\u03bc\\u03b1\\u03c4\\u03b1 Normalized\\"},{\\"Measure\\":{\\"Expression\\":{\\"SourceRef\\":{\\"Source\\":\\"d\\"}},\\"Property\\":\\"\\u0391\\u03bd\\u03b1\\u03c6\\u03bf\\u03c1\\u03ad\\u03c2 Normalized\\"},\\"Name\\":\\"dashboard_view.\\u0391\\u03bd\\u03b1\\u03c6\\u03bf\\u03c1\\u03ad\\u03c2 Normalized\\"}],\\"OrderBy\\":[{\\"Direction\\":1,\\"Expression\\":{\\"Column\\":{\\"Expression\\":{\\"SourceRef\\":{\\"Source\\":\\"p\\"}},\\"Property\\":\\"name_gr\\"}}}]},\\"Binding\\":{\\"Primary\\":{\\"Groupings\\":[{\\"Projections\\":[0,1,2,3]}]},\\"DataReduction\\":{\\"
EOP
	$adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>1, 'dont-bloody-escape-unicode'=>1}
	);
	ok(defined $adump, "perl2dump() called."); $num_tests++;
	ok($adump!~/\\x\{3b1\}/, "perl2dump() unicode not escaped."); $num_tests++;
	# dump2perl
	$result = Data::Roundtrip::dump2perl($adump);
	ok(defined $result, "dump2perl() called."); $num_tests++;
	for my $k (keys %$result){
		ok(exists $perl_var->{$k}, "perl2dump() and dump2perl() key exists."); $num_tests++;
		ok($perl_var->{$k} eq $result->{$k}, "perl2dump() and dump2perl() values are the same."); $num_tests++;
	}
	for my $k (keys %$perl_var){
		ok(exists $result->{$k}, "perl2dump() and dump2perl() key exists (other way round)."); $num_tests++;
	}

	# check terse and indent modes
	# use a perl var which is complex enough to cause indent and terse differences
	$perl_var = {$abc => $xyz, $xyz => $abc, "123" => $xyz, "545" => $abc, "arr" => [$abc, $xyz, '123', [1,2,3], 0]};
	$adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>1, 'dont-bloody-escape-unicode'=>0, 'indent'=>0});
	ok(defined $adump, "perl2dump() called."); $num_tests++;
	ok($adump=~/(\\x\{3b1\})/, "perl2dump() unicode not escaped".($verbose?" ($adump)":"")."."); $num_tests++;
	# terse: do we have $VAR1?
	ok($adump!~/^\$VAR1/, "perl2dump() is in terse mode".($verbose?" ($adump)":"")."."); $num_tests++;
	# indent: do we have new lines?
	ok($adump!~/\r\n|\r|\n/, "perl2dump() allows indent".($verbose?" ($adump)":"")."."); $num_tests++;

	$adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>1, 'dont-bloody-escape-unicode'=>1, 'indent'=>0});
	ok(defined $adump, "perl2dump() called."); $num_tests++;
	ok($adump!~/(\\x\{3b1\})/, "perl2dump() unicode not escaped".($verbose?" ($adump)":"")."."); $num_tests++;
	# terse: do we have $VAR1?
	ok($adump!~/^\$VAR1/, "perl2dump() is in terse mode".($verbose?" ($adump)":"")."."); $num_tests++;
	# indent: do we have new lines?
	ok($adump!~/\r\n|\r|\n/, "perl2dump() allows indent".($verbose?" ($adump)":"")."."); $num_tests++;

	$adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>0, 'dont-bloody-escape-unicode'=>0, 'indent'=>0});
	ok(defined $adump, "perl2dump() called."); $num_tests++;
	ok($adump=~/(\\x\{3b1\})/, "perl2dump() unicode not escaped".($verbose?" ($adump)":"")."."); $num_tests++;
	# terse: do we have $VAR1?
	ok($adump=~/^\$VAR1/, "perl2dump() is in terse mode".($verbose?" ($adump)":"")."."); $num_tests++;
	# indent: do we have new lines?
	ok($adump!~/\r\n|\r|\n/, "perl2dump() allows indent".($verbose?" ($adump)":"")."."); $num_tests++;

	$adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>0, 'dont-bloody-escape-unicode'=>1, 'indent'=>0});
	ok(defined $adump, "perl2dump() called."); $num_tests++;
	ok($adump!~/(\\x\{3b1\})/, "perl2dump() unicode not escaped".($verbose?" ($adump)":"")."."); $num_tests++;
	# terse: do we have $VAR1?
	ok($adump=~/^\$VAR1/, "perl2dump() is in terse mode".($verbose?" ($adump)":"")."."); $num_tests++;
	# indent: do we have new lines?
	ok($adump!~/\r\n|\r|\n/, "perl2dump() allows indent".($verbose?" ($adump)":"")."."); $num_tests++;

	## now with no indent
	$adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>1, 'dont-bloody-escape-unicode'=>0, 'indent'=>1});
	ok(defined $adump, "perl2dump() called."); $num_tests++;
	ok($adump=~/(\\x\{3b1\})/, "perl2dump() unicode not escaped".($verbose?" ($adump)":"")."."); $num_tests++;
	# terse: do we have $VAR1?
	ok($adump!~/^\$VAR1/, "perl2dump() is in terse mode".($verbose?" ($adump)":"")."."); $num_tests++;
	# indent: do we have new lines?
	ok($adump=~/\r\n|\r|\n/, "perl2dump() allows indent".($verbose?" ($adump)":"")."."); $num_tests++;

	$adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>1, 'dont-bloody-escape-unicode'=>1, 'indent'=>1});
	ok(defined $adump, "perl2dump() called."); $num_tests++;
	ok($adump!~/(\\x\{3b1\})/, "perl2dump() unicode not escaped".($verbose?" ($adump)":"")."."); $num_tests++;
	# terse: do we have $VAR1?
	ok($adump!~/^\$VAR1/, "perl2dump() is in terse mode".($verbose?" ($adump)":"")."."); $num_tests++;
	# indent: do we have new lines?
	ok($adump=~/\r\n|\r|\n/, "perl2dump() allows indent".($verbose?" ($adump)":"")."."); $num_tests++;

	$adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>0, 'dont-bloody-escape-unicode'=>0, 'indent'=>1});
	ok(defined $adump, "perl2dump() called."); $num_tests++;
	ok($adump=~/(\\x\{3b1\})/, "perl2dump() unicode not escaped".($verbose?" ($adump)":"")."."); $num_tests++;
	# terse: do we have $VAR1?
	ok($adump=~/^\$VAR1/, "perl2dump() is in terse mode".($verbose?" ($adump)":"")."."); $num_tests++;
	# indent: do we have new lines?
	ok($adump=~/\r\n|\r|\n/, "perl2dump() allows indent".($verbose?" ($adump)":"")."."); $num_tests++;

	$adump = Data::Roundtrip::perl2dump($perl_var,
		{'terse'=>0, 'dont-bloody-escape-unicode'=>1, 'indent'=>1});
	ok(defined $adump, "perl2dump() called."); $num_tests++;
	ok($adump!~/(\\x\{3b1\})/, "perl2dump() unicode not escaped".($verbose?" ($adump)":"")."."); $num_tests++;
	# terse: do we have $VAR1?
	ok($adump=~/^\$VAR1/, "perl2dump() is in terse mode".($verbose?" ($adump)":"")."."); $num_tests++;
	# indent: do we have new lines?
	ok($adump=~/\r\n|\r|\n/, "perl2dump() allows indent".($verbose?" ($adump)":"")."."); $num_tests++;

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

done_testing($num_tests);
