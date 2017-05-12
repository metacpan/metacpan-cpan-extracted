use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Data::Hexdumper',
  META_MERGE => {
    license => 'other',
    resources => {
      repository => {
        web => 'https://github.com/DrHyde/perl-modules-Data-Hexdumper'
      },
      bugtracker => {
        web => 'https://github.com/DrHyde/perl-modules-Data-Hexdumper/issues/new'
      },
    },
  },
  VERSION_FROM => 'lib/Data/Hexdumper.pm',
  PREREQ_PM    => {
    'Test::More' => 0.65,
  }
);
