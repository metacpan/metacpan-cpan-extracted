use strict;
use warnings;
use Module::Build 0.4004;

my @authors =
    map { ( my $mail = lc ) =~ tr/a-z/./cs; "$_ <$mail\@apa.at>" }
    ( 'Andreas Mager', 'Christian Eder', );

my $builder = Module::Build->new(
    module_name       => 'Date::Extract::DE',
    license           => 'gpl2',
    dist_author       => \@authors,
    dist_abstract     => 'extract dates from german texts',
    dist_version_from => 'lib/Date/Extract/DE.pm',
    requires          => {
        'perl'                   => '5.12.0',
        'version'                => '0.77',
        'Moose'                  => '0.64',
        'MooseX::ClassAttribute' => 0,
        'namespace::autoclean'   => '0.05',
        'Date::Range'            => 0,
        'Date::Simple'           => 0,
        'DateTime'               => 0,
        'DateTime::Incomplete'   => 0,
        'Regexp::Assemble'       => '0.38',
    },
    configure_requires => {
        'Module::Build' => 0.4004    # support for test_requires
    },
    test_requires  => { 'Test::More' => 0, },
    add_to_cleanup => [ 'Date-Extract-DE-*', ],
    meta_merge     => {
        resources => {
            repository => 'https://github.com/apa-it/date-extract-de',
            bugtracker => 'https://github.com/apa-it/date-extract-de/issues',
        }
    },
);

$builder->create_build_script();
