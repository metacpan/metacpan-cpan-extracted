package PLCB_ConfUtil;
use strict;
use warnings;
use Dir::Self;
use File::Spec;
use File::Path qw(rmtree);
use Data::Dumper;
use Config;

use lib __DIR__;

my $config = do 'PLCB_Config.pm';
if(!$config) {
    warn("Couldn't find PLCB_Config.pm. Assuming defaults");
    $config = {};
}

sub set_gcc_env {

}

sub get_gcc_linker_flags {
    my $libpath = $config->{COUCHBASE_LIBRARY_PATH};
    if($libpath) {
        $libpath = "-L$libpath ";
    } else {
        $libpath = "";
    }
    $libpath .= '-lcouchbase -lcouchbase_libevent -lvbucket';
    return $libpath;
}

sub get_include_dir {
    my $dir = $config->{COUCHBASE_INCLUDE_PATH};
    if($dir) {
        return "-I$dir";
    } else {
        return "";
    }
}

sub clean_cbc_sources {
    my $dir_base = $config->{SRC_DIR};
    while (my ($kname,$release) = each %$config) {
        next unless $kname =~ /RELEASE/;
        my ($libname,$version) = ($kname =~ /(LIB[^_]+)(.+)/);
        $libname = lc($libname);
        my $dir = "$libname-$release";
        warn $dir;
        $dir = File::Spec->catfile($dir_base, $dir);
        rmtree($dir);
    }
    rmtree($config->{SRC_INST});
}

sub get_toplevel_dir {
    $config->{SRC_DIR};
}

sub get_inst_dir {
    $config->{SRC_INST};
}

my $TEMPFILE = File::Spec->catfile(__DIR__, "COMPILER_FLAGS");

sub write_tmpflags {
    my ($cflags,$ldflags) = @_;
    open my $fh, ">", $TEMPFILE or die "$TEMPFILE: $@";
    my $h = {
        CFLAGS => $cflags,
        LDFLAGS => $ldflags
    };
    print $fh Dumper($h);
}

sub env_from_tmpflags {
    my $confhash = do "$TEMPFILE";
    $ENV{CFLAGS} .= ' ' . $confhash->{CFLAGS} . ' ' . $Config{ccflags};
    $ENV{CFLAGS} .= ' -I' . File::Spec->catfile(__DIR__, 'xs');
    $ENV{LDFLAGS}= "";
#    $ENV{LDFLAGS}  .= ' ' .  $confhash->{LDFLAGS};

#    printf("CFLAGS: %s\nLDFLAGS=%s\n", $ENV{CFLAGS}, $ENV{LDFLAGS});
}

1;
