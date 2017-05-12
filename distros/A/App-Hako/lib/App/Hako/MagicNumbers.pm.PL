#!/usr/bin/perl
use strict;

my ($outfile) = @ARGV or die "usage: $0 <output-filename>\n";
open my $OUT, '>', $outfile or die "cannot open $outfile: $!\n";

# Default values. Try to fix syscalls below.
my %magic = (
    SYS_unshare => 272,
    SYS_mount => 165,
    MS_BIND => 4096,
    CLONE_NEWNS => 0x20000,
    CLONE_NEWUSER => 0x10000000,
    CLONE_NEWNET => 0x40000000,
);

my @names = sort keys %magic;

# TODO: try to find and convert header files.

eval {
    require "syscall.ph";
    $magic{SYS_unshare} = SYS_unshare();
    $magic{SYS_mount} = SYS_mount();
};

eval {
    require "linux/sched.ph";
    $magic{CLONE_NEWNS} = CLONE_NEWNS();
    $magic{CLONE_NEWUSER} = CLONE_NEWUSER();
    $magic{CLONE_NEWNET} = CLONE_NEWNET();
};

eval {
    require "sys/mount.ph";
    $magic{MS_BIND} = MS_BIND();
};


print $OUT <<'EOH';
package App::Hako::MagicNumbers;
use strict;
require Exporter;
our @ISA = qw(Exporter);
use constant {
EOH

print $OUT  "$_ => $magic{$_},\n" for @names;
print $OUT  "};\n";
print $OUT  "our \@EXPORT = qw/ @names /;\n";

close $OUT or die "cannot close $outfile: $!\n";

