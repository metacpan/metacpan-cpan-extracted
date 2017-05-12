package Catalyst::Authentication::Store::LDAP::AD::Class::User;

use strict;
use warnings;
use base qw/Catalyst::Authentication::User/;
use base qw/Class::Accessor::Fast/;
use Catalyst::Authentication::Store::LDAP::AD::Simple;

BEGIN {
	__PACKAGE__->mk_accessors(qw/config resultset _user _ldap/);
}

sub new {
	my ( $class, $config, $c) = @_;

	if (!defined($config->{'user_model'})) {
		$config->{'user_model'} = $config->{'user_class'};
	}

	my $lds = Catalyst::Authentication::Store::LDAP::AD::Simple->new(
		ldap_domain => $config->{'ldap_domain'},
		global_user => $config->{'ldap_global_user'},
		global_pass => $config->{'ldap_global_pass'},
		ldap_base 	=> $config->{'ldap_base'},
		ldap_filter => $config->{'ldap_filter'},
		timeout     => $config->{'ldap_timeout'},
	);

	my $self = {
		config => $config,
		_user => undef,
		_ldap => $lds
	};

	bless $self, $class;

	return $self;
}

sub load {
	my ($self, $authinfo, $c) = @_;
	$self->_ldap->setup();
	my $user = $self->_ldap->get_user(
		login 		=> $authinfo->{'login'},
		password 	=> $authinfo->{'password'}
	);
	if ($user) {
		use Digest::MD5 qw/md5_hex/;
		$user->replace ( 'objectGUID' => md5_hex $user->get_value('objectGUID') );
		no Digest::MD5;
		$self->_user($user);
		return $self;

	} else {
			return undef;
	}

}

sub supported_features {
	my $self = shift;
	return {
		session => 1,
		password => { self_check => 1, },
	};
}

sub for_session {
	my $self = shift;
	return $self->_user;
}

sub from_session {
	my ($self, $frozenuser, $c) = @_;
	$self->_user($frozenuser);
	return $self;
}

sub get {
	my ($self, $field) = @_;
	if ($field) {

		# get entry attribute
		$field = (grep { $_->{'type'} eq $field; } @{$self->_user->{'asn'}->{'attributes'}})[0]->{'vals'}->[0];
		Encode::_utf8_on($field);
		return $field;
	} else {
		return undef;
	}
}

sub get_object {
	my ($self) = @_;
	return $self->_user;
}

sub check_password {
	my ($self, $password) = @_;

	# get user distinguished name
	my $dn = $self->_user->dn() or Catalyst::Exception->throw("no user found! : $!\n");

	return $self->_ldap->authenticate($dn, $password);
}

1;
