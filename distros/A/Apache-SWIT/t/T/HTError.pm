use strict;
use warnings FATAL => 'all';

package T::HTError::Root;

sub ht_validate {
	my $n = shift()->name;
 	return  $n eq 'bad' || $n eq 'foo' ? ('bad') : ();
}

package T::HTError;
use base 'Apache::SWIT::HTPage';
use HTML::Tested qw(HTV);
use HTML::Tested::Value::PasswordBox;

sub swit_startup {
	my $rc = shift()->ht_make_root_class;
	$rc->ht_add_widget(HTV."::EditBox", 'name');
	$rc->ht_add_widget(HTV."::PasswordBox", 'password');
	$rc->ht_add_widget(HTV, 'error');
	$rc->ht_add_widget(::HTV."::Form", form => default_value => 'u');
}

sub ht_swit_render {
	my ($class, $r, $root) = @_;
	$root->name("buh");
	return $root;
}

sub ht_swit_validate_die {
	my ($class, $errs, $r, $root) = @_;
	my $res = $root->name eq 'foo' ? "r?error=validate"
			: "r?error=validie&error_uri=" . $r->uri;
	return ($res, 'password');
}

sub ht_swit_update_die {
	my ($class, $msg, $r, $root) = @_;
	return $class->SUPER::swit_die(@_) unless $msg =~ /Hoho/;
	return ("r?error=updateho", "password");
}

sub ht_swit_update {
	my ($class, $r, $root) = @_;
	return [ Apache2::Const::FORBIDDEN() ] if $root->name eq 'FORBID';
	return $class->swit_failure('r?error=failure', 'password')
		if $root->name eq 'fail';
	die "Hoho";
	return "r";
}

1;
