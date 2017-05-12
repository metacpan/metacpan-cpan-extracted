use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'DBIx::DataAudit',
    VERSION_FROM    => "lib/DBIx/DataAudit.pm", # finds $VERSION
    EXE_FILES       => ['bin/dbix-dataaudit.pl'],
    LICENSE         => 'perl',
    PREREQ_PM       => {
                         DBI => 1.38,      # for ->column_info
                         'parent'      => 0.218,
                         'Class::Accessor' => 0,
                         'Text::Table' => 0,
                         'Test::More'  => 0, # for testing, duh
                       },
);

