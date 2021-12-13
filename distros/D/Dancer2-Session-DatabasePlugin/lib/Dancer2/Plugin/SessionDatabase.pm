package Dancer2::Plugin::SessionDatabase;

use Modern::Perl;
use Dancer2::Plugin; 

use Carp qw(croak);
use Data::Dumper;

=head1 NAME

Dancer2::Plugin::SessionDatabase - Hook Loader For Dancer2::Session::DatabasePlugin

=head1 DESCRIPTION

Hook loader for Dancer2::Session::DatabasePlugin.

=head2 Plugin options


In your config.yml

  plugins:
    SessionDatabase:
      # when set to true this forces a call to the database plugin
      always_clean: 1


=cut

has always_clean=>(
  is=>'rw',
  default=>sub { 1 },
);

our $DBH;

sub reset_session {
  %{$Dancer2::Session::DatabasePlugin::CACHE}=();
  $DBH=undef;
}

sub DBC { 
    my ($self,$conn)=@_;

    if($self->always_clean) {
      $self->reset_session;
    }
    my $db=$self->find_plugin('Dancer2::Plugin::Database');
    my $dbh=$db->database($conn); 

    if(defined($DBH) && $dbh ne $DBH) {
      %{$Dancer2::Session::DatabasePlugin::CACHE}=();
    }

    return $DBH=$dbh;
}

# This method runs after the new constructor
sub BUILD {
  my ($self)=@_;

  while(my ($method,$value)=each %{$self->config}) {
    $self->$method($value);
  }

  $self->app->add_hook(
    Dancer2::Core::Hook->new(
      name=>"engine.session.before_db",
      code=>sub { 
          my ($session)=@_;
          my $dbh=$self->DBC($session->connection);
          $session->dbh($dbh);
        }
      )
  );
  $self->app->add_hook(
    Dancer2::Core::Hook->new(
      name=>"database_connection_lost",
      code=>sub { 
        	my ($dbh)=@_;
          $self->reset_session;
        }
      )
  );
  $self->app->add_hook(
    Dancer2::Core::Hook->new(
      name=>"database_error",
      code=>sub { 
	        my ($err,$dbh)=@_;
          $self->reset_session;
      }
    )
  );
}

=head1 AUTHOR

Michael Shipper AKALINUX@CPAN.ORG

=cut

1;
