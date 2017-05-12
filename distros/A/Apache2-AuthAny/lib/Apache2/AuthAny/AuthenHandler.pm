package Apache2::AuthAny::AuthenHandler;

use strict;

use Data::Dumper qw(Dumper);

use Apache2::Const -compile => qw(OK);
use Apache2::AuthAny::AuthUtil ();
our $aaDB;
our $VERSION = '0.201';

sub handler {
    my $r = shift;

    $r->log->info("Apache2::AuthAny::AuthenHandler: authenticating '" . $r->uri . "'");
    $r->log->info("Apache2::AuthAny::AuthenHandler: \$ENV{REMOTE_USER}: '" . $ENV{REMOTE_USER} . "'");
    if ($ENV{REMOTE_USER}) {
        return Apache2::Const::OK; # Continue through to Authz if handler registered
    } else {
        return Apache2::AuthAny::AuthUtil::goToGATE($r, 'first_access');
    }
}

1;

