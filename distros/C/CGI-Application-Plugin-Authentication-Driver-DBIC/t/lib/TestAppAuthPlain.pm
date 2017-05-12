package TestAppAuthPlain;

use base qw(CGI::Application);
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Authentication;
use lib 't/lib';
use TestDB;

my %config = (
  DRIVER => [
    'DBIC',
    SCHEMA        => TestDB->connect('dbi:SQLite:t/db/users.db'),
    CLASS         => 'Users',
    FIELD_METHODS => [qw(user plain:passphrase)]
  ],
  CREDENTIALS => [qw( auth_username auth_password )],
  STORE       => 'Session',
);

__PACKAGE__->auth->config(%config);

sub setup {
  my $self = shift;
  $self->start_mode('one');
  $self->run_modes(qw( one two ));
  $self->auth->protected_runmodes(qw( two ));
}

sub one {
  my $self = shift;
}

sub two {
  my $self = shift;
}
1;
