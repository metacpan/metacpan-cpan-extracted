package BasicTestApp;

use strict;
use warnings FATAL => 'all';
our $VERSION = 0.01;

use Catalyst qw[HashedCookies];
use File::Spec::Functions qw[catpath splitpath rel2abs];

__PACKAGE__->config(
    name => 'BasicTestApp',
    root => rel2abs( catpath( ( splitpath($0) )[0,1], '' ) ),
);

1;
