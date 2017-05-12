#!perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_license => 1,
    create_readme  => 1,
    dist_abstract  => 'Browse and search CPAN locally',
    dist_author    => 'Leon Brocard <acme@astray.com>',
    license        => 'perl',
    meta_merge     => {
        resources => {

#            bugtracker => {
#                mailto => 'bug-JSON-YAJL@rt.cpan.org',
#                web => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPAN-Mirror-Finder',
#            },
            homepage => 'http://search.cpan.org/dist/CPAN-Webserver/',

       #            repository => {
       #                type => 'git',
       #                web  => 'git@github.com:acme/CPAN-Mirror--Finder.git',
       #                url  => 'https://github.com/acme/CPAN-Mirror-Finder',
       #            },
        },
    },
    'meta-spec' => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    module_name => 'CPAN::Webserver',
    requires =>
        { 'CPAN::Mirror::Finder' => 0, 'LWP' => 0, 'Path::Class' => 0 },
    sign => 1,
);
$build->create_build_script;
