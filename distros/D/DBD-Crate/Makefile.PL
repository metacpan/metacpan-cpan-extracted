use strict;
use 5.010001;
use ExtUtils::MakeMaker;
use DBI;
use DBI::DBD;

WriteMakefile(
    dbd_edit_mm_attribs({
        NAME              => 'DBD::Crate',
        VERSION_FROM      => 'lib/DBD/Crate.pm',
        ABSTRACT_FROM     => 'lib/DBD/Crate.pm',
        CONFIGURE_REQUIRES => {
            'DBI'               => 1.50,
        },
        PREREQ_PM         => {
            'DBI'               => 1.50,
            'HTTP::Tiny'        => 0.055,
            'JSON::MaybeXS'     => 1.003003,
            'Test::More'        => 0,
            'Digest::SHA1'      => 0,
        },
        LICENSE        => 'perl',
        AUTHOR         => 'Mamod Mehyar <mamod.mehyar@gmail.com>',
        "TEST_REQUIRES" => {},
        META_MERGE => {
            resources => {
                repository => 'git://github.com/mamod/DBD-Crate.git',
                bugtracker => 'https://github.com/mamod/DBD-Crate/issues',
            }
        }
    },
    { create_pp_tests => 1})
);

sub MY::postamble {
    return DBI::DBD::dbd_postamble(@_);
}
