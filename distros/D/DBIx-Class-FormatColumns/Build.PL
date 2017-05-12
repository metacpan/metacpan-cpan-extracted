use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'DBIx::Class::FormatColumns',
    requires           => {
        'DBIx::Class' => 0.00,
        'DateTime::Format::DBI' => '0.031',
        'HTML::Entities' => '1.35',
    },
    reccomends         => {},
    create_readme      => 1,
    sign               => 0,
);
$build->create_build_script;
