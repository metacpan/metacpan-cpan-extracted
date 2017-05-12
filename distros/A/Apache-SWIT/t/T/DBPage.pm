use strict;
use warnings FATAL => 'all';

package T::DBPage::DB;
use base 'Apache::SWIT::DB::Base';
__PACKAGE__->set_up_table('dbp');

package T::DBPage;
use base 'Apache::SWIT::HTPage';
use HTML::Tested qw(HTV HT);

sub swit_startup {
	my $rc = shift()->ht_make_root_class('HTML::Tested::ClassDBI');
	$rc->ht_add_widget(HTV."::Hidden", id => cdbi_bind => 'Primary');
	$rc->ht_add_widget(HTV."::EditBox", val => cdbi_bind => '');
	$rc->ht_add_widget(HTV."::DropDown", 'sel');
	$rc->ht_add_widget(HTV."::Marked", dt => is_datetime => 1);
	$rc->bind_to_class_dbi("T::DBPage::DB");
	my $c = $rc->ht_add_widget(HT."::List", 'arr')->containee;
	$c->ht_add_widget(HTV."::Marked", "val");
}

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$root->cdbi_load;
	$root->arr([ $root->arr_containee->new({ val => $root->val }) ]);
	$root->sel([ [ 1, $root->val || "ded" ], [ 2, 'baba', 1 ] ]);
	$root->dt(DateTime->now);
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	$root->cdbi_create_or_update;
	return $root->ht_make_query_string("r", "id");
}

1;
