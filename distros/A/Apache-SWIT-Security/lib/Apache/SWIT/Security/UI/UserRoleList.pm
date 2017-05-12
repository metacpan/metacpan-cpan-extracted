use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::UI::UserRoleList::Root::Item;
use base 'HTML::Tested::ClassDBI';

sub make_widgets {
	my $class = shift;
	$class->ht_add_widget(::HTV."::Marked", 'name', cdbi_bind => ''
			, cdbi_readonly => 1);
	$class->ht_add_widget(::HTV."::Marked", 'role_name');
	$class->ht_add_widget(::HTV."::Hidden", 'role_id', cdbi_bind => ''
			, is_sealed => 1);
	$class->ht_add_widget(::HTV."::Hidden", 'ht_id'
			, cdbi_bind => 'Primary');
	$class->ht_add_widget(::HTV."::CheckBox"
			, 'check', default_value => [ 1 ]);
}

package Apache::SWIT::Security::UI::UserRoleList::Root;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", 'user_list', __PACKAGE__ . '::Item');

package Apache::SWIT::Security::UI::UserRoleList;
use base qw(Apache::SWIT::HTPage);

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$root->user_list_containee_do(
			query_class_dbi => 'search_all_with_roles');
	my $rcont = $ENV{AS_SECURITY_CONTAINER}->create;
	$_->role_name($rcont->find_role_by_id($_->role_id)->name)
		for grep { $_->role_id } @{ $root->user_list };
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	for my $c (grep { $_->check } @{ $root->user_list }) {
		my $o = $c->cdbi_construct;
		$o->delete_role_id($c->role_id);
	}
	return "r";
}

sub swit_startup {
	my $class = shift;
	$class->ht_root_class->user_list_containee->make_widgets;
	$class->ht_root_class->user_list_containee->bind_to_class_dbi(
			$ENV{AS_SECURITY_USER_CLASS});
}

1;
