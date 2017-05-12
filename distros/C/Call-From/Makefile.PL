use strict;
use warnings FATAL => 'all';
use 5.006;

my $DISTNAME    = 'Call-From';
my $GITHUB_USER = 'kentnl';
my $GITHUB_REPO = $DISTNAME;

my %META = (
    name           => $DISTNAME,
    license        => 'perl_5',
    dynamic_config => 0,
    prereqs        => {
        configure => {
            requires => {
                'ExtUtils::MakeMaker' => 0,
            }
        },
        build => { requires => {} },
        test  => {
            requires => {
                'constant'   => 0,
                'Test::More' => '0.95_02',
            }
        },
        runtime => {
            requires => {
                'Exporter' => 0,
                'perl'     => '5.006',
            }
        },
        develop => {
            requires => {
                'CPAN::Meta::Converter'   => 0,
                'CPAN::Meta::Prereqs'     => 0,
                'Carp'                    => 0,
                'Config'                  => 0,
                'Data::Dumper'            => 0,
                'Exporter'                => 0,
                'ExtUtils::MM'            => 0,
                'ExtUtils::MakeMaker'     => 0,
                'ExtUtils::Manifest'      => 0,
                'File::Find'              => 0,
                'File::Path'              => 0,
                'File::Spec'              => 0,
                'File::Temp'              => 0,
                'Getopt::Long'            => 0,
                'Module::CPANfile'        => 0,
                'Module::Metadata'        => 0,
                'PIR'                     => 0,
                'Path::Tiny'              => 0,
                'Perl::PrereqScanner'     => 0,
                'Pod::Coverage::TrustPod' => 0,
                'Test::CPAN::Changes'     => 0,
                'Test::EOL'               => 0,
                'Test::Kwalitee'          => '1.21',
                'Test::More'              => '0.96',
                'Test::Perl::Critic'      => 0,
                'Test::Pod'               => '1.41',
                'Test::Pod::Coverage'     => '1.08',
                'base'                    => 0,
                'perl'                    => '5.006',
            }
        },
    },
    resources => {
        repository => {
            url  => 'git://github.com/' . $GITHUB_USER . '/' . $GITHUB_REPO,
            web  => 'https://github.com/' . $GITHUB_USER . '/' . $GITHUB_REPO,
            type => 'git',
        },
        bugtracker => {
                web => 'https://github.com/'
              . $GITHUB_USER . '/'
              . $GITHUB_REPO
              . '/issues'
        },
        license => ['http://dev.perl.org/licenses/'],
    },
    x_authority => "cpan:KENTNL",
    (
          ( !-f 'META.yml' and -f 'maint/provided.pl' )
        ? ( provides => ( do 'maint/provided.pl' or die $@ ) )
        : ()
    )
);

my %MM_ARGS = ();

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
( do 'maint/Makefile.PL.include' or die $@ ) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

( $MM_ARGS{NAME}         = $META{name} ) =~ s/-/::/g;
( $MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm" ) =~ s{::}{/}g;
$META{license} = [ $META{license} ]
  if $META{license} && !ref $META{license};
$MM_ARGS{LICENSE} = $META{license}[0]
  if $META{license} && $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';
$MM_ARGS{test} = { TESTS => "t/*.t t/*/*.t" };

for (qw(configure build test runtime)) {
    my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_ . '_REQUIRES';
    my $r = $MM_ARGS{$key} = {
        %{ $META{prereqs}{$_}{requires} || {} },
        %{ delete $MM_ARGS{$key} || {} },
    };
    defined $r->{$_} or delete $r->{$_} for keys %$r;
}

$MM_ARGS{MIN_PERL_VERSION} = delete $MM_ARGS{PREREQ_PM}{perl} || 0;

delete $MM_ARGS{MIN_PERL_VERSION}
  if $eumm_version < 6.47_01;
$MM_ARGS{BUILD_REQUIRES} =
  { %{ $MM_ARGS{BUILD_REQUIRES} }, %{ delete $MM_ARGS{TEST_REQUIRES} } }
  if $eumm_version < 6.63_03;
$MM_ARGS{PREREQ_PM} =
  { %{ $MM_ARGS{PREREQ_PM} }, %{ delete $MM_ARGS{BUILD_REQUIRES} } }
  if $eumm_version < 6.55_01;
delete $MM_ARGS{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

ExtUtils::MakeMaker::WriteMakefile(%MM_ARGS);
## END BOILERPLATE ###########################################################
