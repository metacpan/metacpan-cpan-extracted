package Catalyst::Authentication::Store::DBI;
use strict;
use warnings;
use Catalyst::Authentication::Store::DBI::User;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Authentication::Store::DBI - Storage class for Catalyst
Authentication using DBI

=head1 SYNOPSIS

  use Catalyst qw(Authentication);

  __PACKAGE__->config->{'authentication'} = {
    'default_realm' => 'default',
    'realms' => {
      'default' => {
        'credential' => {
          'class'               => 'Password',
          'password_field'      => 'password',
          'password_type'       => 'hashed',
          'password_hash_type'  => 'SHA-1',
        },
        'store' => {
          'class'              => 'DBI',
          'user_table'         => 'login',
          'user_key'           => 'id',
          'user_name'          => 'name',
          'role_table'         => 'authority',
          'role_key'           => 'id',
          'role_name'          => 'name',
          'user_role_table'    => 'competence',
          'user_role_user_key' => 'login',
          'user_role_role_key' => 'authority',
        },
      },
    },
  };

  sub login :Global
  {
    my ($self, $c) = @_;
    my $req = $c->request();

    # catch login failures
    unless ($c->authenticate({
      'name'     => $req->param('name'),
      'password' => $req->param('password'),
      })) {
      ...
    }

    ...
  }

  sub something :Path
  {
    my ($self, $c) = @_;

    # handle missing role case
    unless ($c->check_user_roles('editor')) {
      ...
    }

    ...
  }

=head1 DESCRIPTION

This module implements the L<Catalyst::Authentication> API using
L<Catalyst::Model::DBI>.

It uses DBI to let your application authenticate users against a database and it
provides support for L<Catalyst::Plugin::Authorization::Roles>.

=head1 METHODS

=head2 new

=cut

# instantiates the store object
sub new
{
	my ($class, $config, $app, $realm) = @_;

	unless (defined($config) && ref($config) eq 'HASH') {
		Catalyst::Exception->throw(__PACKAGE__ .
		    ' needs a hashref for configuration');
	}

	my $self = {%$config};

	bless($self, $class);

	return $self;
}

=head2 find_user

=cut

# locates a user using data contained in the hashref
sub find_user
{
	my ($self, $authinfo, $c) = @_;
	my $sql;
	my $sth;
	my %user;

	unless ($self->{'dbh'}) {
		$self->{'dbh'} = $c->model('DBI')->dbh();
	}

	my $dbh = $self->{'dbh'};

	my @col = map { $_ } sort(keys(%$authinfo));

	$sql = 'SELECT * FROM ' . $self->{'user_table'} . ' WHERE ' .
	    join(' AND ', map { $_ . ' = ?' } @col);

	$sth = $dbh->prepare($sql) or die($dbh->errstr());
	$sth->execute(@$authinfo{@col}) or die($dbh->errstr());
	$sth->bind_columns(\( @user{ @{ $sth->{'NAME_lc'} } } )) or
	    die($dbh->errstr());
	unless ($sth->fetch()) {
		$sth->finish();
		return undef;
	}
	$sth->finish();

	unless (exists($user{$self->{'user_key'}}) &&
	    length($user{$self->{'user_key'}})) {
		return undef;
	}

	return Catalyst::Authentication::Store::DBI::User->new($self, \%user);
}

=head2 for_session

=cut

sub for_session
{
	my ($self, $c, $user) = @_;

	return $user->id();
}

=head2 from_session

=cut

sub from_session
{
	my ($self, $c, $frozen) = @_;
	my $sql;
	my $sth;
	my %user;

	unless ($self->{'dbh'}) {
		$self->{'dbh'} = $c->model('DBI')->dbh();
	}

	my $dbh = $self->{'dbh'};

	$sql = 'SELECT * FROM ' . $self->{'user_table'} . ' WHERE ' .
	    $self->{'user_key'} . ' = ?';

	$sth = $dbh->prepare($sql) or die($dbh->errstr());
	$sth->execute($frozen) or die($dbh->errstr());
	$sth->bind_columns(\( @user{ @{ $sth->{'NAME_lc'} } } )) or
	    die($dbh->errstr());
	unless ($sth->fetch()) {
		$sth->finish();
		return undef;
	}
	$sth->finish();

	unless (exists($user{$self->{'user_key'}}) &&
	    length($user{$self->{'user_key'}})) {
		return undef;
	}

	return Catalyst::Authentication::Store::DBI::User->new($self, \%user);

}

=head2 user_supports

=cut

sub user_supports
{
	my $self = shift;

	return;
}

=head1 SEE ALSO

=over 4

=item L<Catalyst::Plugin::Authentication>

=item L<Catalyst::Model::DBI>

=item L<Catalyst::Plugin::Authorization::Roles>

=back

=head1 AUTHOR

Simon Bertrang, E<lt>simon.bertrang@puzzworks.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 PuzzWorks OHG, L<http://puzzworks.com/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
