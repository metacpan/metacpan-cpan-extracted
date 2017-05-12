use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => 'CGI::Scriptpaths',
   VERSION_FROM => 'lib/CGI/Scriptpaths.pm',
   PREREQ_PM => {
      Cwd => 0,
      'Cwd::Ext' => '1.03',
      Carp => 0,
   },
);
