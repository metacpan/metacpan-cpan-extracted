package RemoteTestEngine;
BEGIN {
  require Catalyst;
  if ($Catalyst::VERSION >= 5.89000) {
    require Catalyst::Engine;
    @ISA = qw(Catalyst::Engine);
  } else {
    require Catalyst::Engine::CGI;
    @ISA = qw(Catalyst::Engine::CGI);
  }
}

our $REMOTE_USER;
our $SSL_CLIENT_S_DN;

sub env {
    my $self = shift;
    my %e;
    if ($Catalyst::VERSION >= 5.89000) {
      %e = %{ $self->SUPER::env() };
    } else {
      %e = %ENV;
    }

    $e{REMOTE_USER} = $REMOTE_USER;
    $e{SSL_CLIENT_S_DN} = $SSL_CLIENT_S_DN;
    return \%e;    
};

1;
