use strict;
use warnings;
use Test::More;
use Pod::Simple::Text;
use Data::HashMap::Shared;

# Compile the SYNOPSIS code to catch drift between the POD examples and the real
# API.

my $pm = $INC{'Data/HashMap/Shared.pm'};
ok $pm && -f $pm, "module file found: $pm";

open my $fh, '<', $pm or die $!;
my $src = do { local $/; <$fh> };
close $fh;

my ($synopsis) = $src =~ /=head1\s+SYNOPSIS\s*\n(.+?)(?=^=head1\s)/ms;
ok $synopsis, 'SYNOPSIS section exists';

my @code_lines;
for my $ln (split /\n/, $synopsis) {
    push @code_lines, $1 if $ln =~ /^    (.*)$/;
}
my $code = join("\n", @code_lines);
ok length($code) > 0, 'SYNOPSIS has code examples';

# Syntax check only: wrapped in a sub so nothing runs, while `use` is still
# hoisted at parse time. The SYNOPSIS need not be self-contained: undeclared
# variables (an $fd obtained elsewhere) are fine.
my $harness = "no strict 'vars'; no warnings; use feature ':5.10'; " .
              "sub _synopsis_check {\n" .
              "use Data::HashMap::Shared;\n" .
              $code . "\n}\n 1;\n";
my $rc = eval "$harness";
ok $rc, 'SYNOPSIS parses' or diag $@;

done_testing;
