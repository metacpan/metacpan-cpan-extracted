# This is a -*- perl -*- distribution build file for Acme::Godot
#

use strict;
use warnings;
use Module::Build 0.28;

#
# For documentation on the different arguments to Module::Build->new()
# see perldoc Module::Build::API and Module::Build::Cookbook
#
my $builder = Module::Build->new(
    module_name       => 'Acme::Godot',
    license           => 'perl',
    dist_author       => 'Salve J. Nilsen <sjn@cpan.org>',
    dist_version_from => 'lib/Acme/Godot.pm',
    build_requires => {
        'Test::Exception' => 0,
    },
    build_recommends => {
        'Test::Perl::Critic' => 1,
        'Perl::Critic' => 0.18,
        'Test::Pod' => 1.14,
        'Test::Pod::Coverage' => 1.04,
        'Test::Kwalitee' => 0,
    },
    requires => {
        'perl'       => '5.5.63',         # First version with our()
        'Test::More' => 0,
        'version'    => 0.64,
    },
    add_to_cleanup => ['Acme-Godot-*'],
    create_readme  => 0,
);

$builder->create_build_script();
