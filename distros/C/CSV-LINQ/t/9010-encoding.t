use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use INA_CPAN_Check qw(ok diag plan_tests);

my @manifest = ();
{
    open(MF, '../MANIFEST') or open(MF, 'MANIFEST') or die "Cannot open MANIFEST: $!";
    while (<MF>) {
        chomp;
        s/\s.*//;
        push @manifest, $_ if length $_;
    }
    close(MF);
}

my @check = grep { !m{^doc/} } @manifest;
plan_tests(scalar @check);

for my $file (@check) {
    my $path = -f $file ? $file : "../$file";
    unless (-f $path) {
        ok(1, "$file (not found, skip)");
        next;
    }
    open(FH, $path) or do { ok(0, "$file (cannot open: $!)"); next };
    my $ok = 1;
    my $line = 0;
    while (<FH>) {
        $line++;
        if (/[^\x00-\x7F]/) {
            $ok = 0;
            last;
        }
    }
    close(FH);
    ok($ok, "$file US-ASCII" . ($ok ? '' : " (non-ASCII at line $line)"));
}
