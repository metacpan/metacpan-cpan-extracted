package Catalyst::Authentication::Store::LDAP::AD::Simple;
use Moose;
use Net::LDAP;

=head1 Simple LDAP Interface

	- simple class to authenticate through LDAP to Active Directory

=head1 SYNOPSIS

	sub login : Regex('^login/(\w+)/(\w+)$') {
		my ( $self, $c ) = @_;

		my $lds = Hello::Logic::LDAP::Authorize::Simple->new(
			ldap_domain => 'ldap.domain.ru',
			global_user => "cn=BlaBla,ou=LaLaLAA,dc=domain,dc=ru",
			global_pass => "your_password",
			timeout     => 3
		);

		$lds->setup();

		my $auth = $lds->authenticate(
			login         => $c->req->captures->[0],
			password     => $c->req->captures->[1]
		);

		$c->response->body( $auth ? "Accepted" : "Denied" );

	}

	To access this action thought URL print in browser "domain.ru/login/your_login/your_password"

	global_user -     is the same as "dn" - distinguish name.
					It is the root directory in Active Directory
					structure which contains users information.
					Users information contains at least users dn's (distinguish names).

	global_pass -     is the password for distinguish name.
	ldap_domain -     is a domain that can be accessed through LDAP protocol (ldap://).
	timeout     -   When we try to connect to AD, we send request to it and wait for
					response. If AD is in down and doesn't send us any response for a
					"timeout"-time we drop the connection and crashes to confess.

=cut

# public
has 'ldap_domain' => (is => 'rw', isa => 'Str', required => 1);
has 'global_user' => (is => 'rw', isa => 'Str', required => 1);
has 'global_pass' => (is => 'rw', isa => 'Str', required => 1);
has 'ldap_base'   => (is => 'rw', isa => 'Str', required => 1);
has 'timeout'     => (is => 'rw', isa => 'Int', required => 1, 'default' => 5);

# private
has 'ldap'     => (is => 'rw', isa    => 'Net::LDAP',    init_arg => undef);

=head1 FUNCTIONS

=over 4

=item setup

	- setting up connection to Active Directory
	Arguments:
		none
	Returns: 1

=cut

sub setup {

	my $self     = shift;

	# create LDAP object
	$self->ldap(Net::LDAP->new($self->ldap_domain) or confess "Net::LDAP error! $!");

	# timeout handler
	$SIG{ALRM} = sub {die("ALRM")};

	my $mesg;

	# try to connect to AD thruogh LDAP
	eval {
		alarm($self->timeout); # generate signal ALRM evnokes after "timeout" seconds from connection start

		# get directories & users
		$mesg = $self->ldap->bind(
							$self->global_user,
			password    =>    $self->global_pass,
			version     =>     3
		) or confess("Cant get directories & users");

		alarm(0);
	};

	# error handler
	if ($@) {
		if ($@ =~ /^ALRM/) {
			confess("LDAP connection timed out. No response retrieved from AD!");
		}
		else
		{
			confess("Error connecting to AD: \"$@\"");
		}
	}

	# if code is not zero - it means that there was an error
	confess("LDAP Error: @{[ $mesg->error ]}\n") if $mesg->code;

	$SIG{ALRM} = undef;

	return 1;
}


sub get_user {

=item authenticate

	- trying to authenticate at Active Directory
	Arguments:
		login         => '...',
	Returns: 0|1
		ldap_message->entries->[0] (all available user data retrieved from AD though LDAP)

=cut

	my $self = shift;

	my %arg = @_;

	unless (
		%arg &&
		$arg{login} &&
		$arg{login} =~ /\w/
	)
	{
		confess("No corect args given!");
	}

	# get user
	my $mesg = $self->ldap->search(
		base   => $self->ldap_base,
		filter => "(sAMAccountName=$arg{login})",
	);

	# bad request
	confess("Can't get current user information: $!\n") if $mesg->code;

	my $user;

	# no user found
	unless ($mesg->entries) {

		return 0;
	}
	else
	{
		$user = ($mesg->entries)[0];
	}

	# return authentication process bool result
	return !$mesg->code ? $user : undef;

}

sub authenticate {
	my ($self, $dn, $password) = @_;

	# get user distinguished name
	confess("no dn given! : $!\n") unless $dn;

	# timeout handler
	$SIG{ALRM} = sub {die("ALRM")};

	# message
	my $auth_mesg;

	# try to connect to AD thruogh LDAP
	eval {

		alarm($self->timeout);	# generate signal ALRM evnokes after "timeout" seconds
								# from connection start

		# try to authorize user by DN and USER_PASS
		$auth_mesg = $self->ldap->bind($dn, password => $password)
							or confess("Cant get directories & users");

		alarm(0);

	};

	# error handler
	if ($@) {
		if ($@ =~ /^ALRM/) {
		confess("LDAP connection timed out. No response retrieved from AD!");
		}
		else
		{
			confess("Error connecting to AD: $@");0
		}
	}

	# timeout handler
	$SIG{ALRM} = undef;

	# if there no error code in $auth_mesg user has been authenticated, else - NO
	return !$auth_mesg->code ? 1 : 0;
}

=back

=head1 AUTHOR

Chergik Andrey Vladimirovich

=head1 CONTACTS

email: andrey@chergik.ru

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
