use strict;

use Module::Build;

my $build = Module::Build->new(
    module_name        => 'DBIx::Class::Indexer::WebService::Lucene',
    dist_author        => 'Adam Paynter <adapay@cpan.org>',
    license            => 'perl',
    create_readme      => 1,
    create_makefile_pl => 'traditional',
    requires           => {
        'DBIx::Class::Indexed' => 0,
        'Scalar::Util'         => 0,
        'WebService::Lucene'   => 0,
    },
    build_requires     => {
        'Test::More' => 0
    }
);

$build->create_build_script;
