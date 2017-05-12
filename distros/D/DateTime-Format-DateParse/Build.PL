use Module::Build;

Module::Build->new(
    module_name         => 'DateTime::Format::DateParse',
    dist_version_from   => 'lib/DateTime/Format/DateParse.pm',
    author              => 'Joshua Hoblitt <jhoblitt@cpan.org>',
    license             => 'perl',
    create_makefile_pl  => 'passthrough',
    create_readme       => 1,
    requires            => {
        'DateTime'              => '0.29',
        'DateTime::TimeZone'    => '0.27',
        'Date::Parse'           => '2.27',
        'Time::Zone'            => '2.22',
    },
)->create_build_script;
