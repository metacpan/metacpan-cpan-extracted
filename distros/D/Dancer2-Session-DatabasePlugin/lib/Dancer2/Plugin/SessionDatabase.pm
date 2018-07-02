package Dancer2::Plugin::SessionDatabase;

use Modern::Perl;
use Dancer2::Plugin; 
use Dancer2::Plugin::Database;
use Carp qw(croak);
use Data::Dumper;

=head1 NAME

Dancer2::Plugin::SessionDatabase - Hook Loader For Dancer2::Session::DatabasePlugin

=head1 DESCRIPTION

Hook loader for Dancer2::Session::DatabasePlugin.

=cut

our $DBH;

sub reset_session {
  %{$Dancer2::Session::DatabasePlugin::CACHE}=();
  $DBH=undef;
}

sub DBC { 
    my ($conn)=@_;
    my $dbh=database(@_); 

    unless(defined($DBH)) {
      %{$Dancer2::Session::DatabasePlugin::CACHE}=();
      return $DBH=$dbh;
    } unless(defined($dbh)) {
      $DBH=undef;
      croak "No database handle returned for $conn";
    } elsif($DBH eq $DBH) {
      return $dbh;
    }

    %{$Dancer2::Session::DatabasePlugin::CACHE}=();
    return $DBH=$dbh;
}

sub db_check {
  my ($self,$dbh)=@_;
  return 0 unless defined($DBH);
  return 0 unless $DBH eq $dbh;
  return 1;
}

# This method runs after the new constructor
sub BUILD {
  my ($self)=@_;

  $self->app->add_hook(
    Dancer2::Core::Hook->new(
      name=>"database_connection_lost",
      code=>sub { 
	my ($dbh)=@_;
          return unless $self->db_check($dbh);
          $self->reset_session;
        }
      )
  );
  $self->app->add_hook(
    Dancer2::Core::Hook->new(
      name=>"database_error",
      code=>sub { 
	my ($err,$dbh)=@_;
          return unless $self->db_check($dbh);
          $self->reset_session;
      }
    )
  );
}

=head1 AUTHOR

Michael Shipper AKALINUX@CPAN.ORG

=cut

1;
