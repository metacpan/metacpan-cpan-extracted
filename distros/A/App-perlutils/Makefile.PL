use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile1(
  META_MERGE => {
    q(meta-spec) => { version => 2 },
    resources => {
      repository => {
        type       => 'git',
        url        => 'https://github.com/trapd00r/perlutils.git',
        web        => 'https://github.com/trapd00r/perlutils',
        bugtracker => 'https://github.com/trapd00r/perlutils/issues',
      },
    },
  },

  NAME                         => q{App::perlutils},
  AUTHOR                       => q{Magnus Woldrich <m@japh.se>},
  ABSTRACT                     => q{utils for perl development},
  VERSION_FROM                 => q{lib/App/perlutils.pm},
  LICENSE                      => q{perl},
  EXE_FILES                    => [
    glob("bin/*"),
  ],
  PREREQ_PM                    => {
    'Term::ExtendedColor'      => '0',
    'File::LsColor'            => '0',
    'File::Find::Rule'         => '0',
    'File::LibMagic'           => '0',
  },
  META_ADD                     => {
    provides => {
      'App::perlutils' => {
        file => 'lib/App/perlutils.pm',
      },
    },
  },
  MAN1PODS                     => { },
  dist                         => { COMPRESS => q{gzip -9f},    SUFFIX => q{gz}, },
  clean                        => { FILES    => q{},                  },
);

sub WriteMakefile1 {
  my %params = @_;
  my $eumm_version = $ExtUtils::MakeMaker::VERSION;
  $eumm_version = eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{AUTHOR} and ref($params{AUTHOR}) eq q{ARRAY}
      and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
      #EUMM 6.5502 has problems with BUILD_REQUIRES
      $params{PREREQ_PM}={
        %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}}
      };
      delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION}   if $eumm_version < 6.48;
  delete $params{META_MERGE}         if $eumm_version < 6.46;
  delete $params{META_ADD}           if $eumm_version < 6.46;
  delete $params{LICENSE}            if $eumm_version < 6.31;
  delete $params{AUTHOR}             if $] < 5.005;
  delete $params{ABSTRACT_FROM}      if $] < 5.005;
  delete $params{BINARY_LOCATION}    if $] < 5.005;

  #delete $params{MAN3PODS}->{'README.pod'};

  WriteMakefile(%params);
}
