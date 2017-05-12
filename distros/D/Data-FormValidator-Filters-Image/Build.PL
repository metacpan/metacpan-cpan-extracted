use Module::Build;

Module::Build->new(
    module_name => 'Data::FormValidator::Filters::Image',
    license => 'perl',
    requires => {
        'Data::FormValidator' => 0,
        'Image::Magick' => 0,
        'MIME::Types' => 0,
        'CGI' => 0,
        'File::Basename' => 0,
        'File::Spec' => 0,
    },
    build_requires => {
        'HTTP::Request::Common' => 0,
        'Image::Size' => 0,
        'IO::Scalar' => 0,
        'File::Slurp' => 0,
    },
    create_makefile_pl => 'traditional',
    create_readme => 1,
    dist_author => 'Cees Hek <ceeshek@gmail.com>',
    dist_abstract => 'Filter that allows you to shrink incoming image uploads when using Data::FormValidator',
)->create_build_script;

