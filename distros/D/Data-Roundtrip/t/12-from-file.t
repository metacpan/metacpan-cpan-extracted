#!perl -T

# this test was randomly being KILLed on CPAN test
# machines (but not mine).
# Haarg at PerlMonks.org suggested:
# The problem you are trying to diagnose is due to a core perl bug in versions before 5.14. This is triggered by passing a tainted string to YAML::PP::Load, which is causing an infinite loop. On the test machines, it is eventually killed, which gives the status of 9 (SIGKILL).
# see https://perlmonks.org/?node_id=11154926
# The remedy until YAML::PP is fixed is either to untaint
# the input string to YAML::PP or use Perl >= v5.14
# I am untainting 1 case.

use 5.008;
use strict;
use warnings;

my $verbose = 0;

#### nothing to change below
use Data::Dump qw/pp/;
use utf8;

our $VERSION='0.24';

use File::Temp;
use File::Spec;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

use Data::Random::Structure;
use Data::Random::Structure::UTF8;

use Data::Roundtrip qw/:all/;

# use this for keeping all tempfiles while CLEANUP=>1
# which is needed for deleting them all at the end
$File::Temp::KEEP_ALL = 1;
my $tmpdir = File::Temp::tempdir(CLEANUP=>1);

diag "calling randomiser ...";
my $randomiser = Data::Random::Structure->new(
	max_depth => 50,
	max_elements => 200,
);
ok(defined $randomiser, 'Data::Random::Structure->new()'." called.") or BAIL_OUT;

diag "called randomiser ... OK";

# first test the sub fix_recursively()
my $td = fix_scalar('abc:xyz"\\aa"\'');
diag "fixed the scalar 1 ... OK";
ok($td !~ /[:"'\\]/, 'fix_scalar()'." : called and it works for bad characters.") or BAIL_OUT("no it did not:\n$td\n");
# with utf8
$td = fix_scalar('αβγ:χψζ"\\αα"\'');
diag "fixed the scalar 2 ... OK";
ok($td !~ /[:"'\\]/, 'fix_scalar()'." : called and it works for bad characters.") or BAIL_OUT("no it did not:\n$td\n");

diag "calling utf8 randomiser";
my $randomiser_utf8 = Data::Random::Structure::UTF8->new(
	max_depth => 50,
	max_elements => 200,
);
ok(defined $randomiser, 'Data::Random::Structure->new()'." called.") or BAIL_OUT;
diag "calling utf8 randomiser OK";

my ($outfile, $FH, $perl_data_structure, $json_string, $yaml_string, $perl_data_structure_from_file);

for my $trial (1..2){
	diag "in trials loop, trial is $trial ...";
  # NOTE: randomiser_utf8->generate() will output to STDERR
  #       I don't know how to generate string-UTF8
  #       it is harmless and it shows that all works ok
  for $perl_data_structure (
	$randomiser->generate(),
	$randomiser_utf8->generate()
  ){
	diag "in perl_data_structure loop, trial is $trial ...";
	ok(defined $perl_data_structure, "random perl data structure created.");

	diag "about to call fix_recursively ...";
	my $recursion_depth = 0;
	fix_recursively($perl_data_structure, \$recursion_depth);
	diag "called fix_recursively OK depth was $recursion_depth";

	# YAML does not like quoted strings to contain escaped quotes

	diag "calling Data::Roundtrip::perl2json ...";
	$json_string = Data::Roundtrip::perl2json($perl_data_structure);
	diag "calling Data::Roundtrip::perl2json OK";
	ok(defined($json_string), "json string created from perl data structure.");

	diag "calling Data::Roundtrip::perl2yaml ...";
	$yaml_string = Data::Roundtrip::perl2yaml($perl_data_structure);
	diag "calling Data::Roundtrip::perl2yaml OK";
	ok(defined($yaml_string), "yaml string created from perl data structure.");

	# write JSON to file
	$outfile = File::Spec->catdir($tmpdir, 'out.json');
	diag "opening out to file $outfile ...";
	ok(open($FH, '>:utf8', $outfile), "open tmp file '${outfile}' for writing JSON string.") or BAIL_OUT;
	diag "writing out to file $outfile ...";
	print $FH $json_string;
	diag "writing out to file $outfile OK";
	close $FH;
	diag "closed file $outfile ...";

	# read JSON from file
	diag "reading jsin from file $outfile ...";
	$perl_data_structure_from_file = Data::Roundtrip::jsonfile2perl($outfile);
	diag "reading jsin from file $outfile OK";
	ok(defined($perl_data_structure_from_file), "jsonfile2perl() : called and got defined result.");
	diag "calling is_deeply ...";
	is_deeply($perl_data_structure, $perl_data_structure_from_file, "jsonfile2perl() : result agrees with what we saved before.");
	diag "calling is_deeply OK";

	# write YAML to file
	$outfile = File::Spec->catdir($tmpdir, 'out.yaml');
	diag "opening2 out to file $outfile ...";
	ok(open($FH, '>:utf8', $outfile), "open tmp file '${outfile}' for writing yaml string.") or BAIL_OUT;
	diag "opening2 out to file $outfile OK";
	print $FH $yaml_string;
	diag "printed out to file $outfile OK";
	close $FH;
	diag "closed out to file $outfile OK";

	# read YAML from file
	diag "calling Data::Roundtrip::yamlfile2perl ...";
	$perl_data_structure_from_file = Data::Roundtrip::yamlfile2perl($outfile);
	diag "calling Data::Roundtrip::yamlfile2perl OK";
	ok(defined($perl_data_structure_from_file), "yamlfile2perl() : called and got defined result.") or BAIL_OUT("--begin YAML:\n${yaml_string}\n--end YAML string.\nfailed for above YAML string");
	diag "calling is_deeply2 ...";
	is_deeply($perl_data_structure, $perl_data_structure_from_file, "yamlfile2perl() : result agrees with what we saved before.") or BAIL_OUT("--begin perl_data_structure:".perl2dump($perl_data_structure_from_file)."--end perl_data_structure_from_file\n\n--begin perl_data_structure_from_file:\n".perl2dump($perl_data_structure_from_file)."--end perl_data_structure_from_file.");
	diag "calling is_deeply2 OK";

	if( $verbose == 0 ){
		diag "verbose is 0 and getting details ...";
		my @tests = Test::More->builder->details;
		diag "verbose is 0 and getting details OK";
		for my $test (@tests) {
			diag "foreach test ...";
			if( ! $test->{ok} ){
				diag "foreach test it is not OK will last...";
				# a test failed, rerun with verbose on
				$verbose = 1;
				last;
			}
		}
	} else { 
		diag "lasting here ... ...";
		last
	 }
	diag "ENDED in perl_data_structure loop, trial is $trial ...";
  }
  diag "ENDED in trials loop, trial is $trial ...";
}

diag "ENDED the trials loop";

# cleanup only on success
diag "temp dir: '$tmpdir' ...";
$File::Temp::KEEP_ALL = 0;
File::Temp::cleanup();

diag "cleaned up";

done_testing;

diag "done testing called.";

# the randomiser produces strings with these characters
# which seem to confuse YAML::Load()
# so we are traversing the data structure and changing all
# scalars: array items, keys, values
# to remove these characters
sub fix_scalar {
	my $instr = $_[0];
	$instr =~ s/[:'"\\]+//g;
	return $instr;
}

sub fix_recursively {
	my $item = $_[0];
	${$_[1]}++;
	diag "fix_recursively : called for depth ".${$_[1]}." ...";
	my $r = ref $item;
	if( $r eq 'ARRAY' ){
		foreach my $at (@$item) {
			if( $r eq '' ){ $at = fix_scalar($at) }
			fix_recursively($at, $_[1]);
		}
	} elsif( $r eq 'HASH' ){
		foreach my $ak (keys %$item) {
			$item->{ fix_scalar($ak) } = fix_scalar($item->{$ak});
			delete $item->{$ak};
		}
		foreach (values %$item) {
			fix_recursively($_, $_[1]);
		}
	} elsif( $r eq '' ){
		$item = fix_scalar($item);
	} else { die perl2dump($item)."do not know this ref: '$r' for above input." }
	diag "fix_recursively : ENDED";
}
