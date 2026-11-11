use 5.018;
use strict;
use warnings;
use Test::More;
use Data::Dump::Streamer ();

# PAUSE reads version assignments without executing module code. Keep the
# release versions as simple literals rather than chained assignments.
open my $source, '<', 'lib/Data/Dump/Streamer.pm'
    or die "Cannot read module source: $!";
my ($package, %assignments);
while (my $line= <$source>) {
    last         if $line =~ /^__(?:END|DATA)__\b/;
    $package= $1 if $line =~ /^package\s+([\w:]+)\s*;/;
    if ($line =~ /^\s*(?:our\s+)?\$VERSION\s*=(?!=)/) {
        $assignments{$package} ||= $line;
    }
}
close $source or die "Cannot close module source: $!";

for my $name ('Data::Dump::Streamer', 'Data::Dump::Streamer::Deparser') {
    my $version= $name->VERSION;
    my $literal= qr/(?:'\Q$version\E'|"\Q$version\E"|\Q$version\E)/;
    like(
        $assignments{$name} || '',
        qr/^\s*(?:our\s+)?\$VERSION\s*=\s*$literal\s*;\s*$/,
        "$name has a PAUSE-compatible literal version assignment"
    );
}

done_testing;
