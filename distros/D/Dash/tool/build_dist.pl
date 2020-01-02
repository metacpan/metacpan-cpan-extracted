#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use 5.010;
use JSON;
use Path::Tiny;
use Const::Fast;

const my $dash_renderer_package_name => 'dash_renderer';

const my $dash_component_packages => [ qw(
    dash-core-components
    dash-html-components
    dash-table
    ) ];

# TODO dash path from command line
# TODO version from command line
# TODO pull repo to find tag version


my $dash_path = path('..', 'dash');
my $dist_share_js = path('share/assets');

# Generate componentes

# "Inject" perl generation files
my $python_folder_destination = $dash_path->child('dash')->child('development');

my $distro_python_patched_files = path('tool', 'python');
# Only works for $python_folder_destination
$distro_python_patched_files->visit(sub {
        $_->copy($python_folder_destination) if /\.py$/;
    },
    {recurse => 1}
);


# Dash Renderer
my $dash_venv_path = $dash_path->child('.venv')->child('dev')->child('bin')->child('activate');
my $dash_renderer_path = $dash_path->child('dash-renderer');
my $dash_renderer_assets = $dash_renderer_path->child('dash_renderer');
$dash_renderer_assets->visit(sub {
        $_->remove() if /\.js$/ || /\.map$/;
    });
#$dash_renderer_path->child('node_modules')->remove_tree(); # This usually fail with the folder .cache

system("source $dash_venv_path; cd $dash_renderer_path; renderer build");

my $dist_share_js_renderer = $dist_share_js->child('dash_renderer');
$dist_share_js_renderer->remove_tree();
$dist_share_js_renderer->mkpath();
# TODO LICENSE files and source maps
for my $js_file ($dash_renderer_assets->children(qr/\.js$/)) {
    $js_file->copy($dist_share_js_renderer);
}

my $python_script_extract_renderer_js_deps = path('tool', 'python', 'aux_dash_renderer.py');
my $dash_renderer_deps_path = $dist_share_js_renderer->child('js_deps.json');

# TODO extract js_deps.json into Dash::Renderer using aux_dash_renderer.py
system("source $dash_venv_path; python $python_script_extract_renderer_js_deps > $dash_renderer_deps_path");

for my $component_suite (@$dash_component_packages) {
    print "Building $component_suite <============================================================>\n";
    # TODO pull repo

    my $component_suite_path = path('..', $component_suite);
    # Install js deps
    system("cd $component_suite_path; npm ci");
    #system("cd $component_suite_path; npm update");

    system("source $dash_venv_path; cd $component_suite_path; npm run build");

    my $perl_base_path = $component_suite_path->child('Perl');

    my $component_suite_assets_directory_name = $component_suite;
    $component_suite_assets_directory_name =~ s/-/_/g;
    my $component_suite_assets_path = $dist_share_js->child($component_suite_assets_directory_name);
    $component_suite_assets_path->remove_tree();
    $component_suite_assets_path->mkpath();

    $perl_base_path->child('js_deps.json')->copy($component_suite_assets_path);

    # TODO LICENSE files
    for my $js_file ($perl_base_path->child('deps')->children()) {
        $js_file->copy($component_suite_assets_path);
    }

    my $component_suite_package_files_directory = path('lib', map {ucfirst } split(/-/, $component_suite));
    $component_suite_package_files_directory->remove_tree();
    $component_suite_package_files_directory->mkpath();
    for my $pm_file ($perl_base_path->child($component_suite_assets_directory_name)->children(qr/\.pm$/)) {
        $pm_file->copy($component_suite_package_files_directory);
    }
}

# TODO Automatic Components.pm generation


