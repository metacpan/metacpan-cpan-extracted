use strict;
use warnings;
use 5.008001;

my %META = (
  name => 'Catalyst-Plugin-Authentication',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker' => 0,
    } },
    test => {
      requires => {
        'Test::More' => '0.88',
        'Test::Fatal' => 0,
      },
    },
    runtime => {
      requires => {
        'Catalyst::Runtime' => 0,
        'MRO::Compat' => 0,
        'Moose' => 0,
        'MooseX::Emulate::Class::Accessor::Fast' => 0,
        'namespace::autoclean' => 0,
        'String::RewritePrefix' => 0,
        'Try::Tiny' => 0,
      },
    },
    develop => {
      requires => {
        'Test::Pod' => '1.14',
        'Test::Pod::Coverage' => '1.04',
        'Test::NoTabs' => 0,
        'Test::EOL' => 0,
        'Catalyst::Plugin::Session' => '0.10',
        'Catalyst::Plugin::Session::State::Cookie' => 0,
        'Digest::SHA' => 0,
      },
    },
  },
  resources => {
    repository => {
      url => 'https://github.com/perl-catalyst/Catalyst-Plugin-Authentication.git',
      web => 'https://github.com/perl-catalyst/Catalyst-Plugin-Authentication',
      type => 'git',
    },
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Plugin-Authentication',
      mailto => 'bug-Catalyst-Plugin-Authentication@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
  x_authority => 'cpan:BOBTFISH',
);

my %MM_ARGS = ();

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
