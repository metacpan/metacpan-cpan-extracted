use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Bot::Babelfish',
    license             => 'perl',
    dist_author         => 'Sébastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Bot/Babelfish.pm',
    requires => {
        'Bot::BasicBot' => '0.5',
        'Carp' => '0',
        'Encode' => '0',
        'I18N::LangTags' => '0',
        'Lingua::Translate' => '0',
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Bot-Babelfish-*' ],
);

$builder->create_build_script();
