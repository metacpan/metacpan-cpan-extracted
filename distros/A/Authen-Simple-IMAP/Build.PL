use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Authen::Simple::IMAP',
    license             => 'artistic',
    dist_author         => 'Dylan Martin <dmartin@sccd.ctc.edu>',
    dist_version_from   => 'lib/Authen/Simple/IMAP.pm',
    requires => {
		'perl'		 => '5.8.6',
        'Test::More' => 0,
        'version'    => 0,
		'Net::IMAP::Simple' => 1.17,
		'Authen::Simple' => 0,
		'Authen::Simple::Adapter' => 0,
    },
	recommends => {
		'Net::IMAP::Simple::SSL' => 0,
		'Net::IMAP::Simple::Plus' => 0,
	},
    add_to_cleanup      => [ 'Authen-Simple-IMAP-*','README' ],
	create_makefile_pl	=> 'passthrough',
	create_readme		=> 1,
);

$builder->create_build_script();
