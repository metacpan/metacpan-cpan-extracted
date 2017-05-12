use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %WriteMakefileArgs = (
  NAME => 'Catalyst::Manual',
  VERSION_FROM => 'lib/Catalyst/Manual.pm',
  AUTHOR => [ 'Catalyst Contributors, see Catalyst.pm', 'Kieren Diment <zarquon@cpan.org>' ],

  META_MERGE => {
    'meta-spec' => { version => 2 },
    dynamic_config => 0,
    resources => {
      repository => {
        # r/w: catagits@git.shadowcat.co.uk:Catalyst-Manual.git
        url => 'git://git.shadowcat.co.uk/catagits/Catalyst-Manual.git',
        web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=catagits/Catalyst-Manual.git',
        type => 'git',
      },
      bugtracker => {
        mailto => 'bug-Catalyst-Manual@rt.cpan.org',
        web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Manual',
      },
    },
  },

  META_ADD => {
    prereqs => {
      configure => {
        requires => {
          'ExtUtils::MakeMaker' => '0',
        },
      },
      runtime => {
        requires => {
          perl => '5.006',
        },
      },
      test => {
        requires => {
          'Test::More' => '0.88',
        },
      },
      develop => {
        requires => {
          'Pod::Simple' => '3.11', # L<Foo|http://foo.com> support
          'Test::Pod' => '1.14',
          'Test::Pod::Coverage' => '1.04',
        },
      },
    },
  },

  realclean => { FILES => [ 'Distar/', 'MANIFEST*' ] },
);

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
           or exists $WriteMakefileArgs{$key};
  my $r = $WriteMakefileArgs{$key} = {
    %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
    %{delete $WriteMakefileArgs{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
  if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
  if $eumm_version < 6.46;

delete $WriteMakefileArgs{LICENSE}
  if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);

