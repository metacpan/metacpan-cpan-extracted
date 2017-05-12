use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Business::Billing::TMobile::UK',
	license             => 'perl',
	dist_author         => 'Sagar R. Shah <sagarshah@softhome.net>',
	dist_version_from   => 'lib/Business/Billing/TMobile/UK.pm',
	requires            => {
		'HTML::TreeBuilder' => 0,
		'Term::ReadPassword'=> '0.06',
		'WWW::Mechanize'    => 0,
		'Crypt::SSLeay'     => 0,
		'Encode'            => 0,
	},
	build_requires      => {
		'Test::More'        => 0,
        'Devel::CheckOS'    => '1.42',
	},
	create_readme      => 1,
	scripts            => [ 'script/check_tmobile_allowances' ],
    add_to_cleanup       => [ '*.tar.gz', 'Build', '_build' ],
);

$builder->create_build_script();
