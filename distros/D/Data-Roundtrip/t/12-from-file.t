#!perl

# this test was randomly being KILLed on CPAN test
# machines (but not mine).
# Haarg at PerlMonks.org suggested:
# The problem you are trying to diagnose is due to a core perl bug in versions before 5.14. This is triggered by passing a tainted string to YAML::PP::Load, which is causing an infinite loop. On the test machines, it is eventually killed, which gives the status of 9 (SIGKILL).
# see https://perlmonks.org/?node_id=11154926
# The remedy until YAML::PP is fixed is either to untaint
# the input string to YAML::PP or use Perl >= v5.14
# I am untainting 1 case.

# Another issue is that Data::Random::Structure returning 
# floats we get something like this with Test::More's is_deeply()
#   Failed test 'jsonfile2perl() : result agrees with what we saved before.'
#   at t/12-from-file.t line 120.
#     Structures begin differing at:
#          $got->[0] = '0.764232574944025'
#     $expected->[0] = '0.764232574944026'
# in fix_scalar() we reduce the number of decimal digits, and hope for the best

###################################################################
#### NOTE env-var PERL_TEST_TEMPDIR_TINY_NOCLEANUP=1 will stop erasing tmp files
###################################################################

use 5.008;
use strict;
use warnings;

my $verbose = 0;
my $DIAG_verbose = 0;

#### nothing to change below
use utf8;

our $VERSION='0.30';

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use Test::TempDir::Tiny;
use File::Spec;

use Data::Random::Structure;
use Data::Random::Structure::UTF8;

use Data::Roundtrip qw/:all/;

# if for debug you change this make sure that it has path in it e.g. ./xyz
my $tmpdir = tempdir(); # will be erased unless a BAIL_OUT or env var set
ok(-d $tmpdir, "output dir exists");

if( $DIAG_verbose > 0 ){ diag "calling randomiser ..."; }

my $randomiser = Data::Random::Structure->new(
	max_depth => 50,
	max_elements => 200,
);
ok(defined $randomiser, 'Data::Random::Structure->new()'." called.") or BAIL_OUT;
if( $DIAG_verbose > 0 ){ diag "called randomiser ... OK"; }

if( $DIAG_verbose > 0 ){ diag "calling utf8 randomiser"; }
my $randomiser_utf8 = Data::Random::Structure::UTF8->new(
	max_depth => 5,
	max_elements => 20,
);
ok(defined $randomiser, 'Data::Random::Structure->new()'." called.") or BAIL_OUT;
if( $DIAG_verbose > 0 ){ diag "calling utf8 randomiser OK"; }

my ($outfile, $FH, $perl_data_structure, $json_string, $yaml_string,
    $perl_data_structure_from_file, $perl_data_structure_name);

for my $trial (1..2){
	if( $DIAG_verbose > 0 ){ diag "in trials loop, trial is $trial ..."; }
  # NOTE: randomiser_utf8->generate() will output to STDERR
  #       I don't know how to generate string-UTF8
  #       it is harmless and it shows that all works ok
  for my $ad (
	['randomiser', $randomiser->generate()],
	['randomiser_utf8', $randomiser_utf8->generate()]
  ){
	($perl_data_structure_name, $perl_data_structure) = @$ad;
	if( $DIAG_verbose > 0 ){ diag "in perl_data_structure loop, trial is $trial, randomiser is '$perl_data_structure_name' ..."; }
	ok(defined $perl_data_structure, "random perl data structure created ('$perl_data_structure_name'/$trial).");

	if( $DIAG_verbose > 0 ){ diag "about to call fix_recursively ..."; }
	my $recursion_depth = 0;
	fix_recursively($perl_data_structure, \$recursion_depth);
	if( $DIAG_verbose > 0 ){ diag "called fix_recursively OK depth was $recursion_depth"; }

	# YAML does not like quoted strings to contain escaped quotes
	# But YAML::PP copes just fine, and it is YAML::PP being used now

	if( $DIAG_verbose > 0 ){ diag "calling Data::Roundtrip::perl2json ..."; }
	$json_string = Data::Roundtrip::perl2json($perl_data_structure);
	if( $DIAG_verbose > 0 ){ diag "calling Data::Roundtrip::perl2json OK"; }
	ok(defined($json_string), "json string created from perl data structure ('$perl_data_structure_name'/$trial).");

	if( $DIAG_verbose > 0 ){ diag "calling Data::Roundtrip::perl2yaml ..."; }
	$yaml_string = Data::Roundtrip::perl2yaml($perl_data_structure);
	if( $DIAG_verbose > 0 ){ diag "calling Data::Roundtrip::perl2yaml OK"; }
	ok(defined($yaml_string), "yaml string created from perl data structure ('$perl_data_structure_name'/$trial).");

	# write JSON to file
	$outfile = File::Spec->catfile($tmpdir, 'out.json');
	if( $DIAG_verbose > 0 ){ diag "opening out to file $outfile ..."; }
	ok(open($FH, '>:encoding(UTF-8)', $outfile), "open tmp file '${outfile}' for writing JSON string ('$perl_data_structure_name'/$trial).") or BAIL_OUT;
	if( $DIAG_verbose > 0 ){ diag "writing out to file $outfile ..."; }
	print $FH $json_string;
	if( $DIAG_verbose > 0 ){ diag "writing out to file $outfile OK"; }
	close $FH;
	if( $DIAG_verbose > 0 ){ diag "closed file $outfile ..."; }

	# read JSON from file
	if( $DIAG_verbose > 0 ){ diag "reading jsin from file $outfile ..."; }
	$perl_data_structure_from_file = Data::Roundtrip::jsonfile2perl($outfile);
	if( $DIAG_verbose > 0 ){ diag "reading jsin from file $outfile OK"; }
	ok(defined($perl_data_structure_from_file), "jsonfile2perl() : called and got defined result ('$perl_data_structure_name'/$trial).");
	if( $DIAG_verbose > 0 ){ diag "calling is_deeply ..."; }
	is_deeply($perl_data_structure, $perl_data_structure_from_file, "jsonfile2perl() : result agrees with what we saved before ('$perl_data_structure_name'/$trial).");
	if( $DIAG_verbose > 0 ){ diag "calling is_deeply OK"; }

	# write YAML data to file
	$outfile = File::Spec->catfile($tmpdir, 'out.yaml');
	if( $DIAG_verbose > 0 ){ diag "opening2 out to file $outfile ..."; }
	ok(open($FH, '>:encoding(UTF-8)', $outfile), "open tmp file '${outfile}' for writing yaml string ('$perl_data_structure_name'/$trial).") or BAIL_OUT;
	if( $DIAG_verbose > 0 ){ diag "opening2 out to file $outfile OK"; }
	print $FH $yaml_string;
	if( $DIAG_verbose > 0 ){ diag "printed out to file $outfile OK"; }
	close $FH;
	if( $DIAG_verbose > 0 ){ diag "closed out to file $outfile OK"; }

	# read YAML from file
	if( $DIAG_verbose > 0 ){ diag "calling Data::Roundtrip::yamlfile2perl ..."; }
	$perl_data_structure_from_file = Data::Roundtrip::yamlfile2perl($outfile);
	if( $DIAG_verbose > 0 ){ diag "calling Data::Roundtrip::yamlfile2perl OK"; }
	ok(defined($perl_data_structure_from_file), "yamlfile2perl() : called and got defined result ('$perl_data_structure_name'/$trial).") or BAIL_OUT("--begin YAML:\n${yaml_string}\n--end YAML string.\nfailed for above YAML string");
	if( $DIAG_verbose > 0 ){ diag "calling is_deeply2 ..."; }
	is_deeply($perl_data_structure, $perl_data_structure_from_file, "yamlfile2perl() : result agrees with what we saved before ('$perl_data_structure_name'/$trial).") or BAIL_OUT("--begin perl_data_structure:".perl2dump($perl_data_structure_from_file)."--end perl_data_structure_from_file\n\n--begin perl_data_structure_from_file:\n".perl2dump($perl_data_structure_from_file)."--end perl_data_structure_from_file.");
	if( $DIAG_verbose > 0 ){ diag "calling is_deeply2 OK"; }

	if( $verbose == 0 ){
		if( $DIAG_verbose > 0 ){ diag "verbose is 0 and getting details ..."; }
		my @tests = Test::More->builder->details;
		if( $DIAG_verbose > 0 ){ diag "verbose is 0 and getting details OK"; }
		for my $test (@tests) {
			if( $DIAG_verbose > 0 ){ diag "foreach test ..."; }
			if( ! $test->{ok} ){
				if( $DIAG_verbose > 0 ){ diag "foreach test it is not OK will last..."; }
				# a test failed, rerun with verbose on
				$verbose = 1;
				last;
			}
		}
	} else { 
		if( $DIAG_verbose > 0 ){ diag "lasting here ... ..."; }
		last
	 }
	if( $DIAG_verbose > 0 ){ diag "ENDED in perl_data_structure loop, trial is $trial ..."; }
  }
  if( $DIAG_verbose > 0 ){ diag "ENDED in trials loop, trial is $trial ..."; }
}

if( $DIAG_verbose > 0 ){ diag "ENDED the trials loop"; }

diag "temp dir: $tmpdir ..." if exists($ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}) && $ENV{'PERL_TEST_TEMPDIR_TINY_NOCLEANUP'}>0;

if( $DIAG_verbose > 0 ){ diag "cleaned up"; }

done_testing;

if( $DIAG_verbose > 0 ){ diag "done testing called."; }

# this reduces the number of digits to floats so that
# their comparison does not fail because of last-digit difference
# because of rounding and representation errors etc.
# so 0.191891717171 becomes 0.1918 ONLY
sub fix_scalar {
	#return $_[0]; # short-circuit it, no need to fix anything
	my $instr = $_[0];
	$instr =~ s/^(['"]?)(\d+)\.\d{4}\d+(['"]?)$/$1$2$3/g;
	return $instr;
}

sub fix_recursively {
	my $item = $_[0];
	${$_[1]}++;
	if( $DIAG_verbose > 0 ){ diag "fix_recursively : called for depth ".${$_[1]}." ..."; }
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
	if( $DIAG_verbose > 0 ){ diag "fix_recursively : ENDED"; }
}

sub patched_generate_scalar {
    my $self = shift;

    my $type_count = scalar @{$self->{_scalar_types}};
    my $type = $self->{_scalar_types}[int(rand($type_count))];
 
    if ( $type eq 'float' ) {
        # this is the only change, reduce the number of digits and hope for the best
        return (1000+int(rand(1_000_000)))/1_000.0;
    }
    elsif ( $type eq 'integer' ) {
        return int(rand(1_000_000));
    }
    elsif ( $type eq 'string' ) {
        return scalar(Data::Random::Structure::rand_chars( set => 'all', min => 6, max => 32 ));
    }
    elsif ( $type eq 'bool' ) {
        return (rand(1) < 0.5) ? 1 : 0;
    }
    else {
        die "I don't know how to generate $type\n";
    }
}
