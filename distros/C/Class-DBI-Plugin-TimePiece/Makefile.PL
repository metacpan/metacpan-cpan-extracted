use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Class::DBI::Plugin::TimePiece',
    VERSION_FROM      => 'lib/Class/DBI/Plugin/TimePiece.pm',
    PREREQ_PM         => {
        'Carp'        => 0,
        'Time::Piece' => 0,
    },
);
