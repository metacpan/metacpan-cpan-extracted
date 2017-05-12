#!perl
use strict;
use warnings;
use lib qw(inc);
use Module::Build;
use Devel::CheckLib;

check_lib_or_exit( lib => [qw(archive)] );

my $build = Module::Build->new(
    build_requires => { 'ExtUtils::CBuilder' => 0 },
    create_license => 1,
    create_readme  => 1,
    dist_abstract =>
        'Peek into archives without extracting them (using libarchive)',
    dist_author        => 'Leon Brocard <acme@astray.com>',
    extra_linker_flags => ['-larchive'],
    license            => 'perl',
    meta_merge         => {
        resources => {
            homepage =>
                'http://search.cpan.org/dist/Archive-Peek-Libarchive/',
        },
    },
    'meta-spec' => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    module_name    => 'Archive::Peek::Libarchive',
    needs_compiler => 1,
    requires       => { 'Object::Tiny' => 0, 'Test::More' => 0 },
    sign           => 1,
);
$build->create_build_script;
