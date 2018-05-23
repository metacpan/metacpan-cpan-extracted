#!/usr/bin/perl

### we /need/ perl5.6.1 or higher -- we use coderefs in @INC,
### and 5.6.0 is just too buggy
use 5.006001;

use strict;
use warnings;

BEGIN {
    ### chdir to the makefile.pl dir
    use FindBin;
    use lib $FindBin::Bin;

    use File::Spec;
    use lib File::Spec->catdir( $FindBin::Bin, qw[lib] );        # cpanplus modules

    ### add the directory to our bundled modules
    use vars qw[@ORIG_INC];
    @ORIG_INC = @INC;       # store for later use
    lib->import( File::Spec->catdir( $FindBin::Bin, qw[inc bundle]) );
}


### there's issues with redhat 9.0's stock perl -- they applied some
### custom patches on their 5.8.0 and it breaks use constant a => sub {};
if( $^O eq 'linux' and -e '/etc/redhat-release' and
    $] == '5.008' and (grep /Red Hat, Inc/, values %Config::Config)
) {
    print qq(
### IMPORTANT! ######################################################

You are using perl $] supplied by RedHat, who have applied custom
patches that break various perl modules, including this one.

You will have to migrate to a perl without these flaws. You could
do this for example by building a perl installation by hand.
You can obtain the sources from www.cpan.org.

We're sorry for the inconvenience.

#####################################################################

    ) . $/;

    require 5.008001;
}

### it spews warnings though, so grep those out
### also grep out the warnings we get from using Module::Loaded
BEGIN {
    $SIG{__WARN__} = sub {
        print STDERR "@_" if
            "@_" !~ /^CPANPLUS::inc/        and
            "@_" !~ /Constant subroutine/;
    };
}

use inc::Module::Install;
use Getopt::Long;
use CPANPLUS::Backend;
use CPANPLUS::Configure;
use CPANPLUS::Configure::Setup;
use CPANPLUS::Internals::Constants;
use Locale::Maketext::Simple    Class => 'CPANPLUS', Style => 'gettext';


use constant BASIC_TESTS =>     qq[t/00_CPANPLUS-Internals-Utils.t];


my $Tests;
my $RunSetup;
GetOptions( 'setup' => \$RunSetup );

my $Backend = CPANPLUS::Backend->new;
my $Config  = CPANPLUS::Configure->new;

### no setup? this is easy.. print the message and move a long
unless( $RunSetup ) {
    print qq[
### IMPORTANT! ######################################################


As of CPANPLUS 0.070, configuration during 'perl Makefile.PL'
is no longer required. A default config is now shipped that
should work out of the box on most machines, for priviliged
and unprivileged users.

If you wish to configure CPANPLUS to your environment, you can
either do that from the interactive shell after installation:

    \$ cpanp
    CPAN Terminal> s reconfigure

Or you can invoke this program as follows, to do it now:

    \$ $^X Makefile.PL --setup

This also means that any config created by any CPANPLUS older
than 0.070 will no longer work, and you are required to
reconfigure. See the ChangeLog file for details.

We appologize for the inconvenience.
    ] . $/;

### ok, we're asked to run the setup stuff, let's do it
} else {

    my $setup = CPANPLUS::Configure::Setup->new(
                    backend             => $Backend,
                    configure_object    => $Config,
                );

    $setup->init;
}

{   print loc("
### PLEASE NOTE ###################################################

CPANPLUS also ships a 'boxed' cpanp client, so you can run it
out of it's extraction dir, by typing:

    \$ perl bin/cpanp-boxed

This may help you with bootstrap issues, or other situations
where you need to use CPANPLUS but can not use a system installation.

You can install all of CPANPLUS' dependencies like this, before
installing CPANPLUS itself by running:

    \$ perl bin/cpanp-boxed -s selfupdate dependencies

All the modules bundled are found in the 'inc/bundle' directory. If
you, for whatever reason, wish to not install these from cpan, you
could include them into your environment as such (using tcsh):

    \$ setenv PERL5LIB $FindBin::Bin/inc/bundle

###################################################################

    " );
    print "\n";
}

_check_site_bin();

### toss out the old source files, they might be compiled
### in an incompatilbe format (rt #18121)
### use 'can', because it might be  different backend now
{   my $pat = File::Spec->catfile(
                    $Config->get_conf('base'),
                    $Config->_get_source('stored') .'*'. STORABLE_EXT,
                );

    for my $file( glob($pat) ) {
        1 while $file && unlink $file;
    }
}

### write the makefile.pl
{   my $su      = $Backend->selfupdate_object;
    my %prereq  = ( %{ $su->list_core_dependencies( 'AS_HASH' ) },
                    map { ### might not need anything -- make sure we
                          ### place an empty hash ref there
                          %{ $su->modules_for_feature( $_, 'AS_HASH' ) || {} }
                    } $su->list_enabled_features
                );

    my $buildclean;
    if ( $prereq{'CPANPLUS::Dist::Build'} ) {
      delete $prereq{'CPANPLUS::Dist::Build'};
      $prereq{'Module::Build'} = '0.32';
      require File::Path; require File::Copy;
      File::Path::mkpath( File::Spec->catdir(qw[lib CPANPLUS Dist Build]) ) or die "$!\n";
      File::Copy::copy( File::Spec->catfile('bundled', 'Build.pm'), File::Spec->catfile(qw[lib CPANPLUS Dist], 'Build.pm') );
      File::Copy::copy( File::Spec->catfile('bundled', 'Constants.pm'), File::Spec->catfile(qw[lib CPANPLUS Dist Build], 'Constants.pm' ) );
      $buildclean = ' lib/CPANPLUS/Dist/Build*';
    }

    my @scripts = _scripts();
    my $extraclean .= join ' ', grep { /\d$/ } @scripts;

    ### restore the original @INC, so proper probing of missing
    ### prereqs can be done
    @INC = @ORIG_INC;
    name            ('CPANPLUS');
    author          ('Jos Boumans <kane@cpan.org>');
    abstract        ('Ameliorated interface to the CPAN');
    version_from    ('lib/CPANPLUS/Internals.pm');
    license         ('perl');
    no_index        ( directory => 'bundled' );
    installdirs     ( $] >= 5.009005 && $] < 5.012 ? 'perl' : 'site' ),
    install_script  ($_) for @scripts;
    #install_script  ($_) for grep { $_ !~ /cpanp-boxed/ } glob('bin/*');
    requires        (%prereq);
    makemaker_args  ( test => { TESTS => $Tests } ) if $Tests;
    makemaker_args  ( clean => { FILES =>
                        '.cpanplus t/.*.output t/*.rpt ' .
                        't/dummy-cpanplus/* t/dummy-cpanplus/.cpanplus '.
                        't/dummy-localmirror/* ' . 't/dummy-perl/arch ' .
                        't/dummy-perl/bin/* ' . 't/dummy-perl/lib/* ' .
                        't/dummy-perl/man/man1/* ' . 't/dummy-perl/man/man3/*'.
                        ( $extraclean ? " $extraclean" : '' ) .
                        ( $buildclean ? $buildclean : '' )
                    } );
    repository      ('https://github.com/jib/cpanplus-devel');

    ### write the makefile
    ### this makes all prereqs rediscovered
    {   use Module::Loaded;
        for ( keys %prereq ) {
            mark_as_unloaded( $_ ) if is_loaded( $_ );
        }

        ### silence warnings about redefines...
        ### this will still warn about redefine of CONSTANTS subs...
        no warnings; local $^W;
        &WriteAll( check_nmake => 1 );
    }
}

sub _scripts {
  my @scripts = grep { $_ !~ /cpanp-boxed/ } glob('bin/*');
  if ( $] >= 5.009005 && $] < 5.019000 ) {
    require Config;
    my $version = sprintf("%vd",$^V);
    if ( $Config::Config{versiononly} and
         $Config::Config{startperl} =~ /\Q$version\E$/ ) {
         require File::Copy;
         File::Copy::copy( $_, "$_$version" ) for @scripts;
         @scripts = glob("bin/*$version");
    }
  }
  return @scripts;
}

sub _check_site_bin
{
  require Config;
  return if $] < 5.012;
  return if $Config::Config{installscript} eq $Config::Config{installsitescript};
    print qq(
### IMPORTANT! ######################################################

Your site and core script locations are different. We will be put the
scripts provided by this distribution in the site location.

Please ensure that the site location is in your PATH.

#####################################################################

    ) . $/;
}
