use strict;
use warnings FATAL => 'all';
use 5.006002;

my %META = (
  name => 'Class-C3-Componentised',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
    } },
    build => { requires => {
    } },
    test => {
      requires => {
        'Test::Exception' => '0.31',
        'Test::More'      => '0.96',
      },
    },
    runtime => {
      requires => {
        'perl'              => '5.006002',
        'MRO::Compat'       => '0.09',
        'Class::Inspector'  => '1.32',
        # we don't actually need Class::C3. MRO::Compat loads it on 5.8. On 5.10
        # it isn't needed. However, some existing code relies on us loading
        # Class::C3. We don't want to break it just yet. Therefore we depend
        # directly on Class::C3 as well.
        'Class::C3'         => '0.20',
      },
    },
    develop => {
      requires => {
        'Test::Pod' => '1.14',
        'Test::Pod::Coverage' => '1.04',
      },
    },
  },
  resources => {
    repository => {
      url => 'git://git.shadowcat.co.uk/p5sagit/Class-C3-Componentised.git',
      web => 'https://github.com/p5sagit/Class-C3-Componentised',
      type => 'git',
    },
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Class-C3-Componentised',
      mailto => 'bug-Class-C3-Componentised@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
  x_authority => "cpan:FREW",
  dynamic_config => 0,
  x_static_install => 1,
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
