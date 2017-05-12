use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::Session;
use base 'Apache::SWIT::Session';
use URI;
use URI::QueryParam;

sub cookie_name { return 'apache_swit_security'; }

our $Sec_Man;

sub swit_startup {
	my $class = shift;
	$class->add_class_dbi_var('user', $ENV{AS_SECURITY_USER_CLASS});
	$Sec_Man = $ENV{AS_SECURITY_MANAGER}->create;
}

sub is_uri_ok {}

sub authorize {
	my ($self, $ac, $uri, %param) = @_;
	return $self->is_uri_ok($uri, %param)
		|| $ac->check_user($self->get_user, $self->request);
}

sub is_capable {
	my ($self, $cap) = @_;
	return $Sec_Man->capability_control($cap)->check_user($self->get_user);
}

sub _is_allowed {
	my ($self, $uri, %param) = @_;
	my $ac = $Sec_Man->access_control($uri) or return 1;
	return $self->authorize($ac, $uri, %param);
}

sub is_allowed {
	my ($self, $rel_uri) = @_;
	my $uri = URI->new_abs($rel_uri, $self->request->uri);
	return $self->_is_allowed($uri->path, %{ $uri->query_form_hash });
}

sub access_handler($$) {
	my ($class, $r) =  @_;
	my $res = $class->SUPER::access_handler($r);
	my $apr = Apache2::Request->new($r);
	return $r->pnotes('SWITSession')->_is_allowed($r->uri
		, %{ $apr->param || {} }) ? $res : Apache2::Const::FORBIDDEN();
}

1;
