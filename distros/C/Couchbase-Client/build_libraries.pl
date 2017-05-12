#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(getcwd);
use File::Basename qw(fileparse);
use Log::Fu;
use File::Spec;
use Dir::Self qw(:static);
use Config;
use File::Path qw(mkpath rmtree);
use Getopt::Long;

GetOptions(
    "build-prefix=s" => \my $BuildPrefix,
    "install-prefix=s" => \my $InstallPrefix,
    'env-cppflags=s' => \my $ENV_CPPFLAGS,
    'env-ldflags=s' => \my $ENV_LDFLAGS,
    'env-libs=s'  => \my $ENV_LIBS,
    'rpath=s'     => \my $RPATH,
    'have-java'   => \my $HAVE_JAVA,
);

use lib __DIR__;
use PLCB_ConfUtil;

require 'PLCB_Config.pm';

my $plcb_conf = do 'PLCB_Config.pm' or die "Cannot find configuration";

my $BUILD_SILENT = "> /dev/null";
if($ENV{PLCB_BUILD_NOISY}) {
    $BUILD_SILENT = "";
}

my $RUN_TESTS = 1;
if(exists $ENV{PLCB_RUN_TESTS}) {
    $RUN_TESTS = $ENV{PLCB_RUN_TESTS};
}
if($^O =~ /solaris/) {
    print STDERR "Tests disabled on solaris\n";
    $RUN_TESTS = 0;
}

my %DEPS = map {  ( $_, $_ ) } @ARGV;

sub runcmd {
    my $cmd = join(" ", @_);
    print STDERR "[EXECUTING]:\n\t$cmd\n";
    unless(system($cmd . " $BUILD_SILENT") == 0) {
        print STDERR "Command $cmd failed\n";
        printf STDERR ("CPPFLAGS=%s\nLDFLAGS=%s\n", $ENV{CPPFLAGS}, $ENV{LDFLAGS});
        printf STDERR ("LD_RUN_PATH=%s\n", $ENV{LD_RUN_PATH});
        printf STDERR ("LIBS=%s\n", $ENV{LIBS});
        die "";
    }
}

sub lib_2_tarball {
    my $lib = shift;
    my $release = $plcb_conf->{uc($lib) . "_RELEASE"};
    my $name = "$lib-$release.tar.gz";
}

sub tarball_2_dir {
    my $tarball = shift;
    runcmd("tar xzf $tarball");
    my $filename = fileparse($tarball, qr/\.tar\..*/);
    return $filename;
}

################################################################################
################################################################################
### Tarball Names                                                            ###
################################################################################
################################################################################
my $LIBVBUCKET_TARBALL = lib_2_tarball('libvbucket');
my $LIBCOUCHBASE_TARBALL = lib_2_tarball('libcouchbase');
my $LIBEVENT_TARBALL = lib_2_tarball('libevent');

################################################################################
################################################################################
### Target Directory Structure                                               ###
################################################################################
################################################################################
my $TOPLEVEL = PLCB_ConfUtil::get_toplevel_dir();
my $INST_DIR = $BuildPrefix;
my $INCLUDE_PATH = File::Spec->catfile($INST_DIR, 'include');
my $LIB_PATH = File::Spec->catfile($INST_DIR, 'lib');

chdir $TOPLEVEL;

mkpath($INST_DIR);
mkpath($INCLUDE_PATH);
mkpath($LIB_PATH);

$ENV{PKG_CONFIG_PATH} .= ":"
. File::Spec->catfile($INST_DIR, 'lib', 'pkgconfig');
#$ENV{CC} = $Config{cc};
$ENV{LD_RUN_PATH} .= ":$RPATH";
$ENV{LD_LIBRARY_PATH} .= ":" . $ENV{LD_RUN_PATH};

$ENV{CPPFLAGS} .= $ENV_CPPFLAGS;
$ENV{LIBS} .= $ENV_LIBS;

my $MAKEPROG = $ENV{MAKE};
if(!$MAKEPROG) {
    if(system("gmake --version") == 0) {
        $MAKEPROG = "gmake";
    } else {
        $MAKEPROG = "make";
    }
}


my $MAKE_CONCURRENT = $ENV{PLCB_MAKE_CONCURRENT};
$MAKEPROG = "$MAKEPROG $MAKE_CONCURRENT";

log_info("We're in $TOPLEVEL now");
my @COMMON_OPTIONS = (
"--prefix=$BuildPrefix",
qw(
--silent
--without-docs)
);

sub should_build {
    my $name = shift;
    $name = uc($name);
    exists $DEPS{$name};
}

sub lib_is_built {
    my $libname = shift;
    if(-e File::Spec->catfile($LIB_PATH, $libname . "." . $Config{so})) {
        return 1;
    }
    return 0;
}

################################################################################
### ISASL                                                                    ###
################################################################################
#my $LIBISASL_TARBALL = lib_2_tarball('libisasl');
#disabled because we now bundle it with libcouchbase itself.
#if(should_build('ISASL')) {
#    chdir $TOPLEVEL;
#    chdir tarball_2_dir($LIBISASL_TARBALL);
#    runcmd("./configure", @COMMON_OPTIONS) unless -e 'Makefile';
#    log_info("Configuring libisasl");
#    runcmd("$MAKEPROG install");
#    log_info("Installed libisasl");
#}

################################################################################
### libevent                                                                 ###
################################################################################
if(should_build('EVENT')) {
    chdir $TOPLEVEL;
    my @libevent_options = (qw(
        --disable-openssl
        --disable-debug-mode
        ), @COMMON_OPTIONS
    );

    chdir tarball_2_dir($LIBEVENT_TARBALL);
    runcmd("./configure", @libevent_options) unless -e 'Makefile';
    log_info("Configured libevent");
    runcmd("$MAKEPROG install");
}


################################################################################
### libvbucket                                                               ###
################################################################################
# if(should_build('VBUCKET'))
{
    chdir $TOPLEVEL;
    chdir tarball_2_dir($LIBVBUCKET_TARBALL);
    if(!-e 'Makefile') {
        runcmd("./configure", @COMMON_OPTIONS);
        log_info("Configured libvbucket");
    }

    runcmd("$MAKEPROG");
    log_info("build libvbucket");
    runcmd("$MAKEPROG install");
    log_info("installed libvbucket");
    runcmd("$MAKEPROG check") if $RUN_TESTS;
    log_info("tested libvbucket");
}



################################################################################
### libcouchbase                                                             ###
################################################################################
#if (should_build('COUCHBASE')) {
{
    chdir $TOPLEVEL;
    chdir tarball_2_dir($LIBCOUCHBASE_TARBALL);

    my @libcouchbase_options = (
        @COMMON_OPTIONS,
        "--disable-tools",
        "--enable-embed-libevent-plugin",
    );

    if($^O =~ /solaris/) {
        print STDERR "Disabling tools (won't compile on solaris)\n";
        push @libcouchbase_options, '--disable-tools';
    }

    my $mockpath = File::Spec->catfile(
        __DIR__, 't', 'tmp', 'CouchbaseMock.jar');

    if(!-e $mockpath) {
        die("Can't find mock in $mockpath");
    }
    if($HAVE_JAVA && -e $mockpath) {
        push @libcouchbase_options, '--with-couchbasemock='.$mockpath;
    } else {
        push @libcouchbase_options, '--disable-couchbasemock';
    }

    #First, we need to mangle the 'configure' script:
    {
        my @conflines;
        open my $confh, "+<", "configure" or die "opening configure: $!";
        @conflines = <$confh>;
        foreach my $line (@conflines) {
            if($line =~ s/LIBS=(-l\S+)/LIBS="\$LIBS $1"/msg) {
                print STDERR ">> REPLACING: $line";
            }
            if($line =~ s/sasl_server_init\(NULL,/sasl_client_init\(/) {
                print STDERR ">> REPLACING: $line";
            }
        }
        seek($confh, 0, 0);
        print $confh @conflines;
        truncate($confh, tell($confh));

        close($confh);
    }

    runcmd("./configure", @libcouchbase_options) unless -e 'Makefile';
    runcmd("$MAKEPROG install");
    runcmd("$MAKEPROG check -s") if $RUN_TESTS;
}

exit(0);
