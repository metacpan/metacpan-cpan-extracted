use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Validation::Automation',
    license             => 'perl',
    dist_author         => q{Varun Juyal <varunjuyal123@yahoo.com>},
    dist_abstract       => q{A Validation Framework for Web and Unix Centric Applications},
    dist_version_from   => 'lib/App/Validation/Automation.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'                   => '5.8.8',
        'Moose'                  => '2.0205',
        'Net::SSH::Perl'         => '1.34',
        'WWW::Mechanize'         => '1.70',
        'Config::Simple'         => '4.58',
        'Error::TryCatch'        => '0.07',
        'Crypt::Lite'            => '0.82.11',
        'namespace::autoclean'   => '0.13',
        'HTML::Form::ForceValue' => '0.007',
        'Mail::Sendmail'         => '0.79',
        'Data::Dumper'           => '2.121_08',
        'Carp'                   => 0,
        'English'                => 0,
        'Getopt::Long'           => 0,
        'File::Basename'         => 0,
        'File::Path'             => 0,
        'Switch'                 => 0,
    },
    add_to_cleanup      => [ 'App-Validation-Automation-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
