#!/usr/bin/perl

use strict;
use warnings;

# Sorry, can't use Test::More here...
# use Test::More tests => 6;

print "1..6\n";

our $base;

my $prefix = "";

if ( -d "t" ) {
    $prefix = "t/";
}

{ package PlayTab;
  use App::Music::PlayTab;
  run( "-test",
       "-output", "${prefix}${base}test.ps",
       "-preamble", "${prefix}dummy.pre",
       "${prefix}${base}.ptb",
     );
}

my $ok = !differ ("${prefix}${base}test.ps", "${prefix}${base}.ps");
unlink ("${prefix}test.ps") if $ok;
print $ok ? "" : "not ", "ok 6\n";

# Compare two text files, ignoring line endings.
sub differ {
    my ($file1, $file2) = @_;
    my ($str1, $str2);
    local($/);
    open(my $fd1, "<:raw", $file1) or die("$file1: $!\n");
    $str1 = <$fd1>;
    close($fd1);
    open(my $fd2, "<:raw", $file2) or die("$file2: $!\n");
    $str2 = <$fd2>;
    close($fd2);
    $str1 =~ s/[\n\r]+/\n/g;
    $str2 =~ s/[\n\r]+/\n/g;
    return 0 if $str1 eq $str2;
    1;
}
