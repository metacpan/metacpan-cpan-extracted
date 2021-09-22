use strict;
use warnings FATAL => 'all';
use 5.006;

my %META = (
  name => 'Acme-PodOnly',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
    } },
    build => { requires => {
    } },
    test => {
      requires => {
        'Test::More'  => '0.88',
      },
    },
    runtime => {
      requires => {
      },
    },
    develop   => {
      requires => {
      },
    },
  },
  provides => {
    'Acme::PodOnly' => {
      file => 'lib/Acme/PodOnly.pod',
      version => '0.001003',
    },
    'Acme::PodOnly::NoVersion' => {
      file => 'lib/Acme/PodOnly/NoVersion.pod',
    },
    'Acme::PodOnly::NoFile' => {
      file => undef,
      version => '0.001003',
    },
    'Acme::PodOnly::MissingFile' => {
      file => 'lib/Acme/PodOnly/MissingFile.pod',
      version => '0.001003',
    },
  },
  resources => {
    repository => {
      url => 'https://github.com/haarg/Acme-PodOnly.git',
      web => 'https://github.com/haarg/Acme-PodOnly',
      type => 'git',
    },
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Acme-PodOnly',
      mailto => 'bug-Acme-PodOnly@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
  x_breaks => {
  },
  x_authority => 'cpan:HAARG',
);

my %MM_ARGS = (
  VERSION => '0.001003',
  ABSTRACT_FROM => 'lib/Acme/PodOnly.pod',
);

eval {
  no warnings qw(once redefine);
  require CPAN::Meta::Validator;
  *CPAN::Meta::Validator::is_valid = sub { 1 };
};

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g
  if !exists $MM_ARGS{VERSION} && !exists $MM_ARGS{VERSION_FROM};
$META{license} = [ $META{license} ]
  if $META{license} && !ref $META{license};
$MM_ARGS{LICENSE} = $META{license}[0]
  if $META{license} && $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';
$MM_ARGS{PL_FILES} ||= {};
$MM_ARGS{NORECURS} = 1
  if not exists $MM_ARGS{NORECURS};

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  my $r = $MM_ARGS{$key} = {
    %{$META{prereqs}{$_}{requires} || {}},
    %{delete $MM_ARGS{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

$MM_ARGS{MIN_PERL_VERSION} = delete $MM_ARGS{PREREQ_PM}{perl} || 0;

delete $MM_ARGS{MIN_PERL_VERSION}
  if $eumm_version < 6.47_01;
$MM_ARGS{BUILD_REQUIRES} = {%{$MM_ARGS{BUILD_REQUIRES}}, %{delete $MM_ARGS{TEST_REQUIRES}}}
  if $eumm_version < 6.63_03;
$MM_ARGS{PREREQ_PM} = {%{$MM_ARGS{PREREQ_PM}}, %{delete $MM_ARGS{BUILD_REQUIRES}}}
  if $eumm_version < 6.55_01;
delete $MM_ARGS{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

ExtUtils::MakeMaker::WriteMakefile(%MM_ARGS);
## END BOILERPLATE ###########################################################
