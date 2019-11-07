use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
  NAME         => 'Data::Compare',
  MIN_PERL_VERSION => 5.006,
  META_MERGE => {
    license => ["artistic_1", "gpl_2"],
    resources => {
      repository => 'https://github.com/DrHyde/perl-modules-Data-Compare',
      bugtracker => 'https://github.com/DrHyde/perl-modules-Data-Compare/issues'
    },
  },
  BUILD_REQUIRES => { "ExtUtils::MakeMaker" => 6.48 },
  VERSION_FROM => "lib/Data/Compare.pm",
  PREREQ_PM    => {
    File::Find::Rule => 0.10,
    Scalar::Util     => 0,
    Clone            => 0.43,
    Test::More       => 0.88, # done_testing
  },
  clean        => { FILES => '*.bak *.old mibs/*.dump lib/*/*~' },
);
