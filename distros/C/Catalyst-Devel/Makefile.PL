use strict;
use warnings FATAL => 'all';
use 5.006;

my %META = (
  name => 'Catalyst-Devel',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'     => 0,
      'File::ShareDir::Install' => 0,
    } },
    test => {
      requires => {
        'Test::More'  => '0.94',
        'Test::Fatal' => '0.003',
      },
    },
    runtime => {
      requires => {
        'Moose'                                   => 0,
        'MooseX::Emulate::Class::Accessor::Fast'  => 0,
        'File::ShareDir'                          => 0,
        'namespace::clean'                        => 0,
        'namespace::autoclean'                    => 0,
        'Catalyst'                                => '5.90001',
        'Catalyst::Action::RenderView'            => '0.10',
        'Catalyst::Plugin::Static::Simple'        => '0.28',
        'Catalyst::Plugin::ConfigLoader'          => '0.30',
        'Config::General'                         => '2.42',
        'File::ChangeNotify'                      => '0.07',
        'File::Copy::Recursive'                   => 0,
        'Path::Class'                             => '0.09',
        'Template'                                => '2.14',
        'Module::Install'                         => '1.02',
      },
    },
    develop => {
      requires => {
        'Proc::Background'    => 0,
        'Test::Pod'           => 0,
        'Test::Pod::Coverage' => 0,
      },
    },
  },
  resources => {
    repository => {
      url => 'git://git.shadowcat.co.uk/catagits/Catalyst-Devel.git',
      web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=catagits/Catalyst-Devel.git',
      type => 'git',
    },
    x_IRC => 'irc://irc.perl.org/#catalyst',
    x_MailingList => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst',
    homepage => 'http://dev.catalyst.perl.org/',
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Devel',
      mailto => 'bug-Catalyst-Devel@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
  x_authority => 'cpan:MSTROUT',
);

{
  package MY;
  use File::ShareDir::Install qw(install_share postamble);
  install_share 'share';
}

my %MM_ARGS = (
  PREREQ_PM => {
    # kill warning from older versions of Class::C3
    ( ("$]" >= 5.009_005 && eval { require Class::C3 } && !eval { Class::C3->VERSION(0.20) }) ? (
      'Class::C3' => '0.20',
    ) : () ),
  },
);

if (!$ENV{CATALYST_DEVEL_NO_510_CHECK}) {
    require IPC::Open3;
    require File::Spec;
    open my $in, '<', File::Spec->devnull;
    my $pid = IPC::Open3::open3($in, my $out, undef, $^X, '-It/lib', '-MUnknownError', '-e1');
    my $output = do { local $/; <$out> };

    waitpid $pid, 0;

    if ($output =~ /^Unknown error/m) {
        warn <<EOE;
############################### WARNING #################################
#                                                                       #
# You are using perl 5.10.0 with the "Unknown error" bug. This can make #
# developing Catalyst applications much more painful, as it will come   #
# up with no details every time you have a syntax error in a Controller.#
#                                                                       #
# For more information see:                                             #
#                                                                       #
#  * http://rt.perl.org/rt3/Public/Bug/Display.html?id=49472            #
#                                                                       #
# It is highly recommended that you use a different version of perl or  #
# compile a patched version for Catalyst development.                   #
#                                                                       #
# To skip this check, set the CATALYST_DEVEL_NO_510_CHECK environment   #
# variable.                                                             #
#                                                                       #
#########################################################################

EOE
        require ExtUtils::MakeMaker;
        my $ans = ExtUtils::MakeMaker::prompt('Do you want to continue?', 'no');
        exit 0 unless $ans =~ /^y(es)?\z/i;
    }
}


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
