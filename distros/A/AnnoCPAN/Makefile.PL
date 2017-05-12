use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'AnnoCPAN',
    VERSION_FROM    => 'lib/AnnoCPAN.pm', 
    NORECURS        => 1, 
    EXE_FILES       => [qw(
        bin/ac_cpanratings
        bin/ac_recent_dists_rss
        bin/annocpan_load
        bin/annocpan_undump
        bin/create_annopod_db
    )],
    PREREQ_PM       => {
        # non-core modules
        Archive::Tar        => 0,
        Archive::Zip        => 0,
        Class::DBI          => 0,
        CPAN::DistnameInfo  => 0.06,
        DBD::SQLite         => 1.08,
        IO::String          => 0,
        String::Similarity  => 1,
        Template            => 2,
        XML::RSS            => 0,
        XML::Simple         => 0,
        XML::SAX            => 0,
        Test::Pod           => 1.20,
        Lingua::EN::Inflect => 0,
        Pod::Parser         => 1.31,

        # core 5.8 modules
        List::Util          => 0,
        Test::More          => 0,

        # core 5.6 modules
        Pod::Select         => 0,
        File::Path          => 0,
        File::stat          => 0,
        Carp                => 0,
    },
);

sub MY::postamble {
<<'EOT';
all :: tables.mysql tables.sqlite
tables.mysql: tables.tt.sql
	tpage --define db=mysql tables.tt.sql > tables.mysql
tables.sqlite: tables.tt.sql
	tpage --define db=sqlite tables.tt.sql > tables.sqlite
EOT
}
