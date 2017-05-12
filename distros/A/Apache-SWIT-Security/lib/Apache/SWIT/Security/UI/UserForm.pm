use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::UI::UserForm;
use Apache::SWIT::HTPage;
use base qw(Apache::SWIT::HTPage::Safe);
use Apache::SWIT::Security qw(Hash);

sub swit_startup {
	my $rc = shift()->ht_make_root_class('HTML::Tested::ClassDBI');
	$rc->ht_add_widget(::HTV."::EditBox", 'username', cdbi_bind => 'name');
	$rc->ht_add_widget(::HTV."::PasswordBox", 'password', cdbi_bind => '');
	$rc->ht_add_widget(::HTV."::PasswordBox", 'password2'
		, check_mismatch => 'password'
		, constraints => [ [ 'defined' ] ]);
	$rc->bind_to_class_dbi(
		$ENV{AS_SECURITY_USER_CLASS}, { PrimaryKey => [] });
}

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	return $root;
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	$root->password(Hash($root->password));
	$root->cdbi_create_or_update;
	return "../userlist/r";
}

1;
