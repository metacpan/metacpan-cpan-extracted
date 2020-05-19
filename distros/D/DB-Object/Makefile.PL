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
        'Test::More'		=> '1.302162',
        'Test::Pod'			=> '1.52',
        'strict'			=> 0,
        'parent'			=> 0,
        'version'			=> 0,
        'common::sense'		=> '3.74',
        ## We don't directly need Devel::Declare, but TryCatch requires it, and newer version breaks TryCatch
        'Devel::Declare'    => '<= 0.006019',
        'Module::Generic'	=> '0.11.6',
        'IO::File'			=> 0,
        'Fcntl'				=> 0,
        'File::Spec'		=> '3.78',
        'Scalar::Util'		=> '1.54',
        'DBI'				=> '1.643',
        'JSON'				=> '4.02',
        'POSIX'				=> '1.88',
        'Want'				=> '0.29',
        'Devel::Confess'	=> '0.009004',
        'TryCatch'			=> '1.003002',
        'DateTime'			=> '1.51',
        'DateTime::TimeZone' => '2.36',
        'DateTime::Format::Strptime' => '1.76',
        'Net::IP'			=> '1.26',
        'File::Basename'	=> '2.85',
        'Number::Format'	=> '1.75',
        'Class::Struct'		=> '0.65',
        'IO::Dir'			=> 0,
        'URI'				=> '1.76',
    },
    LICENSE				=> 'perl_5',
    MIN_PERL_VERSION	=> 5.6.0,
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
        #    homepage    => undef,
            repository  => {
                url         => 'git@git.deguest.jp:jack/DB-Object.git',
                web         => 'https://git.deguest.jp/jack/DB-Object',
                type        => 'git',
            },
        #    bugtracker => {
        #        web         => undef,
        #    },
        },
    })),
);

WriteMakefile(%WriteMakefileArgs);
