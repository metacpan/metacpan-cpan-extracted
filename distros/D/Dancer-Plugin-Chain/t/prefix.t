use strict;
use warnings;

use Test::More tests => 2;

{
    package MyApp;

    use Dancer;
    use Dancer::Plugin::Chain;

    prefix '/foo' => sub {

    my $chain = chain '/baz', sub { };

    get chain $chain, sub { 'baz' };

    prefix '/bar';
    
    get chain $chain, sub { 'bar/baz' };

    }
        
}

use Dancer::Test;

response_content_is '/foo/baz' => 'baz';
response_content_is '/foo/bar/baz' => 'bar/baz';

