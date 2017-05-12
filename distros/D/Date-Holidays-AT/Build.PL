use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Date::Holidays::AT',
    license           => 'perl',
    dist_author       => 'Matthias Dietrich <perl@rainboxx.de>',
    dist_version_from => 'lib/Date/Holidays/AT.pm',
    build_requires    => {
                  'Date::Calc' => '5.0',
                  'Test::More' => 0,
                  'version'    => 0,
                },
    configure_requires => { 'Module::Build' => 0.36 },
    add_to_cleanup => ['Date-Holidays-AT-*'],
    create_makefile_pl => 'traditional',
    meta_merge => {
        resources => {
            repository => 'git://github.com/rainboxx/Date-Holidays-AT.git',
            homepage   => 'http://github.com/rainboxx/Date-Holidays-AT/',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-AT',
        }
    },
);

$builder->create_build_script();
