use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Coat::Persistent',
    AUTHOR       => 'Alexis Sukrieh (sukria) <sukria@cpan.org>',
    LICENSE      => 'perl',
    VERSION_FROM => 'lib/Coat/Persistent.pm',
    ABSTRACT     => "ORM based on the Moose-like engine `Coat'",
    PREREQ_PM    => {
        'Coat'           => '0.334',
        'DBI'            => '0',
        'DBIx::Sequence' => '0',
        'Class::Date'    => '0', # For the types defined 
        'DBD::CSV'       => '0', # needed for the test suite
        'SQL::Abstract'  => '0',
        'List::Compare'  => '0',
        'Test::Database' => '0',
    },
    test  => {TESTS => join( ' ', (glob( 't/*.t'), glob('t/*/*.t')))},
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 't/csv-test-database'},
);
