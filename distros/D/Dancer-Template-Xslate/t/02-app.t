use strict;
use warnings;
use Test::More tests => 2;
use File::Spec;

{
    use Dancer::Test;
    use lib File::Spec->catdir(qw(t lib));
    use TestApp;
    route_exists [ GET => '/' ];
    response_content_like( [ GET => '/' ], qr/1<br \/>\n2/ );
}
