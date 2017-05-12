#!/usr/bin/perl

# @(#)Makefile.PL	1.1

use 5.008;
use ExtUtils::MakeMaker;

use strict;

use Cwd;
use File::Spec;
use Config;

my $pwd=cwd();

sub tsm_choose_dsm_dir {
    if (-d $ENV{DSM_DIR} and
        -f $ENV{DSM_CONFIG}
        ) {
        my $dsm_config=(-f File::Spec->catfile($ENV{DSM_DIR},"dsm.sys"))?File::Spec->catfile($ENV{DSM_DIR},"dsm.sys"):
                                                                         File::Spec->catfile($ENV{DSM_CONFIG});        
        return ($ENV{DSM_DIR},
                File::Spec->catfile($ENV{DSM_DIR},"dsmadmc"),
                $dsm_config,
                );
    }
    ($^O eq 'linux'   or
     $^O eq 'solaris' ) and return (File::Spec->catfile("","opt","tivoli","tsm","client","ba","bin"),
                                    File::Spec->catfile("","opt","tivoli","tsm","client","ba","bin","dsmadmc"),
                                    File::Spec->catfile("","opt","tivoli","tsm","client","ba","bin","dsm.sys"),
                                   );
    ($^O eq 'aix'     or
     $^O eq 'irix'    or
     $^O eq 'hpux')      and return (File::Spec->catfile("","usr","tivoli","tsm","client","ba","bin"),
                                     File::Spec->catfile("","usr","bin","dsmadmc"),
                                     File::Spec->catfile("","usr","tivoli","tsm","client","ba","bin","dsm.sys"),
                                 );
    ($^O eq 'darwin')    and return (File::Spec->catfile("","Library","Application Support","tivoli","tsm","client","ba","bin"),
                                     File::Spec->catfile("","Library","Application Support","tivoli","tsm","client","ba","bin","dsmadmc"),
                                     File::Spec->catfile("","Library","Preferences", "Tivoli Storage Manager","dsm.opt"),
                                 );
    ($^O eq 'MSWin32')   and return (File::Spec->catfile($ENV{ProgramFiles},"Tivoli","tsm","baclient"),
                                     File::Spec->catfile($ENV{ProgramFiles},"Tivoli","tsm","baclient","dsmadmc"),
                                     File::Spec->catfile($ENV{ProgramFiles},"Tivoli","tsm","baclient","dsm.opt"),
                                    );
    return;
}

sub config_macro {
    my ($dsm_dir,$dsmadmc,$dsm_config)=tsm_choose_dsm_dir();
    
    $dsm_dir    = $ENV{DSM_DIR} || 'need_DSM_DIR'                unless (-d $dsm_dir);
    $dsmadmc    = File::Spec->catfile($ENV{DSM_DIR}, 'dsmadmc')  unless (-f $dsmadmc);
    $dsm_config = $ENV{DSM_CONFIG} || 'need_DSM_SYS'             unless (-f $dsm_config);
    
    print "Choose TSM Install directory:  $dsm_dir\n";
    print "Choose TSM dsmadmc command:    $dsmadmc\n";
    print "Choose TSM client config file: $dsm_config\n";
    
    return {
        TSM_DSMDIR    => $dsm_dir,
        TSM_DSMCONFIG => $dsm_config,
        TSM_DSMADMC   => $dsmadmc,
        };  
}

my $macros        = config_macro();
my @module        = ('DBD','TSM');
my $module_name   = join('::',@module);
my $module_filter = File::Spec->catfile('lib',@module,'configure.pl');
$module[-1]      .= '.pm';
my $module_path   = File::Spec->catfile('lib',@module);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => $module_name,
    VERSION_FROM      => $module_path, # finds $VERSION
    PREREQ_PM         => {DBI => 1.4}, # e.g., Module::Name => 1.1
    macro             => $macros,
    PM_FILTER         => $Config{perlpath}." ".$module_filter,
    ($] >= 5.008 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBD/TSM.pm', # retrieve abstract from module
       AUTHOR         => 'Laurent Bendavid <bendavid.laurent@free.fr>') : ()),
);
