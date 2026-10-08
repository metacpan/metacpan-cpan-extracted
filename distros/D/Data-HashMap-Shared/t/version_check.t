use strict;
use warnings;
use Test::More;
use Data::HashMap::Shared;

my $v = Data::HashMap::Shared->VERSION;
ok $v, 'VERSION defined';
like $v, qr/^\d+\.\d+$/, 'VERSION is X.YY';

# Minimal MANIFEST check; a reverse check against git is noisy with
# MANIFEST.SKIP.
my $module_root = do {
    my $p = $INC{'Data/HashMap/Shared.pm'};
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
    ok exists $lines{'lib/Data/HashMap/Shared.pm'}, 'MANIFEST includes .pm';
}

# Every variant must declare the main module's version, or a release bumping
# only the main .pm leaves the variant packages indexed at the previous release.
for my $variant (qw(II IS SI SS I16 I16S I32 I32S SI16 SI32)) {
    my $class = "Data::HashMap::Shared::$variant";
    unless (eval "require $class; 1") { fail("load $class: $@"); next }
    is $class->VERSION, $v, "$class VERSION matches the main module";
}

done_testing;
