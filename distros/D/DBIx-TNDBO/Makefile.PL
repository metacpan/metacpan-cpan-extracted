use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'DBIx::TNDBO',
    VERSION_FROM => 'lib/DBIx/TNDBO.pm',    # finds $VERSION
    PREREQ_PM    => {
        'Data::Dumper'   => '2.131',
        'Readonly'       => '1.03',
        'DBI'            => '1.6',
        'SQL::Abstract'  => '1.6',
        'Storable'       => '2.23',
        'File::Spec'     => '3.33',
        'Filter::Simple' => '0.88',
    },                                      # e.g., Module::Name => 1.1
    (   $] >= 5.005
        ? ( ABSTRACT_FROM => 'lib/DBIx/TNDBO.pod',
            AUTHOR        => 'Dylan Doxey <dylan@cpan.org>'
            )
        : ()
    ),
);
