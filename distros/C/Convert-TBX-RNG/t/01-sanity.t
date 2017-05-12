#make sure that the core structure RNG validates a TBX file
use strict;
use warnings;
use Test::More 0.88;
plan tests => 3;
use Test::NoWarnings;
use Convert::TBX::RNG qw(core_structure_rng);
use TBX::Checker qw(check);
use Path::Tiny;
use FindBin qw($Bin);
use File::Slurp;
use XML::LibXML;
use Try::Tiny;

my $corpus_dir = path($Bin, 'corpus');
my $min_tbx = path($corpus_dir, 'min.tbx');
my $tbx_basic_sample = path($corpus_dir, 'TBX-basic-sample.tbx');

my $rng = XML::LibXML::RelaxNG->new(
	string => ${ core_structure_rng() });

subtest 'Correct validation of minimal TBX file' => sub {
	plan tests => 2;
	my ($valid, $messages) = check($min_tbx);
	ok($valid, 'TBXChecker')
		or note explain $messages;

	try{
		my $doc = XML::LibXML->load_xml(location => $min_tbx);
		$rng->validate($doc);
	}catch{
		fail("Error validating minimal TBX with core RNG: $_");
		return;
	};
	pass('No error validating minimal TBX with core RNG');
};

subtest 'Correct validation of TBX-basic file' => sub {
	plan tests => 2;
	my ($valid, $messages) = check($tbx_basic_sample);
	ok($valid, 'TBXChecker')
		or note explain $messages;

	try{
		my $doc = XML::LibXML->load_xml(location => $tbx_basic_sample);
		$rng->validate($doc);
	}catch{
		fail("Error validating TBX-Basic with core RNG: $_");
		return;
	};
	pass('No error validating TBX-Basic with core RNG');
};

