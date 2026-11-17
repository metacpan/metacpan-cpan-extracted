#!/usr/bin/env perl
use strict;
use warnings;

# dzil build hook (dist.ini, [Run::AfterBuild]): put a capability check at
# the head of the Makefile.PL in the build directory given as the argument.
#
# DBIO::Forked forks one process per query, so a perl without a real fork()
# ($Config{d_fork} unset; a pseudo-fork emulated with threads, as in Strawberry
# Perl) cannot run it. "OS unsupported" is what CPAN Testers reads as NA
# instead of FAIL. [AssertOS] would decide on the operating system's name; the
# capability is what matters here, and it is not a name.

my $dir = shift // die "usage: $0 BUILD_DIR\n";
my $file = "$dir/Makefile.PL";

open my $in, '<', $file or die "$file: $!\n";
my $text = do { local $/; <$in> };
close $in;

die "$file: already carries the fork check\n" if $text =~ /\$Config::Config\{d_fork\}/;

my $check = <<'PERL';
BEGIN {
  require Config;
  die "OS unsupported: this perl has no real fork() (\$Config{d_fork} is not set), DBIO::Forked forks one process per query\n"
    unless $Config::Config{d_fork};
}

PERL

# After the generated-file comment, before the first statement.
$text =~ s/^(?=use strict;)/$check/m
  or die "$file: no 'use strict;' to put the check before\n";

open my $out, '>', $file or die "$file: $!\n";
print {$out} $text;
close $out or die "$file: $!\n";
