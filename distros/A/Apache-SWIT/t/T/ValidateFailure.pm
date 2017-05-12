use strict;
use warnings FATAL => 'all';

package T::ValidateFailure::Root;
use base 'HTML::Tested';

sub ht_validate { return qw(hoho); }

package T::ValidateFailure;
use base 'Apache::SWIT::HTPage';
use File::Slurp;

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	my $a;
	my $should_die_here = $a . "a";
	return $root;
}

sub ht_swit_update {
	my ($class, $r) = @_;
	write_file("/tmp/apache_swit_validate_failure", "");
	return "r";
}

1;
