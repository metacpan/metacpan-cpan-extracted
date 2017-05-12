use strict;

use Module::Build;

my $build = Module::Build->new(
	module_name        => 'Data::FormValidator::Constraints::HTTP',
	dist_author        => 'Adam Paynter <adapay@cpan.org>',
	license            => 'perl',
	create_readme      => 1,
	create_makefile_pl => 'traditional',
	requires           => {
        'Data::FormValidator' => '4.30',
	},
	build_requires     => {
		'Test::More'   => 0,
	},
);

$build->create_build_script;
