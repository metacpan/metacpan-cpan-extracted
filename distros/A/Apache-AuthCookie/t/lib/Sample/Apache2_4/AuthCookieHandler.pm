package Sample::Apache2_4::AuthCookieHandler;

use strict;
use Sample::Apache2::AuthCookieHandler;
use Apache2::Const qw(AUTHZ_DENIED_NO_USER);
use Apache2::RequestRec;
use Apache::AuthCookie::Util qw(is_blank);

use vars qw(@ISA);

@ISA = qw(Sample::Apache2::AuthCookieHandler);

my %Dwarves = map { $_ => 1 }
    qw(bashful doc dopey grumpy happy sleepy sneezy programmer);

# authz under apache 2.4 is very different from previous versions
sub dwarf {
    my ($self, $r) = @_;

    $r->server->log_error("dwarf entry");

    my $user = $r->user;

    if (is_blank($user)) {
        $r->server->log_error("No user authenticted yet");
        return Apache2::Const::AUTHZ_DENIED_NO_USER;
    }
    elsif (defined $Dwarves{$user}) {
        $r->server->log_error("$user is a dwarf");
        return Apache2::Const::AUTHZ_GRANTED;
    }
    else {
        $r->server->log_error("$user is not a dwarf");
        return Apache2::Const::AUTHZ_DENIED;
    }
}

1;
