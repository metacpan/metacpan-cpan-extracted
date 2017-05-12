#!/usr/bin/env perl
use warnings;
use strict;
use autodie;
use Data::Dumper;
chomp(my $path = qx(perldoc -l perlvar));
my %is_var = map { $_ => "\$$_" } '_', 0 .. 9;
open my $fh, '<', $path;
while (<$fh>) {
    $is_var{$_} = $_ for /X<([\$\@%]\S+?)>/g;
}
close $fh;
for my $key (keys %is_var) {

    # %SIG can also be found as SIG etc. Need at least two word
    # characters; finding '$^H' with 'H' appears a bit too random.
    if ($key =~ /(\w{2,})/) {
        $is_var{$1} = $key;
    }
}
print Data::Dumper->Dump([ \%is_var ], ['*is_var']);
