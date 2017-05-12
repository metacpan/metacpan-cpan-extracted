use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::UI::Login;
use base qw(Apache::SWIT::HTPage);
use Apache::SWIT::Security qw(Hash);

sub swit_startup {
	my $rc = shift()->ht_make_root_class;
	$rc->ht_add_widget(::HTV."::EditBox", 'username');
	$rc->ht_add_widget(::HTV."::PasswordBox", 'password');
	$rc->ht_add_widget(::HTV."::Hidden", 'redirect'
		, default_value => '../result/r');
	$rc->ht_add_widget(::HTV, $_) for qw(failed logout);
}

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$r->pnotes('SWITSession')->delete_user if $root->logout;
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	my ($u) = $ENV{AS_SECURITY_USER_CLASS}->search(
			name => $root->username,
			password => Hash($root->password // ""));
	my $res = $u ? $root->redirect
			: "r?failed=f&username=" . ($root->username // "");
	$r->pnotes('SWITSession')->set_user($u) if ($u);
	return $res;
}

1;
