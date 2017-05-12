use Test::More tests => 6;
use Apache::Emulator;
use strict;
BEGIN
{
    use_ok( 'Apache::Emulator' );
    use_ok( 'Apache' );
    use_ok( 'Apache::Constants' );
}
require_ok( 'Apache::Emulator' );
require_ok( 'Apache' );
require_ok( 'Apache::Constants' );
