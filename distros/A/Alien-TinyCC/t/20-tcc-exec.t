use strict;
use warnings;
use Test::More;

use Alien::TinyCC;

# tcc should just be in my path, so let's build a c file and run it
open my $out_fh, '>', 'test.c';
print $out_fh <<'EOF';
/* If this seems pedantic, see this test report:
 * http://www.cpantesters.org/cpan/report/ea8944fc-0f24-11e3-b8b2-96b61dda783b
 * and this note about needing stdarg for older gcc's:
 * http://www.winehq.org/pipermail/wine-patches/2009-December/083364.html
 */
#include <stdarg.h>

#include <stdio.h>

int main() {
	printf("Good to go");
	return 0;
}

EOF
close $out_fh;

END {
	unlink 'test.c';
}

my $results = `tcc -run test.c`;
is($results, 'Good to go', 'tcc compiled the code correctly')
	or diag(join("\n", "tcc printed [$results]",
		"tcc configuration:",
		scalar(`tcc -print-search-dirs`),
	));

done_testing;
