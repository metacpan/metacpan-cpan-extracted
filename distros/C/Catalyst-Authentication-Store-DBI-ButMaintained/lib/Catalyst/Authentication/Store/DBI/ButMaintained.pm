package Catalyst::Authentication::Store::DBI::ButMaintained;
use strict;
use warnings;
use namespace::autoclean;

use Storable;
use Moose;
use MooseX::Types::LoadableClass qw/ClassName/;

our $VERSION = '0.03';

has 'config' => (
	isa  => 'HashRef'
	, is => 'ro'
	, required => 1
	, traits => ['Hash']
	, handles => {
		get_config => 'get'
	}
);

has 'store_user_class' => (
	isa  => ClassName
	, is => 'ro'
	, coerce  => 1
	, lazy    => 1
	, default => sub {
		my $self = shift;
		defined $self->get_config('store_user_class')
			? $self->get_config('store_user_class')
			: 'Catalyst::Authentication::Store::DBI::ButMaintained::User'
		;
	}
);

# locates a user using data contained in the hashref
sub find_user {
	my ($self, $authinfo, $c) = @_;
	my $dbh = $c->model('DBI')->dbh;

	my @col = sort keys %$authinfo;

	my $abs_user_dest = $self->_safe_escape(
		$dbh
		, {map { $_ => $self->get_config("user_$_") } qw/database schema table/}
	);

	my $sql = "SELECT * FROM $abs_user_dest WHERE "
			.	join( ' AND ', map $dbh->quote_identifier($_) . " = ?", @col )
	;

	my $sth = $dbh->prepare($sql) or die($dbh->errstr());
	$sth->execute(@$authinfo{@col}) or die($dbh->errstr());

	my %user;
	$sth->bind_columns(\( @user{ @{ $sth->{'NAME_lc'} } } )) or
	die($dbh->errstr());
	unless ($sth->fetch()) {
		$sth->finish();
		return undef;
	}
	$sth->finish();

	## Fail silently clause
	return undef
		unless exists $user{$self->get_config('user_key')}
		&& length $user{$self->get_config('user_key')}
	;

	my $class = $self->store_user_class;
	return $class->new({
		store  => $self
		, user => \%user
		, authinfo  => $authinfo
		, dbi_model => $c->model('DBI')
	});

}

sub _safe_escape {
	my $self = shift;
	my ( $dbh, $unescaped ) = @_;

	join '.'
		, map $dbh->quote_identifier( $unescaped->{$_} )
			, grep exists $unescaped->{$_} && defined $unescaped->{$_}
				, qw/database schema table column/
	;

}


## Not sure how for_session would work with ACCEPT_CONTEXT in the Model::DBI
## If you don't have the same context in the DBI you could presumably get a
## different user
sub for_session {
	my $self = shift;
	my ( $c, $user) = @_;

	## TODO: Freeze whole user, this should just be fallback
	if (
		exists $self->config->{user_key}
		&& $user->get( $self->get_config('user_key') )
	) {
		my $k = $self->get_config('user_key');
		my $uid = $user->get( $k );
		return Storable::nfreeze({ $k => $uid });
	}
	## Support users with composite key
	else {
		return Storable::nfreeze( $user->authinfo );
	}

}

sub from_session {
	my $self = shift;
	my ( $c, $frozen ) = @_;
	$self->find_user( Storable::thaw($frozen), $c );
}

sub user_supports {
	return;
}

sub BUILDARGS {
	my $class = shift;
	my ( $config, $app, $realm ) = @_;

	scalar @_ == 1
		? $class->SUPER::BUILDARGS(@_)
		: { config => $config, app => $app, realm => $realm }
	;

}

1;

__END__

=head1 NAME

Catalyst::Authentication::Store::DBI::ButMaintained - Storage class for Catalyst Authentication using DBI

=head1 SYNOPSIS

use Catalyst qw(Authentication);

	__PACKAGE__->config->{'authentication'} = {
		default_realm => 'default'
		, realms => {
			default => {
				credential => {
					class                 => 'Password'
					, password_field      => 'password'
					, password_type       => 'hashed'
					, password_hash_type  => 'SHA-1'
				}
				store => {
					class                => 'DBI::ButMaintained'
					, user_schema        => 'authentication' # Not required
					, user_table         => 'login'
					, user_key           => 'id'
					, user_name          => 'name'

					## Role stuff is not needed if you want to subclass or not use roles
					, role_table         => 'authority'
					, role_key           => 'id'
					, role_name          => 'name'
					, user_role_table    => 'competence'
					, user_role_user_key => 'login'
					, user_role_role_key => 'authority'
				},
			},
		},
	};

	sub login :Global {
		my ($self, $c) = @_;
		my $req = $c->request();

		# catch login failures
		unless ($c->authenticate({
			'name'       => $req->param('name')
			, 'password' => $req->param('password')
		})) {
		...
		}

		...
	}

	sub something :Path {
		my ($self, $c) = @_;

		# handle missing role case
		unless ($c->check_user_roles('editor')) {
		...
	}

=head1 DESCRIPTION

This module implements the L<Catalyst::Authentication> API using L<Catalyst::Model::DBI>.

It uses DBI to let your application authenticate users against a database and it provides support for L<Catalyst::Plugin::Authorization::Roles>.

=head2 History

This module started off as a patch to L<Catalyst::Authentication::Store::DBI>. I was unable to get ahold of the author, JANUS after he had said that he was willing to cede maintainership. This combined with my inability to provide support on official catalyst mediums -- I credit (mst) Matthew Trout's desire to instigate matters when someone is trying to provide a patch -- leads me to fork.

You can get official support on this module in on irc.freenode.net's #perlcafe.

=head2 Config

The store is fully capable of dealing with more complex schemas by utilizing the where condition in C<find_user>. Now, if your role schema is different from the below diagram then simply subclass L<Catalyst::Authentication::Store::DBI::ButMaintained::User> and set C<store_user_class> in the config. Currently, this is probably the most likely reason to subclass the User.

The C<authenticate> method takes a hash ref that will be used to serialize and unserialize the user if there is no single L<user_key>. Composite keys are not currently supported in L<user_key>

=head3 The default database configuration

This module was created for the following configuration:

	role_table            user_role_table
	===================   ===================
	role_id | role_name   role_id | user_id
	-------------------   -------------------
	0       | role        0       | 1

	user_table
	===================
	user_id | user_name
	-------------------
	0       | Evan "The Man" Carroll

=head1 METHODS

=head2 new

=head2 find_user

Will find a user with provided information

=head2 for_session

This does not truely serialize a user from the session. If there is a L<user_key> in the config it saves that users value to a hash; otherwise, it saves the entire authinfo condition from the call to authenticate.

=head2 from_session

Will either C<find_user> based on the C<user_key>, or C<auth_info> provided to C<authenticate>

=head2 user_supports

=head2 get_config( $scalar )

Accessor used for getting to the authentication modules configuration as set in the Catalyst config.

=head2 _safe_escape

Internal method only: takes a copy of $dbh, and a hash with keys of B<database>, B<schema>, B<table> and B<column> and escapes all that is provided joining them on a period for use in prepaired statements.

=head1 SEE ALSO

=over 4

=item L<Catalyst::Plugin::Authentication>

=item L<Catalyst::Model::DBI>

=item L<Catalyst::Plugin::Authorization::Roles>

=back

=head1 AUTHOR

Evan Carroll, E<lt>cpan@evancarroll.comE<gt>

(v.01) Simon Bertrang, E<lt>simon.bertrang@puzzworks.comE<gt>

=head1 AUTHOR

Copyright (c) 2010 Evan Carroll, L<http://www.evancarroll.com/>

=head2 Original L<Catalyst::Authentication::Store::DBI>

Copyright (c) 2008 PuzzWorks OHG, L<http://puzzworks.com/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
