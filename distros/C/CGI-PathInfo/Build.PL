use Module::Build;
my $build = Module::Build->new
      ( module_name    => 'CGI::PathInfo',
        dist_author    => 'Benjamin Franz <snowhare@nihongo.org>',
        dist_abstract  => 'A lightweight CGI processing package for using PATH_INFO like GET method form parameters',
        license        => 'perl',
        requires       => {
            'Carp'           => 0,
            'HTML::Entities' => 0,
        },
        build_requires => { },
      )->create_build_script;
