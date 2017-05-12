# thanks kd
package UnknownError;
use strict;
sub MODIFY_CODE_ATTRIBUTES {}
sub  check : Blah {
$error = "please explode" ; # deliberate syntax error
}
1;
