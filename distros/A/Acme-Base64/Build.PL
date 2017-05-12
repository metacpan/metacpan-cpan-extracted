use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Acme::Base64',
    license           => 'perl',
    dist_author       => 'Alan Haggai Alavi <haggai@cpan.org>',
    dist_version_from => 'lib/Acme/Base64.pm',
    build_requires    => { 'Test::More' => 0, },
    requires          => {
        'version'        => 0,
        'MIME::Base64'   => 0,
        'Filter::Simple' => 0,
    },
    'meta_merge' => {
        'resources' => {
            'repository' =>
              'git://github.com/alanhaggai/Acme-Base64.git',
        },
    },
    add_to_cleanup => ['Acme-Base64-*'],
);

$builder->create_build_script();
