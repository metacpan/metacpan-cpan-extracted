package TestApp::Plugin::ErrorMessage;

use strict;
use warnings;

sub finalize_error {
  my $c = shift;

  my $error = join ' ', ( ref $c->error eq 'ARRAY' ? @{ $c->error }
                                                   : ( $c->error ));
  $c->response->body( $error );
}

1;
