use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'DBIx::Class::ForceUTF8',
    'VERSION_FROM' => 'lib/DBIx/Class/ForceUTF8.pm', # finds $VERSION
    'PREREQ_PM' => {
        DBIx::Class => '0',
        Test::More => 0.32
    },
);
