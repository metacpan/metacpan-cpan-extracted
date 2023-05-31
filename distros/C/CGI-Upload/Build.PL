use Module::Build;
my $build = Module::Build->new
(
	module_name         => 'CGI::Upload',
	license             => 'perl',
	dist_author         => 'Rob Casey <rob.casey@bluebottle.com>',
	dist_abstract       => 'CGI class for handling browser file uploads',
	create_makefile_pl  => 'traditional',
	create_readme       => 1,
	requires            => {
		'CGI'                   => 2.47, 
		'File::MMagic'          => 1.16,
		'HTTP::BrowserDetect'   => 0.97,
		'Test::More'            => 0,
		'Carp'                  => 0,
	},
    meta_merge => {
        resources => {
            repository => 'https://github.com/szabgab/CGI-Upload/',
            bugtracker => 'https://github.com/szabgab/CGI-Upload/issues'
        }
    },
);

$build->create_build_script;

