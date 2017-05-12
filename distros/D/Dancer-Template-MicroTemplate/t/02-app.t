use strict;
use warnings;
use Test::More tests => 2;
use File::Spec;

{
    use Dancer::Test;
    use lib File::Spec->catdir(qw(t lib));
    use TestApp;
    route_exists [GET => '/'];
    response_content_is(
        [GET => '/'],
        qq{this is var1="1" and var2=2\n\nanother line\n\none two three\n}
    );
}

