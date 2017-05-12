package TestAppAuthcrypt;

use base qw(CGI::Application);
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Authentication;

my %config = (
  DRIVER => [
    'CDBI',
    CLASS   => 'TestUsers',
    FIELD_METHODS => [qw(user crypt:passphrase)]
  ],
  CREDENTIALS => [qw(auth_username auth_password)],
  STORE       => 'Session',
);

__PACKAGE__->authen->config(%config);

sub setup {
  my $self = shift;
  $self->start_mode('one');
  $self->run_modes( [ qw(one two) ]);
  $self->authen->protected_runmodes(qw(two));
}

sub one {
  my $self = shift;
}

sub two {
  my $self = shift;
}
1;
