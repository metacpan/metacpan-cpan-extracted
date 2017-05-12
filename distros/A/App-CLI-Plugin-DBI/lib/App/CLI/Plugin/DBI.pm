package App::CLI::Plugin::DBI;

=pod

=head1 NAME

App::CLI::Plugin::DBI - for App::CLI::Extension database base module 

=head1 VERSION

1.1

=head1 SYNOPSIS

  # MyApp.pm
  package MyApp;
  
  use strict;
  use base qw(App::CLI::Extension);
  
  # extension method
  __PACKAGE__->load_plugins(qw(DBI));
  __PACKAGE__->config(dbi => ["dbi:Pg:dbname=app_db", "foo", "bar", { RaiseError => 1, pg_enable_utf8 => 1 }]);
  
  1;
  
  # MyApp/Hello.pm
  package MyApp::Hello;
  use strict;
  use base qw(App::CLI::Command);
  our $VERSION = '1.0';
  
  sub run {
  
      my($self, @args) = @_;
      my $sql = "select id, name, age from member where id = ?";
	  my $sth = $self->dbh->prepare($sql);
      $sth->execute($args[0]);
	  while (my $ref = $sth->fetchrow_hashref) {
          # anything to do...
      }
      $sth->finish;
  }

=head1 DESCRIPTION

App::CLI::Extension DBI plugin module

dbh method setting

normal setting

  # config (example: PostgreSQL)
  __PACKAGE__->config(dbi => ["dbi:Pg:dbname=app_db", "foo", "bar", { RaiseError => 1, pg_enable_utf8 => 1 }]);
  
  # get DBI handle
  my $dbh = $self->dbh;

multi db setting

  # config
  __PACKAGE__->config(dbi => {
                        default  => ["dbi:Pg:dbname=app_db", "foo", "bar", { RaiseError => 1, pg_enable_utf8 => 1 }]
                        other    => ["dbi:Pg:dbname=other_db;host=192.168.1.100;port=5432", "foo", "bar", { RaiseError => 1, pg_enable_utf8 => 1 }]
  );
  
  # get DBI handle
  my $default_dbh = $self->dbh; # same as $self->dbh("default")
  my $other_dbh   = $self->dbh("other");

=cut

use strict;
use warnings;
use base qw(Class::Accessor::Grouped);
use DBI;

our $DEFAULT_HANDLE = "default";
our $VERSION        = '1.1';

#__PACKAGE__->mk_classaccessor(_dbh => {});
#__PACKAGE__->mk_classaccessor(dbi_default_handle => $DEFAULT_HANDLE);
__PACKAGE__->mk_group_accessors(inherited => "_dbh", "dbi_default_handle");
__PACKAGE__->_dbh({});
__PACKAGE__->dbi_default_handle($DEFAULT_HANDLE);

=pod

=head1 METHOD

=cut

sub setup {

	my($self, @argv) = @_;

	if (!exists $ENV{APPCLI_DISABLE_DB_AUTO_CONNECT}) {
		$self->dbi_connect;
	}
	$self->maybe::next::method(@argv);
}

sub finish {

	my($self, @argv) = @_;

	if (!exists $ENV{APPCLI_DISABLE_DB_AUTO_CONNECT}) {
		$self->dbi_disconnect;
	}
	$self->maybe::next::method(@argv);
}

=pod

=head2 dbi_connect

initialize DBI connect setting. setup phase to run normally with no need to perform explicitly. 

However, the environment variable "APPCLI_DISABLE_DB_AUTO_CONNECT" If you have defined not to run the setup phase,

the need to call this method yourself

=cut

sub dbi_connect {

	my $self = shift;

	my $dbi_option = $self->_dbi_option;
	map { $self->_dbh->{$_} = DBI->connect(@{$dbi_option->{$_}}) } keys %{$dbi_option};
}

=head2 dbi_disconnect

destroy DBI disconnect. finish phase to run normally with no need to perform explicitly. 

However, the environment variable "APPCLI_DISABLE_DB_AUTO_CONNECT" If you have defined not to run the setup phase,

the need to call this method yourself

=cut

sub dbi_disconnect {

	my $self = shift;

	map { $self->_dbh->{$_}->disconnect } keys %{$self->_dbh};
}

=pod

=head2 dbh

get DBD::db. default handle name is "default"(actual value and the value returned dbi_default_handle method)

Example

  # same as $self->dbh($self->dbi_default_handle);
  my $dbh = $self->dbh;
  
  # if you set up if you want to connect multiple databases
  my $default_dbh = $self->dbh;
  my $other1_dbh  = $self->dbh("other1");
  my $other2_dbh  = $self->dbh("other2");

=head2 dbi_default_handle

get default handle name. 

get current default handle name

  # $handle is "default"
  my $handle = $self->dbi_default_handle;

to change the default handle name

  $self->dbi_default_handle("new_handle_name");
  # get new_handle_name db handle
  my $dbh = $self->dbh;

=cut

sub dbh {

	my($self, $handle) = @_;

	$handle ||= $self->dbi_default_handle;
	if (keys(%{$self->_dbh}) == 0) {
		die "still not connected to database?";
	}
	if (!exists $self->_dbh->{$handle}) {
		die "$handle is not undefined dbh handle";
	}
	return $self->_dbh->{$handle};
}


####################################
# private method
####################################
sub _dbi_option {

	my $self = shift;

	if (!defined $self->config->{dbi}) {
		die "dbi option is always required";
	}
	my $dbi_option;
	if (ref($self->config->{dbi}) eq "ARRAY") {
		$dbi_option = { $self->dbi_default_handle => $self->config->{dbi} };
	} elsif (ref($self->config->{dbi}) eq "HASH") {
		$dbi_option = $self->config->{dbi};
	}

	return $dbi_option;
}

1;

__END__

=head1 AUTHOR

Akira Horimoto

=head1 SEE ALSO

L<App::CLI::Extension> L<DBI>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 COPYRIGHT

Copyright (C) 2010 Akira Horimoto

=cut
