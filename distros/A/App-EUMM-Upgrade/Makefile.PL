require 5.006;
use ExtUtils::MakeMaker;
WriteMakefile1(
  'NAME' => 'App::EUMM::Upgrade',
  'VERSION_FROM' => 'lib/App/EUMM/Upgrade.pm',
  'ABSTRACT_FROM' => 'lib/App/EUMM/Upgrade.pm',
  'AUTHOR' => q{Alexandr Ciornii <alexchorny@gmail.com>},
  'CONFIGURE_REQUIRES' => {
                   'ExtUtils::MakeMaker' => '6.56',
  },
  'PREREQ_PM' => {
                   'ExtUtils::MakeMaker' => '6.56',
                   'File::Slurp' => 0,
                   'Github::Fork::Parent' => '0.24',
                   'Perl::Meta' => '0.03',
                   'Text::FindIndent' => '0.08',
  },
  TEST_REQUIRES => {
                   'Test::More' => '0.88',
  },
  LICENSE => 'gpl_3',
  MIN_PERL_VERSION => '5.006',
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'git://github.com/chorny/EUMM-upgrade.git',
        web => 'https://github.com/chorny/EUMM-upgrade',
      },
    },
    keywords => [
      'development','upgrade','EU::MM','Makefile.PL',
    ],
  },
  'INSTALLDIRS' => 'site',
  'EXE_FILES' => [
                   'eumm-upgrade.pl'
                 ],
  'PL_FILES' => {},
  $^O =~/win/i ? (
    dist => {
      TAR      => 'ptar',
      TARFLAGS => '-c -C -f',
    },
  ) : (),
)
;

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
  my %params=@_;
  my $eumm_version=$ExtUtils::MakeMaker::VERSION;
  $eumm_version=eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
    $params{META_ADD}->{author}=$params{AUTHOR};
    $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
  }
  if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
    $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
    delete $params{TEST_REQUIRES};
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;

  WriteMakefile(%params);
}
