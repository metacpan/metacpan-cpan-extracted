use strict;
use warnings;
use Test::More;
use Pod::Simple::Text;
use Data::Graph::Shared;

# Extract SYNOPSIS block from the .pm POD and compile it (`perl -c`).
# Catches drift between POD examples and the real API.

my $pm = $INC{'Data/Graph/Shared.pm'};
ok $pm && -f $pm, "module file found: $pm";

open my $fh, '<', $pm or die $!;
my $src = do { local $/; <$fh> };
close $fh;

my ($synopsis) = $src =~ /=head1\s+SYNOPSIS\s*\n(.+?)(?=^=head1\s)/ms;
ok $synopsis, 'SYNOPSIS section exists';

# Strip POD markup and keep only 4-space indented code blocks.
my @code_lines;
for my $ln (split /\n/, $synopsis) {
    push @code_lines, $1 if $ln =~ /^    (.*)$/;
}
my $code = join("\n", @code_lines);
ok length($code) > 0, 'SYNOPSIS has code examples';

# Syntax-check only: wrap in a sub so we don't run side effects,
# but Perl still parses the body. `use` is hoisted at parse time
# which is what we want to verify.
# SYNOPSIS is documentation — not necessarily self-contained; undeclared
# variables that represent "given some $fd you obtained elsewhere" are OK.
# We only check the code parses (catches missing parens, bad method sig, etc).
my $harness = "no strict 'vars'; no warnings; use feature ':5.10'; " .
              "sub _synopsis_check {\n" .
              "use Data::Graph::Shared;\n" .
              $code . "\n}\n 1;\n";
my $rc = eval "$harness";
ok $rc, 'SYNOPSIS parses' or diag $@;

done_testing;
