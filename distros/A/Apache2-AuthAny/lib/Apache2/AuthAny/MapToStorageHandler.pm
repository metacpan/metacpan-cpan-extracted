package Apache2::AuthAny::MapToStorageHandler;

use strict;

use Apache2::Const -compile => qw(DECLINED OK);
our $VERSION = '0.201';

sub handler {
    my $r = shift;

    my $uri = $r->uri;

    # Using PHP OpenId library for google auth.
    # The PHP library supports Attribute Exchange (AX)
    if ($uri =~ m{/aa_auth/google/([^/]+)\.php}) {
        my $script = $1;
        $r->filename("$ENV{AUTH_ANY_ROOT}/google/$script.php");
    }

    if ($uri =~ m{/aa_auth/(?!google)}) {
        return Apache2::Const::OK;
    } else {
        return Apache2::Const::DECLINED;
    }
}

1;
