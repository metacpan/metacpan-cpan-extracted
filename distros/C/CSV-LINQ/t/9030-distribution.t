use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use INA_CPAN_Check qw(ok diag plan_tests);

my @tests_def = ();

sub slurp {
    my $f = shift;
    open(SL, $f) or return '';
    my $c = do { local $/; <SL> };
    close SL;
    return $c;
}

my $root = -f 'MANIFEST' ? '.' : '..';
my $pm   = "$root/lib/CSV/LINQ.pm";

# A1: MANIFEST exists
push @tests_def, sub { ok(-f "$root/MANIFEST",    'A1: MANIFEST exists') };
push @tests_def, sub { ok(-f "$root/Changes",      'A2: Changes exists') };
push @tests_def, sub { ok(-f "$root/README",       'A3: README exists') };
push @tests_def, sub { ok(-f "$root/LICENSE",      'A4: LICENSE exists') };
push @tests_def, sub { ok(-f "$root/SECURITY.md",  'A5: SECURITY.md exists') };
push @tests_def, sub { ok(-f "$root/CONTRIBUTING", 'A6: CONTRIBUTING exists') };

# B: version consistency
my $pm_ver = do {
    my $s = slurp($pm);
    $s =~ /\$VERSION\s*=\s*'([^']+)'/ ? $1 : '';
};
my $changes_ver = do {
    my $s = slurp("$root/Changes");
    $s =~ /^(\d+\.\d+)\s/m ? $1 : '';
};

push @tests_def, sub { ok(length($pm_ver),                         'B1: pm VERSION defined') };
push @tests_def, sub { ok($pm_ver eq $changes_ver,                  "B2: pm/Changes version match ($pm_ver vs $changes_ver)") };

# C: MANIFEST lists lib/CSV/LINQ.pm first
my @mf = do {
    open(MF, "$root/MANIFEST") or return;
    my @l = grep { /\S/ } map { chomp; $_ } <MF>;
    close MF;
    @l;
};
push @tests_def, sub { ok($mf[0] eq 'lib/CSV/LINQ.pm', 'C1: MANIFEST first line is lib/CSV/LINQ.pm') };

# D: MANIFEST files all exist
for my $f (@mf) {
    push @tests_def, sub { ok(-f "$root/$f", "D: $f exists") };
}

# E: lib/CSV/LINQ.pm has NAME/VERSION/SYNOPSIS POD
my $pm_src = slurp($pm);
push @tests_def, sub { ok($pm_src =~ /^=head1\s+NAME/m,     'E1: POD NAME') };
push @tests_def, sub { ok($pm_src =~ /^=head1\s+VERSION/m,  'E2: POD VERSION') };
push @tests_def, sub { ok($pm_src =~ /^=head1\s+SYNOPSIS/m, 'E3: POD SYNOPSIS') };
push @tests_def, sub { ok($pm_src =~ /^=head1\s+AUTHOR/m,   'E4: POD AUTHOR') };

# F: Changes has version entry matching pm VERSION
push @tests_def, sub {
    my $s = slurp("$root/Changes");
    ok($s =~ /^$pm_ver\b/m, "F1: Changes has $pm_ver entry");
};

plan_tests(scalar @tests_def);
$_->() for @tests_def;
