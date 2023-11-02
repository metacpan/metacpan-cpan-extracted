use strict;
use warnings;

use Test::More;

# ABSTRACT: Ensure wrap lengths are expected.

use CPAN::Changes;

# Text::Wrap has a default columns= value of 76
# But in practice, this means a string length of 75, because Text::Wrap *includes* \n in its string
# length calculation. Or its an off-by-one error somewhere.
my $limit  = 75;
# There are a lot of steps here because it turns out, Text::Wrap is hateful
# and unclear.
# Offsets do not include trailing \n like vim does.
my $source = <<'EOF';
0.1.2 - 2015-06-21
 - nowrap x:68 characters long potato salmon farm test seagull xxxxx
 - nowrap x:72 characters long potato salmon farm test elephant xxxxxxxx
 - wrap x:73 characters long potato salmon farm test elephant xxxxxxxxxxx
 - wrap x:74 characters long potato salmon farm test elephant xxxxxxxxxxxx
 - wrap x:75 characters long potato salmon farm test elephant xxxxxxxxxxxxx
 - wrap x:76 characters long potato salmon farm test mammoth elephant xxxxxx
 - wrap x:77 characters long potato salmon farm test mammoth elephant xxxxxxx
 - wrap x:78 characters long potato salmon farm test mammoth elephant xxxxxxxx
 - wrap x:80 characters long potato salmon farm test mammoth elephant xxxxxxxxxx
EOF

my $reflow = CPAN::Changes->load_string($source)->serialize();
my @lines = split /\n/, $reflow;

note explain \@lines;

my $lineno = 0;
for my $line ( @lines ) {
    $lineno++;
    my ( $wrap, $wraplength ) = $line =~ /\A\s*-\s*(nowrap|wrap)\s+x:(\d+)\s+/;
    next unless defined $wrap;    # Skip the wrapped tail of each line

    next
      if cmp_ok( length $line, '<=', $limit,
        "Line $lineno expected <= wrap limit $limit" );

    diag "Wrapped Line is: \'$line\'";
}

done_testing;
