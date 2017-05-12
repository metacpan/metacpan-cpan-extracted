use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
  NAME         => 'Data::Compare',
  META_MERGE => {
    license => 'other',
    resources => {
      repository => 'https://github.com/DrHyde/perl-modules-Data-Compare',
      bugtracker => 'https://github.com/DrHyde/perl-modules-Data-Compare/issues/new'
    },
  },
  VERSION_FROM => "lib/Data/Compare.pm",
  PREREQ_PM    => {
    File::Find::Rule => 0.10,
    Scalar::Util     => 0
  },
  clean        => { FILES => '*.bak *.old mibs/*.dump lib/*/*~' },
);
