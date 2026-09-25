use strict;
use warnings;
use Test::More;
use Pod::Simple::Text;
use Data::ReqRep::Shared;

my $pm = $INC{'Data/ReqRep/Shared.pm'};
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

# Syntax-check only: wrap in a sub so we don't run side effects.
# SYNOPSIS is not necessarily self-contained; undeclared variables are OK.
my $harness = "no strict 'vars'; no warnings; use feature ':5.10'; " .
              "sub _synopsis_check {\n" .
              "use Data::ReqRep::Shared;\n" .
              $code . "\n}\n 1;\n";
my $rc = eval "$harness";
ok $rc, 'SYNOPSIS parses' or diag $@;

done_testing;
