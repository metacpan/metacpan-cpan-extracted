use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'DBIx::BLOB::Handle',
    VERSION_FROM    => 'Handle.pm',
    (
        $] >= 5.6
        ? (ABSTRACT   => 'Read Database Large Object Binaries from file handles',
           AUTHOR     => 'Mark Southern (mark_southern@merck.com)')
        : ()
    ),
    PREREQ_PM => { 
                    DBI => undef,
                 },
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
);
