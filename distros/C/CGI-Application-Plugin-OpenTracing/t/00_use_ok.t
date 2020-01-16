use Test::Most;

use strict;
use warnings;

# we could check that we actually add the callbacks ? that is what `use` is
# suposed to do, we opught to test that here!!
#

my $callbacks = [];
sub add_callback { push @$callbacks, +{ name=> $_[1], coderef =>  $_[2] } };

BEGIN {
    use_ok('CGI::Application::Plugin::OpenTracing');
    
    cmp_deeply( $callbacks =>
        [
            {
                name    => 'init',
                coderef => ignore(),
            },
            {
                name    => 'prerun',
                coderef => ignore(),
            },
            {
                name    => 'postrun',
                coderef => ignore(),
            },
            {
                name    => 'teardown',
                coderef => ignore(),
            },
        ],
        "Installed expected callbacks, although these may not be coderefs!"
    );
    
};

done_testing;
