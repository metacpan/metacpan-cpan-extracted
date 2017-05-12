use strict;
use warnings;

package YOUR_MODULE;

# Plack application

use parent qw(Plack::Component);

sub call {
    my ($self, $env) = @_;
    my $res = [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
    return $res;
}

1;
