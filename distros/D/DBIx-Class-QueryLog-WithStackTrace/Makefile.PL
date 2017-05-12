use ExtUtils::MakeMaker;
WriteMakefile(
  NAME  => 'DBIx::Class::QueryLog::WithStackTrace',
  META_MERGE => {
    license => 'other',
    resource => {
      repository => 'https://github.com/DrHyde/perl-modules-DBIx-Class-QueryLog-WithStackTrace'
    }
  },
  VERSION_FROM => 'lib/DBIx/Class/QueryLog/WithStackTrace.pm',
  PREREQ_PM => {
    'Devel::StackTrace'     => 1.21,
    'Moose'                 => 0.90,
    'DBIx::Class::QueryLog' => 1.003002,
    # and for testing ...
    'File::Temp'            => 0,
    'DBI'                   => 0,
    'DBD::SQLite'           => 0,
    'DBIx::Class'           => 0
  }
);
