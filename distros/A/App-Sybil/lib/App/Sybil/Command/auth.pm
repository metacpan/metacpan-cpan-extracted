package App::Sybil::Command::auth;

use strict;
use warnings;
use v5.12;

use App::Sybil -command;

use IO::Prompt::Simple 'prompt';

sub abstract { 'Authenticate with github' }

sub execute {
  my ($self, $opt, $args) = @_;

  if ($self->app->_read_token) {
    say STDERR "You already have an authentication token.";
    return;
  }

  # TODO hide password when typing
  my $user = prompt('GitHub Username');
  my $pass = prompt('GitHub Password');

  my $github = Net::GitHub->new(
    version => 3,
    login => $user,
    pass => $pass,
  );

  eval { $github->user->show(); };

  if ($@ =~ /OTP/) {
    my $otp = prompt('Authenticator code');

    $github = Net::GitHub->new(
      version => 3,
      login => $user,
      pass => $pass,
      otp => $otp,
    );
  }

  eval { $github->user->show(); };

  if ($@) {
    say STDERR "Authentication error: $@";
    return;
  }

  my $auth;
  eval {
    $auth = $github->oauth->create_authorization({
      scopes => ['repo'],
      note => 'sybil',
    });
  };

  if ($@) {
    say STDERR "Unable to generate token: $@";
    return;
  }

  if (my $token = $auth->{token}) {
    $self->app->_write_token($token);
    say STDERR 'Authentication token stored';
  } else {
    say STDERR 'Unable to create authentication token';
  }
}

1;
