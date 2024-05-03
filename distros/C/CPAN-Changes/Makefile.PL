use strict;
use warnings FATAL => 'all';
use 5.008;

my %META = (
  name => 'CPAN-Changes',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
    } },
    test => {
      requires => {
        'Test::More'  => 0.96,
      },
    },
    runtime => {
      requires => {
        'Moo' => '1.006000',
        'Module::Runtime' => 0,
        'Test::Builder' => 0,
        'Sub::Quote' => '1.005000',
        'Types::Standard' => 0,
      },
    },
    develop => {
      requires => {
        'Test::Pod' => 1.00,
        'Test::Pod::Coverage::TrustMe' => '0.002000',
      },
    },
  },
  resources => {
    repository => {
      url => 'https://github.com/metacpan/CPAN-Changes.git',
      web => 'https://github.com/metacpan/CPAN-Changes',
      type => 'git',
    },
    x_IRC => 'irc://irc.perl.org/#metacpan',
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Changes',
      mailto => 'bug-CPAN-Changes@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
  x_authority => 'cpan:BRICAS',
  provides => {
    'CPAN::Changes' => {
      file => 'lib/CPAN/Changes.pm',
      version => '0.500004',
    },
    'CPAN::Changes::Entry' => {
      file => 'lib/CPAN/Changes/Entry.pm',
      version => '0.500004',
    },
    'CPAN::Changes::Group' => {
      file => 'lib/CPAN/Changes/Group.pm',
      version => '0.500004',
    },
    'CPAN::Changes::HasEntries' => {
      file => 'lib/CPAN/Changes/HasEntries.pm',
      version => '0.500004',
    },
    'CPAN::Changes::Parser' => {
      file => 'lib/CPAN/Changes/Parser.pm',
      version => '0.500004',
    },
    'CPAN::Changes::Release' => {
      file => 'lib/CPAN/Changes/Release.pm',
      version => '0.500004',
    },
    'CPAN::Changes::Spec' => {
      file => 'lib/CPAN/Changes/Spec.pod',
      version => '0.500004',
    },
    'Test::CPAN::Changes' => {
      file => 'lib/Test/CPAN/Changes.pm',
      version => '0.500004',
    },
  },
);

my %MM_ARGS = (
  EXE_FILES => [ 'bin/tidy_changelog' ],
  test => { TESTS => 't/*.t t/*/*.t' },
);

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g;
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
