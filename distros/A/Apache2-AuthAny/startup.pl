use lib ("$ENV{AUTH_ANY_ROOT}/lib");

use Apache2::RequestRec ();
use Apache2::Log ();
use Apache2::Request ();
use Apache2::Module ();
use Apache2::ServerRec ();
use Apache2::AuthAny::FixupHandler ();
use Apache2::AuthAny::Cookie ();

1;
