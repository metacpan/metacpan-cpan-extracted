#!/usr/bin/env perl
use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;
use File::Spec;
use File::Temp;

# patches welcome
die "OS unsupported\n" if $^O eq 'MSWin32';

my %WriteMakefileArgs = (
  "ABSTRACT" => "perl XS bindings for TweetNaCl",
  "AUTHOR" => "Brad Barden <perlmodules\@5c30.org>",
  "DISTNAME" => "Crypt-NaCl-Tweet",
  "INC" => $ENV{AUTHOR_MODE} ? "-Wall -Wextra" : '',
  "LICENSE" => "perl",
  "NAME" => "Crypt::NaCl::Tweet",
  "MIN_PERL_VERSION" => "5.001000",
  "MYEXTLIB" => "tweetnacl$Config{lib_ext}",
  "PREREQ_PM" => {
    "XSLoader" => 0,
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88",
  },
  VERSION_FROM => "lib/Crypt/NaCl/Tweet.pm",
  "depend" => { '$(OBJECT)' => '$(MYEXTLIB)' },
  "test" => {
    "TESTS" => "t/*.t"
  },
);

my %FallbackPrereqs = (
  "Test::More" => "0.88",
  "XSLoader" => 0,
  "strict" => 0,
  "warnings" => 0
);

my $eumm_version = eval { $ExtUtils::MakeMaker::VERSION };
delete $WriteMakefileArgs{TEST_REQUIRES} if $eumm_version < 6.64;
$WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs if $eumm_version < 6.64;
delete $WriteMakefileArgs{BUILD_REQUIRES} if $eumm_version < 6.56;
delete $WriteMakefileArgs{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
delete $WriteMakefileArgs{META_MERGE} if $eumm_version < 6.46;
delete $WriteMakefileArgs{LICENSE} if $eumm_version < 6.31;
delete $WriteMakefileArgs{MIN_PERL_VERSION} if $eumm_version < 6.48;

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  return <<EOMAKE;
\$(MYEXTLIB): tweetnacl$Config{obj_ext}
	\$(AR) \$(ARFLAGS) \$(MYEXTLIB) tweetnacl$Config{obj_ext}
EOMAKE
}

# NB: has to take command as a string (cflags etc need tokenization)
sub _c_compile_test {
  my ($src, $cmd) = @_;
  my $tmpdir = File::Temp->newdir;
  my $c = File::Spec->catfile($tmpdir, "input.c");
  open(my $fh, '>', $c) or die "$c: open: $!";
  print $fh $src or die "$c: print: $!";
  close($fh) or die "$c: close: $!";
  $cmd .= " -o /dev/null $c";
  return system($cmd) == 0;
}
