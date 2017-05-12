use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'CGI::FileManager',
	license             => 'perl',
	dist_author         => 'Gabor Szabo <gabor@pti.co.il>',
	dist_abstract       => 'Managing a directory structure on an HTTP server',
	create_makefile_pl  => 'passthrough',
	create_readme       => 1,
	script_files        => ['bin/cfm-passwd.pl', 'bin/cfm-install.pl'],
	requires            => {
		'Test::More'                        => '0.47',
		'Test::Warn'                        => '0',
		'CGI::Application'                  => '3.31',
		'CGI::Application::Plugin::Session' => '0.03',
		'HTML::Template'                    => '2.6',
		'CGI::Upload'                       => '1.10',
#		'Unix::PasswdFile'                  => '0',
		'Unix::ConfigFile'                  => '0.06',
	},
);

system "$^X bin/cfm-install.pl --force";

$builder->create_build_script();
