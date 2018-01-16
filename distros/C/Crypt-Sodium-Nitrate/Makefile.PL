
use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::CBuilder;
use Getopt::Std;
use Config;

my $aliensodium_version = '1.0.8.0';

my %opts;
getopt('L:I:', \%opts) or die usage();

my @defines;
my @dirs;
my $include_dirs;

if ( $opts{L} && $opts{I} ) {
    @dirs = $opts{L};
    $include_dirs = "-I$opts{I}";

    die "Could not locate sodium.h in $opts{I}\n"
        unless -e "$opts{I}/sodium.h";
} else {
    require Alien::Sodium;
    require File::Spec;
    require File::ShareDir;
    require Text::ParseWords;

    my $libsodium = Alien::Sodium->new;

    $include_dirs = $libsodium->cflags;

    @dirs = map { s/^-L//g; $_ } grep { /^-L/ } Text::ParseWords::shellwords($libsodium->libs);

    # NOTE: since Alien::Sodium v1.0.3.1 it may not be needed anymore
    push @dirs, File::Spec->catdir( File::ShareDir::dist_dir("Alien-Sodium"), 'lib' );

    # NOTE: some smokers still cannot find libsodium.a, but don't add it yet, as
    # the updated Alien::Base could have fixed that
    # push @dirs, map { "$_/.libs/" } grep { /_alien/ } @dirs;
}

my $lib_ext = $Config{lib_ext};
my $libsodium_lib = "libsodium${lib_ext}";
my $libsodium_path;

for my $dir ( @dirs ) {
    if ( -e "$dir/$libsodium_lib" ) {
        $libsodium_path = "$dir/$libsodium_lib";
        last;
    }
}

die "Is Alien::Sodium available? Could not locate $libsodium_lib in @dirs\n"
    unless $libsodium_path;

WriteMakefile(
    ABSTRACT_FROM  => 'lib/Crypt/Sodium/Nitrate.pm', # retrieve abstract from module
    AUTHOR         => [
        "Brian Fraser (brian.fraser at booking.com)",
        "Gonzalo Diethelm (gonzalo.diethelm at booking.com)",
    ],
    CONFIGURE_REQUIRES => {
        "File::ShareDir" => 0,
        "File::Spec" => 0,
        "Alien::Sodium" => $aliensodium_version,
        "Alien::Base::ModuleBuild" => 0,
        "ExtUtils::MakeMaker" => 0,
    },
    DISTNAME  => "Crypt-Sodium-Nitrate",
    DEFINE    => join(" ", map { "-D$_" } @defines),
    EXE_FILES => [],
    MYEXTLIB  => $libsodium_path,
    INC       => join(' ', "-I.", $include_dirs),
    LICENSE   => "perl",
    NAME      => "Crypt::Sodium::Nitrate",
    PREREQ_PM => {
        "Alien::Sodium" => $aliensodium_version,
        "Carp"          => 0,
        "XSLoader"      => 0,
        "strict"        => 0,
        "warnings"      => 0
    },
    TEST_REQUIRES => {
        "Test::More"      => 0,
        "Test::Exception" => 0,
    },
    VERSION_FROM     => 'lib/Crypt/Sodium/Nitrate.pm',
    test => {
        "TESTS" => "t/*.t"
    }
);

sub usage {
    return "Example usage:\n"
        ."\tperl $0 -L /usr/lib/x86_64-linux-gnu/ -I /usr/include/\n"
}



