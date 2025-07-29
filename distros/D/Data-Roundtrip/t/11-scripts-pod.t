#!perl -T
use 5.008;
use strict;
use warnings;

our $VERSION='0.30';

use Test::More;
use Test2::Plugin::UTF8;
use Test::Pod;
use File::Spec;
use File::Basename;

my %SCRIPTS = (
	'script/json2json.pl' => 't-data/succeeding/test.json',
	'script/json2perl.pl' => 't-data/succeeding/test.json',
	'script/json2yaml.pl' => 't-data/succeeding/test.json',
	'script/perl2json.pl' => 't-data/succeeding/test.pl',
	'script/yaml2json.pl' => 't-data/succeeding/test.yaml',
	'script/yaml2perl.pl' => 't-data/succeeding/test.yaml',
);

#### nothing to change below
my $num_tests = 0;

my $dirname = File::Basename::dirname(__FILE__);

for my $ascriptname (sort keys %SCRIPTS){
	my $infile = File::Spec->catfile($dirname, $SCRIPTS{$ascriptname});
	ok(-f $infile, "test file exists ($infile)."); $num_tests++;
	ok(-s $infile, "test file has content ($infile)."); $num_tests++;
	pod_file_ok($ascriptname, "checking pod for script '$ascriptname'."); $num_tests++;
}
done_testing($num_tests);
