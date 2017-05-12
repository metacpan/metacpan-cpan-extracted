#! perl
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
	module_name => 'Algorithm::RabinKarp',
	dist_author => 'Norman Nunley <nnunley@gmail.com>',
	dist_abstract => 'An implementation of the Rabin-Karp rolling hash algorithm',
        license => 'perl',
        create_makefile_pl => 'traditional',
	requires => {
		perl => '>=5.006',
	},
	recommends => {
		bignum => undef,
		'Test::Exception' => 0,
		'Smart::Comments' => 0,
	},
	build_requires => {
		'Test::More' => 0,
		'File::Temp' => 0,
	},
	script_files => [
		'rabin.pl'
	]
);

$build->create_build_script();
