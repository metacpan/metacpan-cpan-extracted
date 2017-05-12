use ModPerl::Util (); #for CORE::GLOBAL::exit

use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

use Apache2::Const -compile => ':common';
use APR::Const -compile => ':common';

unless ($ENV{MOD_PERL}) {
    die '$ENV{MOD_PERL} not set!';
}

1;
