package ActiveRecord::Simple::Connect;

use strict;
use warnings;
use 5.010;

use DBI;


my $self;

sub new {
	my ($class, $dsn, $username, $password, $params) = @_;

	if (!$self) {
		$self = { dbh => undef };
		if ($dsn) {
			$self->{dsn} = $dsn;
			$self->{username} = $username if $username;
			$self->{password} = $password if $password;
			$self->{connection_parameters} = $params if $params;

			my $dbh = DBI->connect($dsn, $username, $password, $params) or die DBI->errstr;
			$self->{dbh} = $dbh;
		}

		bless $self, $class;
	}

	return $self;
}

sub username {
	my ($self, $username) = @_;

	$self->{username} = $username if $username;

	return $self->{username};
}

sub password {
	my ($self, $password) = @_;

	$self->{password} = $password if $password;

	return $self->{password};
}

sub dsn {
	my ($self, $dsn) = @_;

	$self->{dsn} = $dsn;

	return $self->{dsn};
}

sub connection_parameters {
	my ($self, $connection_parameters) = @_;

	$self->{connection_parameters} = $connection_parameters;

	return $self->{connection_parameters};
}

sub dbh {
	my ($self, $dbh) = @_;

	if ($dbh) {
		$self->{dbh} = $dbh;
	}

	return ref $self->{dbh} eq 'CODE' ? $self->{dbh}->() : $self->{dbh};
}

1;
