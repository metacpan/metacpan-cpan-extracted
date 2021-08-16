use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'DB::Object',
    VERSION_FROM        => 'lib/DB/Object.pm',
    AUTHOR              => 'Jacques Deguest (jack@deguest.jp)',
    ABSTRACT            => 'A SQL Database object abstraction class',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'strict'			=> 0,
        'parent'			=> 0,
        'version'			=> 0,
        'common::sense'		=> '3.74',
        'Class::Struct'		=> '0.65',
        'DateTime'			=> '1.51',
        'DateTime::Format::Strptime' => '1.76',
        'DateTime::TimeZone' => '2.36',
        'DBI'				=> '1.643',
        'Devel::Confess'	=> '0.009004',
        'Fcntl'				=> 0,
        'File::Basename'	=> '2.85',
        'File::Spec'		=> '3.75',
        'IO::Dir'			=> 0,
        'IO::File'			=> 0,
        'JSON'				=> '4.02',
        'Module::Generic'   => 'v0.12.14',
        'Net::IP'			=> '1.26',
        'Nice::Try'			=> 'v0.1.3',
        'Number::Format'	=> '1.75',
        'POSIX'				=> '1.53_01',
        'Scalar::Util'		=> '1.54',
        'URI'				=> '1.76',
        'Want'				=> '0.29',
    },
    TEST_REQUIRES =>
    {
        'Test::More'		=> '1.302162',
        'Test::Pod'			=> '1.52',
    },
    LICENSE				=> 'perl_5',
    MIN_PERL_VERSION	=> 'v5.16.0',
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/DB-Object.git',
                web         => 'https://git.deguest.jp/jack/DB-Object',
                type        => 'git',
            },
            bugtracker => {
                web         => 'https://git.deguest.jp/jack/DB-Object/issues',
            },
        },
    }) : ()),
);

WriteMakefile(%WriteMakefileArgs);
