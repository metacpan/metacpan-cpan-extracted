
use Module::Build;
my $build = Module::Build->new(
	module_name => 'CGI::Application::Plugin::PageBuilder',
	license => 'perl',
    dist_version_from => 'lib/CGI/Application/Plugin/PageBuilder.pm',
	requires => {
		CGI::Application => '4',
	},
    configure_requires => {
        'Module::Build' => 0,
    },
);

$build->create_build_script();

