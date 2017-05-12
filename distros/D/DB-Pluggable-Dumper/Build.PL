use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'DB::Pluggable::Dumper',
    license            => 'perl',
    dist_author        => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from  => 'lib/DB/Pluggable/Dumper.pm',
    requires           => { 'DB::Pluggable' => '1.100851', },
    build_requires     => { 'Test::More' => 0, },
    add_to_cleanup     => ['DB-Pluggable-Dumper-*'],
    create_makefile_pl => 'traditional',
    meta_merge        => {
        resources =>
          { repository => 'http://github.com/Ovid/DB-Pluggable-Dumper', },
    },
);

$builder->create_build_script();
