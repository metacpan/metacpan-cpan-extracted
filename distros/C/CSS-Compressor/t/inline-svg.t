
use strict;
use warnings;

use Test::More
    tests => 2;

BEGIN {
    use_ok('CSS::Compressor' => qw( css_compress ) );
}

my $result = css_compress(<<CSS);
some foo {
    background: url('data:image/svg+xml;utf8,<svg width="17" height="12" version="1.1" xmlns="http://www.w3.org/2000/svg"><path d="M6.4 11.6c-.4 0-.8-.1-1-.4l-5-4.8C0 6 0 5 .4 4.4 1 4 2 4 2.4 4.5l4 3.9L14.6.4c.5-.5 1.4-.5 2 0 .5.5.5 1.4 0 2l-9.2 8.8c-.3.3-.6.4-1 .4z" fill="#0AB21A" stroke="none" stroke-width="1" fill-rule="evenodd"/></svg>') 0 5px;
}
CSS

is $result => q|some foo{background:url('data:image/svg+xml;utf8,<svg width="17" height="12" version="1.1" xmlns="http://www.w3.org/2000/svg"><path d="M6.4 11.6c-.4 0-.8-.1-1-.4l-5-4.8C0 6 0 5 .4 4.4 1 4 2 4 2.4 4.5l4 3.9L14.6.4c.5-.5 1.4-.5 2 0 .5.5.5 1.4 0 2l-9.2 8.8c-.3.3-.6.4-1 .4z" fill="#0AB21A" stroke="none" stroke-width="1" fill-rule="evenodd"/></svg>') 0 5px}| => 'match';

