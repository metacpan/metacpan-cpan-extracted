#!perl
use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    create_license => 1,
    create_readme  => 1,
    dist_abstract =>
        'Peek into archives without extracting them (using external tools)',
    dist_author => 'Leon Brocard <acme@astray.com>',
    license     => 'perl',
    meta_merge  => {
        resources => {
            homepage => 'http://search.cpan.org/dist/Archive-Peek-External/',
        },
    },
    'meta-spec' => {
        version => '2',
        url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
    },
    module_name => 'Archive::Peek::External',
    requires    => {
        'File::Which'                => '0',
        'IPC::Run3'                  => '0',
        'Moose'                      => '0',
        'MooseX::Types::Path::Class' => '0',
        'Test::More'                 => '0',
    },
    sign => 1,
);
$build->create_build_script;
