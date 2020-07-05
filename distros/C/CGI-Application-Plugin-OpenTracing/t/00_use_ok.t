use Test::Most;

use strict;
use warnings;

use Ref::Util qw/is_coderef/;

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
                coderef => code( \&is_coderef ),
            },
            {
                name    => 'prerun',
                coderef => code( \&is_coderef ),
            },
            {
                name    => 'postrun',
                coderef => code( \&is_coderef ),
            },
            {
                name    => 'load_tmpl',
                coderef => code( \&is_coderef ),
            },
            {
                name    => 'teardown',
                coderef => code( \&is_coderef ),
            },
        ],
        "Installed expected callbacks, and these are coderefs!"
    );
    
};

done_testing;
