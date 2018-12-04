
use strict;
use warnings;

use Test::More
    tests => 3;

BEGIN {
    use_ok('CSS::Compressor' => qw( css_compress ) );
}

my $result = css_compress(<<CSS);
some foo {
    background: url('data:image/svg+xml;utf8,<svg width="17" height="12" version="1.1" xmlns="http://www.w3.org/2000/svg"><path d="M6.4 11.6c-.4 0-.8-.1-1-.4l-5-4.8C0 6 0 5 .4 4.4 1 4 2 4 2.4 4.5l4 3.9L14.6.4c.5-.5 1.4-.5 2 0 .5.5.5 1.4 0 2l-9.2 8.8c-.3.3-.6.4-1 .4z" fill="#0AB21A" stroke="none" stroke-width="1" fill-rule="evenodd"/></svg>') 0 5px;
}
CSS

is $result => q|some foo{background:url('data:image/svg+xml;utf8,<svg width="17" height="12" version="1.1" xmlns="http://www.w3.org/2000/svg"><path d="M6.4 11.6c-.4 0-.8-.1-1-.4l-5-4.8C0 6 0 5 .4 4.4 1 4 2 4 2.4 4.5l4 3.9L14.6.4c.5-.5 1.4-.5 2 0 .5.5.5 1.4 0 2l-9.2 8.8c-.3.3-.6.4-1 .4z" fill="#0AB21A" stroke="none" stroke-width="1" fill-rule="evenodd"/></svg>') 0 5px}| => 'match';

my $output = css_compress(<<CSS);
some thing {
    background: url('data:image/svg+xml;utf8,<svg viewBox="-40 0 150 100" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g fill="grey" transform="rotate(-10 50 100) translate(-36 45.5) skewX(40) scale(1 0.5)"><path id="heart" d="M 10,30 A 20,20 0,0,1 50,30 A 20,20 0,0,1 90,30 Q 90,60 50,90 Q 10,60 10,30 z" / </g><use xlink:href="#heart" fill="none" stroke="red"/></svg>') 0 5px;
}
CSS

is $output => q|some thing{background:url('data:image/svg+xml;utf8,<svg viewBox="-40 0 150 100" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><g fill="grey" transform="rotate(-10 50 100) translate(-36 45.5) skewX(40) scale(1 0.5)"><path id="heart" d="M 10,30 A 20,20 0,0,1 50,30 A 20,20 0,0,1 90,30 Q 90,60 50,90 Q 10,60 10,30 z" / </g><use xlink:href="#heart" fill="none" stroke="red"/></svg>') 0 5px}| => 'match';

