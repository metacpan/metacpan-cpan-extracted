use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Data::Generate',
	license             => 'artistic',
	dist_author         => 'Davide Conti <daconti.mail@gmail.com>',
	dist_abstract       => 'Generate data arrays by parsing user statements',
	create_readme       => 0,
	requires            => {
		'Test::More'              => 0.47,
		'Parse::RecDescent'       => 1.94,
		'Date::Parse'             => 0,
		'Date::DayOfWeek'         => 0,
		'perl'                    => '0.005',
	},
);

$builder->create_build_script();
