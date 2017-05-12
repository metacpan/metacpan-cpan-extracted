use strict;
use warnings FATAL => 'all';

package T::Empty::Root;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Marked", 'first');
__PACKAGE__->ht_add_widget(::HTV."::Form", form => default_value => 'u');

package T::Empty;
use base qw(Apache::SWIT::HTPage);

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	return "r";
}

1;

