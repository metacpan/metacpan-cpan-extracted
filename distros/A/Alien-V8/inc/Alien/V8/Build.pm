package Alien::V8::Build;

use base qw(Module::Build);

##############################################################################
#
# Modules
#
##############################################################################
use Config;
use Cwd;
use File::Spec;
use File::Path;
use File::Copy;
use Archive::Tar;
use IPC::Cmd qw(can_run);

##############################################################################
#
# Global variable
#
##############################################################################
my $RootDir = File::Spec->rel2abs(".");
my $SrcDir = File::Spec->catdir($RootDir, "src");
my $ShareDir = File::Spec->catdir($RootDir, "share");
my $ShareIncDir = File::Spec->catdir($ShareDir, "include");
my $ShareLibDir = File::Spec->catdir($ShareDir, "lib");

my $SConsName = "scons-2.0.1";
my $SConsDist = "$SConsName.tar.gz";
my $SConsDir = File::Spec->catdir($SrcDir, $SConsName);
my $SConsLibDir = File::Spec->catdir($SConsDir, "engine");
my $SConsBin = File::Spec->catfile($SConsDir, "script", "scons");
my @SConsArgs = (
    "library=shared",
    "console=readline"
);

my $V8Name = "v8-3.1.5";
my $V8Dist = "$V8Name.tar.gz";
my $V8LibName = "libv8." . $Config{so};
my $V8SrcDir = File::Spec->catdir($SrcDir, $V8Name);
my $V8SrcIncName = File::Spec->catfile($V8SrcDir, "include", "v8.h");
my $V8SrcLibName = File::Spec->catfile($V8SrcDir, $V8LibName);
my $V8DstLibName = File::Spec->catfile($ShareLibDir, $V8LibName);

my @ToCopy = (
    { source => $V8SrcIncName, dest => $ShareIncDir },
    { source => $V8SrcLibName, dest => $ShareLibDir }
);

##############################################################################
#
# Utility subroutines
#
##############################################################################
sub make_shared_directories {
    foreach my $dir (($ShareIncDir, $ShareLibDir)) {
        eval { File::Path::mkpath($dir); };
        die "failed to create directory $dir: $@\n" if ($@);
    }
}

sub check_python_version {
    my $pythonpath = can_run("python") or
        die "As odd as it seems, Python needs to be installed\n";

    my $version = `$pythonpath --version 2>&1`;
    chomp($version);
    
    if ($version =~ /^Python\s(\d)\.(\d)\.(\d)$/) {
        die "Bundled SCons does not run under $version\n" unless
            ($1 == 2);
        die "Bundled SCons needs Python version >= 2.4 (you have $version)\n" if
            ($2 < 4);
    } else {
        warn "Failed to check Python version, assuming it is correct\n";
    }
    
    print "Using $version from $pythonpath\n";
}

##############################################################################
#
# Module::Build actions
#
##############################################################################
sub ACTION_build {
    my $self = shift;
    
    check_python_version();
    
    my $curdir = getcwd;
    
    chdir($SrcDir) or
        die "Failed to chdir to $SrcDir: $!\n";
        
    my $tar = Archive::Tar->new();
    
    # Extract SCons
    if (!-d $SConsDir) {
        print "Extracting $SConsDist\n";
        $tar->read($SConsDist);
        $tar->extract();
    }
    
    # Ensure SCons is executable
    if ($^O ne "MSWin32") {
        chmod(0755, $SConsBin) or
            die "Failed to set permissions on $SConsBin: $!\n";
    }
    
    # Extract V8
    if (!-d $V8SrcDir) {
        print "Extracting $V8Dist\n";
        $tar->read($V8Dist);
        $tar->extract();
    }
    
    # Build V8
    if (exists($Config{ptrsize}) && $Config{ptrsize} == 8) {
        push(@SConsArgs, "arch=x64");
    }
    
    chdir($V8SrcDir) or
        die "Failed to chdir to $V8SrcDir: $!\n";
    
    $ENV{SCONS_LIB_DIR} = $SConsLibDir;
    
    print "Building V8 library\n";
    system("$SConsBin " . join(" ", @SConsArgs)) == 0 or
        die "Failed to build V8\n";
        
    # Stage V8 into share dir
    print "Staging V8 library\n";
    make_shared_directories();
    
    foreach my $tch (@ToCopy) {
        copy($tch->{source}, $tch->{dest}) or
            die "Failed to copy " . $tch->{source} . " to " . $tch->{dest} . "\n";
    }
    
    if ($^O ne "MSWin32") {
        chmod(0755, $V8DstLibName) or
            die "Failed to set permissions on $V8DstLibName: $!\n";
    }
    
    print "V8 library successfully built\n";
    
    chdir($curdir) or
        die "Failed to chdir to $curdir: $!\n";
    
    $self->SUPER::ACTION_build();
}

1;

__END__