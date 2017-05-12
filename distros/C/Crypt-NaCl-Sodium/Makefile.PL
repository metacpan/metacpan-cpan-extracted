
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

my $cb = ExtUtils::CBuilder->new( quiet => 1 );
push @defines, "AES256GCM_IS_AVAILABLE" if check_if_aes_is_available();

my %WriteMakefileArgs = (
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Crypt/NaCl/Sodium.pm', # retrieve abstract from module
       AUTHOR         => "Alex J. G. Burzy\x{144}ski <ajgb\@cpan.org>") : ()),
  "BUILD_REQUIRES" => {
    "ExtUtils::CBuilder" => 0,
  },
  "CONFIGURE_REQUIRES" => {
    "File::ShareDir" => 0,
    "File::Spec" => 0,
    "Alien::Sodium" => $aliensodium_version,
    "ExtUtils::MakeMaker" => "0",
    "ExtUtils::CBuilder" => 0,
  },
  "DISTNAME" => "Crypt-NaCl-Sodium",
  "DEFINE" => join(" ", map { "-D$_" } @defines),
  "EXE_FILES" => [],
  "MYEXTLIB"  => $libsodium_path,
  "INC"       => join(' ', "-I.", $include_dirs),
  "LICENSE" => "perl",
  "NAME" => "Crypt::NaCl::Sodium",
  "PREREQ_PM" => {
    "Alien::Sodium" => $aliensodium_version,
    "Carp" => 0,
    "Sub::Exporter" => 0,
    "XSLoader" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0,
  },
  "VERSION_FROM"     => 'lib/Crypt/NaCl/Sodium.pm',
  "test" => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "Alien::Sodium" => $aliensodium_version,
  "Carp" => 0,
  "Sub::Exporter" => 0,
  "Test::More" => 0,
  "XSLoader" => 0,
  "strict" => 0,
  "warnings" => 0
);

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

sub usage {
    return "Example usage:\n"
        ."\tperl $0 -L /usr/lib/x86_64-linux-gnu/ -I /usr/include/\n"
}

sub check_if_aes_is_available {
    my $test_file_name = "aes-test.c";
    open( my $test_file, ">", $test_file_name) or die("Cannot write $test_file_name: $!");
    print $test_file <<'EOF';
#include <stdio.h>
#include "sodium.h"

int main(int argc, char **argv) {
    int ic, rc;
    ic = sodium_init();
    rc = crypto_aead_aes256gcm_is_available();
    printf("AES256GCM %s available\n", rc ? "is" : "is not");
    exit( rc ? 0 : 1 );
}
EOF

    close($test_file);

    my @include_dirs = map { s/^\s+//; s/\s+$//; $_ } grep { length } split(/\-I/, $include_dirs);

    my $file_obj = eval {
        $cb->compile(
            source => $test_file_name,
            include_dirs => [ '.', @include_dirs ],
        );
    };
    unlink $test_file_name;

    return unless $file_obj;

    my $file_exe = eval {
        $cb->link_executable(
            objects => $file_obj,
            extra_linker_flags => $libsodium_path,
        );
    };
    unlink $file_obj;

    return unless $file_exe;

    my $rv = system("./$file_exe");
    unlink $file_exe;

    return $rv == 0;
}

