package My::Build;

use warnings FATAL => 'all';
use strict;

use Archive::Tar;
use Cwd qw/realpath/;
use Digest::SHA qw/sha1_hex/;
use File::Path qw/remove_tree/;
use File::Spec::Functions qw/catdir catfile/;
use IPC::Run qw/run/;
use LWP::Simple qw/getstore RC_OK/;
use Module::Build;

use base 'Module::Build';

sub ACTION_code {
    my $self = shift;

    $self->SUPER::ACTION_code;

    return if -e 'build-zeromq';
    $self->add_to_cleanup('build-zeromq');

    my %args = $self->args;
    my %vars;

    $self->have_c_compiler or die "C compiler not found";

    unless (exists $args{'zmq-skip-probe'}) {
        print "Probing...\n";
        %vars = $self->probe_zeromq;
    }

    if ($vars{inc_version} && $vars{lib_version} && $vars{inc_dir} && $vars{lib_dir}) {
        print "Found libzmq $vars{lib_version}; skipping installation\n";
    } else {
        print "libzmq not found; building from source...\n";
        %vars = $self->install_zeromq;
    }

    # write vars to ZMQ.pm
    my $module = catfile qw/blib lib Alien ZMQ.pm/;
    open my $LIB, '<', $module or die "Cannot read module";
    my $lib = do { local $/; <$LIB> };
    close $LIB;
    $lib =~ s/^sub inc_dir.*$/sub inc_dir { "$vars{inc_dir}" }/m;
    $lib =~ s/^sub lib_dir.*$/sub lib_dir { "$vars{lib_dir}" }/m;
    $lib =~ s/^sub inc_version.*$/sub inc_version { v$vars{inc_version} }/m;
    $lib =~ s/^sub lib_version.*$/sub lib_version { v$vars{lib_version} }/m;
    my @stats = stat $module;
    chmod 0644, $module;
    open $LIB, '>', $module or die "Cannot write config to module";
    print $LIB $lib;
    close $LIB;
    chmod $stats[2], $module;

    open my $TARGET, '>', "build-zeromq";
    print $TARGET time, "\n";
    close $TARGET;
}

sub probe_zeromq {
    my $self = shift;
    my $cb = $self->cbuilder;
    my %config = $cb->get_config;

    my $src = "test-$$.c";
    open my $SRC, '>', $src;
    print $SRC <<END;
#include <stdio.h>
#include <zmq.h>
int main(int argc, char* argv[]) {
    int major, minor, patch;
    zmq_version(&major, &minor, &patch);
    printf("%d.%d.%d %d.%d.%d",
        ZMQ_VERSION_MAJOR, ZMQ_VERSION_MINOR, ZMQ_VERSION_PATCH,
        major, minor, patch);
    return 0;
}
END
    close $SRC;

    my @inc_search;
    my @lib_search;

    my $cflags = $self->args('zmq-cflags');
    my $libs   = $self->args('zmq-libs');

    my $pkg_version;

    my $pkg_config = $ENV{PKG_CONFIG_COMMAND} || "pkg-config";
    for my $pkg (qw/libzmq zeromq3/) {
        $pkg_version = `$pkg_config $pkg --modversion`;
        chomp $pkg_version;
        next unless $pkg_version;

        $cflags ||= `$pkg_config $pkg --cflags`;
        $libs   ||= `$pkg_config $pkg --libs`;

        # use -I and -L flag arguments as extra search directories
        my $inc = `$pkg_config $pkg --cflags-only-I`;
        push @inc_search, map { s/^-I//; $_ } $cb->split_like_shell($inc);
        my $lib = `$pkg_config $pkg --libs-only-L`;
        push @lib_search, map { s/^-L//; $_ } $cb->split_like_shell($lib);

        last;
    }

    my $obj = eval {
        $cb->compile(source => $src, include_dirs => [@inc_search], extra_compiler_flags => $cflags);
    };
    unlink $src;
    return unless $obj;

    my $exe = eval {
        $cb->link_executable(objects => $obj, extra_linker_flags => $libs);
    };
    unlink $obj;
    return unless $exe;

    my $out = `./$exe`;
    unlink $exe;
    my ($inc_version, $lib_version) = $out =~ /(\d\.\d\.\d) (\d\.\d\.\d)/;

    # query the compiler for include and library search paths
    push @lib_search, map {
        my $path = $_;
        $path =~ s/^.+ =?//;
        $path =~ s/\n.*$//;
        -d $path ? realpath($path) : ();
    } split /:/, `$config{cc} -print-search-dirs`;
    push @inc_search, map {
        my $path = $_;
        $path =~ s/lib(32|64)?$/include/;
        $path;
    } @lib_search;

    # search for the header and library files
    my ($inc_dir) = grep { -f catfile($_, "zmq.h") } @inc_search;
    my ($lib_dir) = grep { -f catfile($_, $cb->lib_file("libzmq")) } @lib_search;

    (
        inc_version => $inc_version,
        lib_version => $lib_version,
        pkg_version => $pkg_version,
        inc_dir	    => $inc_dir,
        lib_dir	    => $lib_dir,
    );
}

sub install_zeromq {
    my $self = shift;
    my $cb = $self->cbuilder;

    my $version = $self->notes('zmq-version');
    my $sha1 = $self->notes('zmq-sha1');
    my $archive = "zeromq-$version.tar.gz";

    print "Downloading libzmq $version source archive from download.zeromq.org...\n";
    getstore("http://download.zeromq.org/$archive", $archive) == RC_OK
        or die "Failed to download libzmq source archive";

    print "Verifying...\n";
    my $sha1sum = Digest::SHA->new;
    open my $ARCHIVE, '<', $archive or die "Can't open source archive";
    binmode $ARCHIVE;
    $sha1sum->addfile($ARCHIVE);
    close $ARCHIVE;
    $sha1sum->hexdigest eq $sha1 or die "Source archive checksum mismatch";

    print "Extracting...\n";
    Archive::Tar->new($archive)->extract;
    unlink $archive;

    my $prefix  = catdir($self->install_destination("lib"), qw/auto share dist Alien-ZMQ/);
    my $basedir = $self->base_dir;
    my $datadir = catdir($basedir, "share");
    my $srcdir  = catdir($basedir, "zeromq-$version");
    chdir $srcdir;

    print "Patching...\n";
    for my $patch (glob("$basedir/files/zeromq-$version-*.patch")) {
	run [qw/patch -p1/], '<', $patch or die "Failed to patch libzmq";
    }

    print "Configuring...\n";
    my @config = $cb->split_like_shell($self->args('zmq-config') || "");
    $cb->do_system(qw/sh configure CPPFLAGS=-Wno-error/, "--prefix=$prefix", @config)
        or die "Failed to configure libzmq";

    print "Compiling...\n";
    $cb->do_system("make") or die "Failed to make libzmq";

    print "Installing...\n";
    $cb->do_system(qw|make install prefix=/|, "DESTDIR=$datadir")
        or die "Failed to install libzmq";

    chdir $basedir;
    remove_tree($srcdir);

    (
        inc_version => $version,
        lib_version => $version,
        inc_dir	    => catdir($prefix, "include"),
        lib_dir	    => catdir($prefix, "lib"),
    );
}

1;
