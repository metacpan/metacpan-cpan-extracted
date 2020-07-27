use strict;
use warnings FATAL => 'all';
use 5.008;

my %META = (
  name => 'Catalyst-Plugin-ConfigLoader',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
    } },
    test => {
      requires => {
        'Test::More' => '0.96',
      },
    },
    runtime => {
      requires => {
        'Catalyst::Runtime' => '5.7008',    # needed for env_value()
        'Data::Visitor'     => '0.24',
        'Config::Any'       => '0.20',
        'MRO::Compat'       => '0.09',
      },
    },
    develop => {
      requires => {
        'Test::Pod'           => '1.00',
        'Test::Pod::Coverage' => '1.00',
      },
    },
  },
  resources => {
    repository => {
      # rw: catagits@git.shadowcat.co.uk:Catalyst-Plugin-ConfigLoader.git
      url => 'git://git.shadowcat.co.uk/catagits/Catalyst-Plugin-ConfigLoader.git',
      web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=catagits/Catalyst-Plugin-ConfigLoader.git',
      type => 'git',
    },
    x_IRC => 'irc://irc.perl.org/#catalyst',
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Plugin-ConfigLoader',
      mailto => 'bug-Catalyst-Plugin-ConfigLoader@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
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
