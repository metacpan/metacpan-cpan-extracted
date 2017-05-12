use Module::Build;

Module::Build->new(
    'module_name' => 'Biblio::COUNTER',
    'license'     => 'perl',
    'requires'    => { 'Text::CSV' => 0, },
    'dist_author' => 'Paul Hoffman <nkuitse@cpan.org>',
)->create_build_script;

