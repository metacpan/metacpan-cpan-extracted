use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/lib";

use INA_CPAN_Check qw(ok diag plan_tests);

my $pm = -f 'lib/CSV/LINQ.pm' ? 'lib/CSV/LINQ.pm' : '../lib/CSV/LINQ.pm';
open(PM, $pm) or die "Cannot open $pm: $!";
my $src = do { local $/; <PM> };
close(PM);

my @tests_def = ();
my @results    = ();

# P1: no 'say' keyword
push @tests_def, ['P1: no say keyword', sub { $src !~ /\bsay\b/ }];

# P2: no '//' (defined-or)
push @tests_def, ['P2: no defined-or //', sub { $src !~ m{(?<![:/])//} }];

# P3: no 'given'/'when' (in code, not POD)
push @tests_def, ['P3: no given/when', sub {
    my $code = $src;
    $code =~ s/^=\w.*?^=cut\n//gsm;  # strip POD
    $code !~ /\b(?:given|when)\b/;
}];

# P4: no 'state'
push @tests_def, ['P4: no state', sub { $src !~ /\bstate\b/ }];

# P5: no 3-arg open in main code (open FH, mode, file)
push @tests_def, ['P5: no 3-arg open', sub {
    my $s = $src;
    $s =~ s/#.*//gm;
    $s !~ /open\s*\(\s*\w+\s*,\s*['"](?:>|<|>>)['"]\s*,/;
}];

# P6: warnings stub present
push @tests_def, ['P6: warnings stub', sub {
    $src =~ /warnings::import/ || $src =~ /INC.*warnings/;
}];

# P7: use vars (not 'our')
push @tests_def, ['P7: use vars not our', sub {
    $src !~ /^our\s+/m;
}];

# P8: VERSION self-assignment
push @tests_def, ['P8: VERSION self-assign', sub {
    $src =~ /\$VERSION\s*=\s*\$VERSION/;
}];

# P9: no lexical filehandle open(my $fh, ...)
push @tests_def, ['P9: no open(my $fh)', sub {
    $src !~ /open\s*\(\s*my\s+\$\w+\s*,/;
}];

# P10: CVE-2016-1238 mitigation
push @tests_def, ['P10: pop @INC mitigation', sub {
    $src =~ /pop\s+\@INC/ || $src =~ /INC\[-1\]/;
}];

# P11: no 'use feature'
push @tests_def, ['P11: no use feature', sub {
    $src !~ /^use\s+feature\b/m;
}];

# P12: no 'use 5.' version pragma
push @tests_def, ['P12: no use 5.x pragma', sub {
    $src !~ /^use\s+5\./m;
}];

plan_tests(scalar @tests_def);

for my $t (@tests_def) {
    my($name, $code) = @{$t};
    my $result = eval { $code->() };
    ok($result && !$@, $name);
}
