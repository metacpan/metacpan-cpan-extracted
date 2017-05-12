use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton::HT::Page;
use base 'Apache::SWIT::Maker::Skeleton::Page';

sub template { return <<'ENDS' };
use strict;
use warnings FATAL => 'all';

package [% class_v %];
use base qw(Apache::SWIT::HTPage);

sub swit_startup {
	my $rc = shift()->ht_make_root_class;
	$rc->ht_add_widget(::HTV."::Marked", 'first');
	$rc->ht_add_widget(::HTV."::Form", form => default_value => 'u');
}

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	return "r";
}

1;
ENDS

1;

