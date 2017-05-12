use Module::Build;

Module::Build->new(
    module_name => 'Data::FormValidator::Filters::HTMLStrip',
    license => 'perl',
    requires => {
        'Data::FormValidator' => 0,
        'CGI' => 0,
		'HTML::Strip' => 0,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    dist_author => 'David Baxter <david@sitesuite.com.au>',
    dist_abstract => 'Filter that removes HTML tags from input',
)->create_build_script;

