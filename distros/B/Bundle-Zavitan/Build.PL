use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
    module_name	   => 'Bundle::Zavitan',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    requires =>
    {
        'CGI' => 0,
        'Crypt::Blowfish' => 0,
        'Data::Dumper' => 0,
        'Date::DayOfWeek' => 0,
        'Date::Parse' => 0,
        'DBI' => 0,
        'DBD::mysql' => 0,
        'Math::BigInt' => 0,
        'MIME::Base64' => 0,
        'Net::SMTP' => 0,
        'Time::DaysInMonth' => 0,
        'perl' => '5.008',
        'strict' => 0,
        'vars' => 0,
        'warnings' => 0,
    },
    license => "mit",
    meta_merge =>
    {
        resources =>
        {
            repository => "https://bitbucket.org/shlomif/zavitan-a-seminars-manager",
        },
    },
);

$build->create_build_script;
