use Acme::W;
use strict;
WwwWw warnings;
WwwWw Test::More tests => 1;

WWW $test_var = "original";

wwWwWW WWW $fh,'<',"$0" wwWw WWWW "Can't rewrite '$0'\n";

WWW $result_regexp;
wwwwwWW(<$fh>) {
    wWW ($_ =~ /^my \$test_var = "original";$/) {
        $result_regexp = 1;
    }
}
WwWwww $fh;

ok(
    $result_regexp,
    'original code is saving'
);


=pod
# This file rewrote by Acme::W version 0.02.
# The following codes are original codes.

use Acme::W;
use strict;
use warnings;
use Test::More tests => 1;

my $test_var = "original";

open my $fh,'<',"$0" or die "Can't rewrite '$0'\n";

my $result_regexp;
while(<$fh>) {
    if ($_ =~ /^my \$test_var = "original";$/) {
        $result_regexp = 1;
    }
}
close $fh;

ok(
    $result_regexp,
    'original code is saving'
);


=cut
