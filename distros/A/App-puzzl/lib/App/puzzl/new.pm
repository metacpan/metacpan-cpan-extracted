use strict;
use v5.28;
package App::puzzl::new;
use Exporter 'import';
use File::Path qw(make_path);

sub new_day {
	my ($day) = @_;

	make_path('days');

	open(my $code, '>', "days/day$day.pl") or die "failed to open file days/$day.pl";

	print $code <<'EOF';
use strict;
use v5.28;

sub part1 {
	my ($input_fh) = @_;
}

sub part2 {
	my ($input_fh) = @_;
}
EOF
	close($code);
}

our @EXPORT_OK = qw(new_day);

1;