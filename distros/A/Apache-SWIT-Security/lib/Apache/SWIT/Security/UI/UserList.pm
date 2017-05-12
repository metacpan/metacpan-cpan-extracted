use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::UI::UserList::Root::Item;
use base 'HTML::Tested::ClassDBI';

sub make_widgets {
	my $class = shift;
	$class->ht_add_widget(::HTV . "::Marked", 'name', cdbi_bind => ''
			, cdbi_readonly => 1);
	$class->ht_add_widget(::HTV."::Hidden"
			, ht_id => cdbi_bind => 'Primary');
	$class->ht_add_widget(::HTV."::CheckBox"
			, check => default_value => [ 1 ]);
}

package Apache::SWIT::Security::UI::UserList::Root;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", 'user_list', __PACKAGE__ . '::Item');
__PACKAGE__->ht_add_widget(::HTV."::DropDown", 'role_sel');

package Apache::SWIT::Security::UI::UserList;
use base qw(Apache::SWIT::HTPage);

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$root->user_list_containee_do(query_class_dbi => 'retrieve_all');
	$root->role_sel([ [ 0, 'Select Role' ]
		, $ENV{AS_SECURITY_CONTAINER}->create->roles_list ]);
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	my @objs = map { $_->cdbi_construct }
			grep { $_->check } @{ $root->user_list };
	my $rs = $root->role_sel;
	my ($op, @args) = $rs ? ('add_role_id', ($rs)) : ('delete', ());
	$_->$op(@args) for @objs;
	return $rs ? "../userrolelist/r" : "r";
}

sub swit_startup {
	my $class = shift;
	$class->ht_root_class->user_list_containee->make_widgets;
	$class->ht_root_class->user_list_containee->bind_to_class_dbi(
		$ENV{AS_SECURITY_USER_CLASS});
}

1;
