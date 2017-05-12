#! perl

use strict;
use warnings;
use Test::More 0.88;
use Test::Deep;

use CPAN::Meta 2.120920;
use CPAN::Meta::Check qw/check_requirements verify_dependencies/;

use Env ();

my %prereq_struct = (
	runtime => {
		requires => {
			'Config'     => 0,
			'File::Spec' => 0,
			'IO::File'	 => 0,
			'perl'			 => '5.005_03',
		},
		recommends => {
			'Pod::Text' => 0,
			'This::Should::Be::NonExistent' => 1,
			Env => 99999,
		},
		conflicts => {
			'CPAN::Meta' => '<= 100.0',										# check should fail
			'Test::Deep' => '== ' . Test::Deep->VERSION,	# check should fail
			'Test::More' => '<= 0.01',										# check should pass (up to 0.01 is bad)
    },
	},
	build => {
		requires => {
			'Test' => 0,
		},
	},
);

my $meta = CPAN::Meta->create({ prereqs => \%prereq_struct, version => 1, name => 'Foo'  }, { lazy_validation => 1 });

cmp_deeply([ verify_dependencies($meta, 'runtime', 'requires') ], [], 'Requirements are verified');

my $pre_req = $meta->effective_prereqs->requirements_for('runtime', 'requires');
is($pre_req->required_modules, 4, 'Requires 4 modules');
cmp_deeply(check_requirements($pre_req, 'requires'), { map { ( $_ => undef ) } qw/Config File::Spec IO::File perl/ }, 'Requirements are satisfied ');

my $pre_rec = $meta->effective_prereqs->requirements_for('runtime', 'recommends');
cmp_deeply([ sort +$pre_rec->required_modules ], [ qw/Env Pod::Text This::Should::Be::NonExistent/ ], 'The right recommendations are present');
cmp_deeply(check_requirements($pre_rec, 'recommends'), {
		Env => "Installed version ($Env::VERSION) of Env is not in range '99999'",
		'Pod::Text' => undef,
		'This::Should::Be::NonExistent' => 'Module \'This::Should::Be::NonExistent\' is not installed',
	}, 'Recommendations give the right errors');

my $pre_con = $meta->effective_prereqs->requirements_for('runtime', 'conflicts');
cmp_deeply([ sort +$pre_con->required_modules ], [ qw/CPAN::Meta Test::Deep Test::More/ ], 'The right conflicts are present');
cmp_deeply(check_requirements($pre_con, 'conflicts'), {
		'CPAN::Meta' => re(qr/Installed version \([\d._]+\) of CPAN::Meta is in range '<= 100.0'/),
		'Test::More' => undef,
		'Test::Deep' => re(qr/Installed version \([\d._]+\) of Test::Deep is in range '== $Test::Deep::VERSION'/),
	}, 'Conflicts give the right errors');

done_testing();
# vi:noet:sts=2:sw=2:ts=2
