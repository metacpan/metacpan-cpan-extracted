use strict;

$ENV{MOD_PERL} or die "not running under mod_perl";

use Apache::SdnFw;

$SIG{__WARN__} = \&Carp::cluck;
