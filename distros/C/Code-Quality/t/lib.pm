package t::lib;
use v5.14;
use warnings;

our $reference = <<'EOF';
#include <stdio.h>

int main(void) {
	int a, b;
	scanf("%d%d", &a, &b);
	printf("%d\n", a + b);
	return 0;
}
EOF

our $long_code = <<'EOF';
#include <stdio.h>
#include <time.h>

int main(void) {
	int time_start;
	int a, b, c;
	time_start = time(NULL);
	scanf("%d%d", &a, &b);
	c = a + b;
	if (c == a + b) {
		printf("%d\n", c);
	} else
		puts("FATAL ERROR: addition failed");
	fprintf(stderr, "time taken: %ld", time(NULL) - time_start);
	return 0;
}
EOF

our $long_code_with_bug = $long_code =~ s/%ld/%d/r;

1;
