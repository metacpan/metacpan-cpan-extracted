use strict;
use warnings;
use Test::More;
use Data::Graph::Shared;

my $v = Data::Graph::Shared->VERSION;
ok $v, 'VERSION defined';
like $v, qr/^\d+\.\d+$/, 'VERSION is X.YY';

# MANIFEST must not contain stale entries not in git (and vice-versa,
# but MANIFEST.SKIP makes reverse check noisy). Minimal: MANIFEST exists
# and includes the .pm file.
my $module_root = do {
    my $p = $INC{'Data/Graph/Shared.pm'};
    $p =~ s{/blib/.*$}{};
    $p =~ s{/lib/.*$}{};
    $p;
};
SKIP: {
    skip 'MANIFEST not shipped in installed module', 1
        unless -f "$module_root/MANIFEST";
    open my $fh, '<', "$module_root/MANIFEST" or die $!;
    my %lines;
    while (my $line = <$fh>) {
        $lines{$1}++ if $line =~ /^(\S+)/;
    }
    close $fh;
    ok exists $lines{'lib/Data/Graph/Shared.pm'}, 'MANIFEST includes .pm';
}

done_testing;
