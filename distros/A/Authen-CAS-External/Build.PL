use 5.00;
use strict;
use warnings 'all';

use Module::Build 0.31;

my $build = Module::Build->new(
	module_name => 'Authen::CAS::External',
	license     => 'perl',
	dist_author => 'Douglas Christopher Wilson <doug@somethingdoug.com>',

	meta_merge => {
		resources => {
			homepage   => 'http://github.com/dougwilson/perl5-authen-cas-external/',
			repository => 'git://github.com/dougwilson/perl5-authen-cas-external.git',
		},
		no_index => {
			directory => [qw/inc t xt/],
		},
	},

	# Module that are required for tests in t/
	build_requires => {
		'Test::More'     => 0,
		'Test::Requires' => '0.02',
	},

	# Module that are required
	requires => {
		'perl'                      => '5.008001',
		'HTML::Form'                => '5.817',
		'HTML::TokeParser'          => '3.00',
		'HTTP::Status'              => '5.817',
		'LWP::UserAgent'            => '5.819',
		'Moose'                     => '0.89',
		'Moose::Role'               => '0.89',
		'MooseX::StrictConstructor' => '0.08',
		'MooseX::Types'             => '0.08',
		'MooseX::Types::Moose'      => 0,
		'MooseX::Types::URI'        => 0,
		'Scalar::Util'              => '1.14',
		'URI'                       => '1.22',
		'URI::QueryParam'           => 0,
		'namespace::clean'          => '0.04',
	},

	# Enable tests to be in multi-level directories
	recursive_test_files => 1,

	# Create a LICENSE file
	create_license => 1,

	test_files => 't/*.t xt/*.t',
);

$build->create_build_script;
