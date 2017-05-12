#!perl

use strict;
use warnings FATAL => 'all';

use English qw( -no_match_vars );    # Avoids regex performance penalty
local $OUTPUT_AUTOFLUSH = 1;

use Test::More tests => 46;

BEGIN {
	use_ok('App::Midgen');
	use_ok('App::Midgen::Role::Attributes');
	use_ok('App::Midgen::Role::AttributesX');
	use_ok('App::Midgen::Role::Eval');
	use_ok('App::Midgen::Role::Experimental');
	use_ok('App::Midgen::Role::FindMinVersion');
	use_ok('App::Midgen::Role::Heuristics');
	use_ok('App::Midgen::Role::InDistribution');
	use_ok('App::Midgen::Role::Options');
	use_ok('App::Midgen::Role::TestRequires');
	use_ok('App::Midgen::Role::UseModule');
	use_ok('App::Midgen::Role::UseOk');
	use_ok('App::Midgen::Role::Output');
	use_ok('App::Midgen::Role::Output::CPANfile');
	use_ok('App::Midgen::Role::Output::Dist');
	use_ok('App::Midgen::Role::Output::EUMM');
	use_ok('App::Midgen::Role::Output::Infile');
	use_ok('App::Midgen::Role::Output::MB');
	use_ok('App::Midgen::Role::Output::METAjson');
	use_ok('App::Midgen::Role::Output::MIdsl');
	use_ok('App::Midgen::Role::Output::MI');

	use_ok('Carp',                 '1.3301');
	use_ok('Cwd',                  '3.47');
	use_ok('Data::Printer',        '0.35');
	use_ok('File::Slurp::Tiny',    '0.003');
	use_ok('File::Spec',           '3.47');
	use_ok('Getopt::Long',         '2.42');
	use_ok('JSON::Tiny',           '0.49');
	use_ok('List::MoreUtils',      '0.33');
	use_ok('MetaCPAN::Client',     '1.003000');
	use_ok('Module::CoreList',     '3.1');
	use_ok('Moo',                  '1.004005');
	use_ok('PPI',                  '1.215');
	use_ok('Perl::MinimumVersion', '1.37');
	use_ok('Perl::PrereqScanner',  '1.019');
	use_ok('Pod::Usage',           '1.63');
	use_ok('Term::ANSIColor',      '4.03');
	use_ok('Tie::Static',          '0.04');
	use_ok('Time::Stamp',          '1.3');
	use_ok('Try::Tiny',            '0.22');
	use_ok('Type::Tiny',           '0.042');
	use_ok('constant',             '1.27');

#  use_ok('lib',                  '0.63');
	use_ok('version', '0.9908');

	use_ok('Test::CheckDeps', '0.01');
	use_ok('Test::More',      '1.001003');
	use_ok('Test::Requires',  '0.07');
}

diag("Testing App::Midgen v$App::Midgen::VERSION");

done_testing();

__END__
