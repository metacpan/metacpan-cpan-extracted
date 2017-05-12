use strict;
use warnings;
use Config qw(%Config);
use Module::Build;
use File::Spec;
use File::Which qw(which);
use File::HomeDir;
use File::Path qw(remove_tree);
use LWP::Simple qw(getstore is_success);
use Archive::Tar;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Cwd ();

my $VERBOSE = 0;

sub _get_talib_win32_x64libs {
    my $force = shift;
    my $src_url = 'http://github.com/vikasnkumar/vikasnkumar.github.io/raw/98f6d24bc7ef9fa84df030aa64cba48a73e2838e/files/msvc-lib64.zip';
    my $datadir = $ENV{PREFIX} || File::HomeDir->my_dist_data('Alien-TALib', { create => 1 });
    my $destzip = File::Spec->catfile($datadir, 'msvc-lib64.zip');
    my $destdir = File::Spec->catfile($datadir, 'lib64');
    if ($force) {
        unlink $destzip if -e $destzip;
        remove_tree ($destdir, {safe => 1 });
    }
    unless (-e $destzip and -e $destdir) {
        print "Trying to download into $destzip from $src_url\n" if $VERBOSE;
        my $rc = getstore($src_url, $destzip);
        die "Unable to download source from $src_url into $destzip" unless is_success($rc);
        my $cwd = Cwd::getcwd;
        chdir $datadir;
        my $zip = Archive::Zip->new;
        if ($zip->read($destzip) == AZ_OK) {
            $zip->extractTree();
            die "Unable to successfully extract $destzip into ta-lib64" unless -e $destdir;
        } else {
            die "Unable to read the zip file: $destzip";
        }
        chdir $cwd;
    } else {
        print "$destzip already exists and is unarchived in ta-lib64\n" if $VERBOSE;
    }
    return $destdir;
}

sub _build_talib_src_win32 {
    my $force = shift;
    my $src_url = 'http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-msvc.zip';
    my $datadir = $ENV{PREFIX} || File::HomeDir->my_dist_data('Alien-TALib', { create => 1 });
    my $destzip = File::Spec->catfile($datadir, 'ta-lib-0.4.0-mscv.zip');
    my $destdir = File::Spec->catfile($datadir, 'ta-lib');
    if ($force) {
        unlink $destzip if -e $destzip;
        remove_tree ($destdir, {safe => 1 });
    }
    unless (-e $destzip and -e $destdir) {
        print "Trying to download into $destzip from $src_url\n" if $VERBOSE;
        my $rc = getstore($src_url, $destzip);
        die "Unable to download source from $src_url into $destzip" unless is_success($rc);
        my $cwd = Cwd::getcwd;
        chdir $datadir;
        my $zip = Archive::Zip->new;
        if ($zip->read($destzip) == AZ_OK) {
            $zip->extractTree();
            die "Unable to successfully extract $destzip into ta-lib" unless -e $destdir;
        } else {
            die "Unable to read the zip file: $destzip";
        }
        chdir $cwd;
    } else {
        print "$destzip already exists and is unarchived in ta-lib\n" if $VERBOSE;
    }
    my $lib64_dir;
    if ($Config{archname} =~ /x64|x86_64/i) {
        $lib64_dir = &_get_talib_win32_x64libs($force);
    }
    # ok we have extracted nicely and let's use the pre-built libs
    my $lib_dir = $lib64_dir || File::Spec->catdir($destdir, 'c', 'lib');
    my $libs = "-L$lib_dir -lta_abstract_cmr -lta_common_cmr -lta_func_cmr -lta_libc_cmr";
    my $inc_dir = File::Spec->catdir($destdir, 'c', 'include');
    my $cflags = "-I$inc_dir";
    return {
        cflags => $cflags,
        libs => $libs,
        installed => 1,
    };
}

sub _build_talib_src_unix {
    my $prefix = shift || $ENV{PREFIX} || File::HomeDir->my_dist_data('Alien-TALib', { create => 1 });
    my $src_url = 'http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz';
    my $dest = 'ta-lib-0.4.0-src.tar.gz';
    unless (-e $dest and -e 'ta-lib') {
        print "Trying to download $dest from $src_url\n" if $VERBOSE;
        my $rc = getstore($src_url, $dest);
        die "Unable to download source from $src_url into $dest" unless is_success($rc);
        if (Archive::Tar->has_zlib_support) {
            my $files = Archive::Tar->extract_archive($dest, COMPRESS_GZIP);
            die "Unable to extract source code in $dest ", Archive::Tar->error unless $files;
            die "Cannot find ta-lib/ directory" unless -d 'ta-lib';
        } else {
            die "No gzip/zlib support enabled in Archive::Tar. Cannot extract $dest";
        }
    } else {
        print "$dest already exists and is unarchived in ta-lib\n" if $VERBOSE;
    }
    my $prefix_cmd = "--prefix=$prefix" if $prefix;
    $prefix_cmd = '' unless $prefix;
    my @build_commands = (
        "./configure $prefix_cmd",
        'make',
        'make check',
        'make install',
    );
    my $cwd = Cwd::getcwd;
    chdir('ta-lib');
    my $ncwd = Cwd::getcwd;
    foreach my $cmd (@build_commands) {
        print "Executing $cmd\n" if $VERBOSE;
        system($cmd) == 0 || die "Unable to run '$cmd' in $ncwd";
    }
    chdir $cwd;
    my $taconf = File::Spec->catfile($prefix, 'bin', 'ta-lib-config');
    return $taconf if -e $taconf;
    die "Tried building the source but cannot find $taconf" unless -e $taconf;
}

sub _find_ta_lib_config {
    my ($taconf, $prefix) = @_; # pass an existing ta-lib-config as argument
    my $cflags = $ENV{TALIB_CFLAGS};
    my $libs = $ENV{TALIB_LIBS};
    if (defined $cflags and defined $libs) {
        return {
            cflags => $cflags,
            libs => $libs,
            installed => 1,
        };
    }
    my ($talibconfig) = $taconf || which('ta-lib-config');
    if (not defined $talibconfig and defined $prefix) {
        $talibconfig = File::Spec->catfile($prefix, 'bin', 'ta-lib-config');
    }
    my $inc_dir = '';
    my $lib_dir = '';
    if (defined $talibconfig) {
        print "ta-lib-config found installed at $talibconfig\n" if $VERBOSE;
        # usually the ta-lib-config is in the path format /abc/bin/ta-lib-config
        my ($vol, $dir, $file) = File::Spec->splitpath($talibconfig);
        my (@dirs) = File::Spec->splitdir($dir);
        pop @dirs if $dirs[$#dirs] eq '';
        pop @dirs if $dirs[$#dirs] eq 'bin';
        # create the include directory and lib directory path
        # to take care of ta-lib-config's malformed output
        # the user may have installed ta-lib-config in a non /usr/local area.
        $inc_dir = File::Spec->catdir(@dirs, 'include', 'ta-lib') if @dirs;
        $lib_dir = File::Spec->catdir(@dirs, 'lib') if @dirs;
        $inc_dir = File::Spec->catfile($vol, $inc_dir) if $inc_dir;
        $lib_dir = File::Spec->catfile($vol, $lib_dir) if $lib_dir;
        $inc_dir = File::Spec->canonpath($inc_dir);
        $lib_dir = File::Spec->canonpath($lib_dir);
        if (not defined $libs) {
            $libs = `$talibconfig --libs`;
            chomp $libs if length $libs;
            $libs =~ s/[\s\n\r]*$// if length $libs;
            $libs .= " -lta_lib" if length $libs && $libs !~ /-lta_lib/;
            # fix the problem with ta-lib-config --libs giving the wrong -L path
            $libs = "-L$lib_dir $libs" if $lib_dir;
        }
        if (not defined $cflags) {
            $cflags = `$talibconfig --cflags`;
            chomp $cflags if length $cflags;
            $cflags =~ s/[\s\n\r]*$// if length $cflags;
            $cflags = "-I$inc_dir $cflags" if $inc_dir;
        }
    }
    return unless (defined $cflags and defined $libs);
    #$cflags = " -DHAVE_CONFIG_H";
    #$libs = "-lpthread -ldl -lta_lib";
    if ($VERBOSE) {
        print "Expected ta-lib cflags: $cflags\n" if defined $cflags;
        print "Expected ta-lib libs: $libs\n" if defined $libs;
    }
    return {
        cflags => $cflags,
        libs => $libs,
        ta_lib_config => $talibconfig,
        installed => 1,
    };
}

my $needs_compiler = $^O =~ /Win32/i ? 0 : 1;
my $build = Module::Build->new(
    module_name => 'Alien::TALib',
    license => 'perl',
    dist_author => 'Vikas N. Kumar <vikas@cpan.org>',
    dist_abstract => 'Alien module for ta-lib from http://ta-lib.org',
    create_readme => 0,
    create_license => 0,
    needs_compiler => $needs_compiler,
    configure_requires => {
        'Module::Build' => 0,
        'File::Spec' => 0,
        'File::Which' => 0,
        'File::HomeDir' => 0,
        'File::Path' => 0,
        'LWP::Simple' => 0,
        'Archive::Tar' => 0,
        'Archive::Zip' => 0,
        'Cwd' => 0,
    },
    build_requires => {
        'Module::Build' => 0,
        'Test::More' => 0,
        'File::HomeDir' => 0,
        'File::Spec' => 0,
        'File::Which' => 0,
        'File::Path' => 0,
        'LWP::Simple' => 0,
        'Archive::Tar' => 0,
        'Archive::Zip' => 0,
        'Cwd' => 0,
    },
    requires => {
        'File::Spec' => 0,
        'File::Which' => 0,
        'File::HomeDir' => 0,
        'LWP::Simple' => 0,
        'Archive::Tar' => 0,
        'Archive::Zip' => 0,
        'Cwd' => 0,
        'perl' => 5.006,
    },
    meta_merge => {
        resources => {
            repository => "https://github.com/vikasnkumar/Alien-TALib",
            bugtracker => "https://github.com/vikasnkumar/Alien-TALib/issues",
        },
    },
);
$VERBOSE = $build->verbose;
my $installed = &_find_ta_lib_config(); # try ta-lib-config even on MS Windows
if ($^O =~ /Win32/i and not $installed) {
    $installed = &_build_talib_src_win32($ENV{TALIB_FORCE});
} else {
    if ($ENV{TALIB_FORCE} or not $installed) {
        # ok ta-lib was not found or build was forced
        # so build it
        # cygwin/linux/bsd/darwin
        my $prefix = $build->install_destination('bin');
        $prefix =~ s/bin\/?$//g if defined $prefix; # remove the bin
        $prefix = $ENV{PREFIX} || $build->prefix() || $prefix;
        my $taconf = &_build_talib_src_unix($prefix);
        $installed = &_find_ta_lib_config($taconf, $prefix);
    }
}
die "Unable to find ta-lib or install it" unless $installed;

foreach (keys %$installed) {
    $build->config_data($_ => $installed->{$_});
}
$build->create_build_script;
$build->dispatch('distmeta');
$build->dispatch('manifest');
$build->dispatch('build');

__END__
#### COPYRIGHT: Vikas N Kumar. All Rights Reserved
#### AUTHOR: Vikas N Kumar <vikas@cpan.org>
#### DATE: 17th Dec 2013
#### LICENSE: Refer LICENSE file.
