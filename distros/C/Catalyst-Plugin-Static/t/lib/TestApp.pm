package TestApp;
use strict;
use warnings;

use Catalyst qw[Static];
use File::Spec::Functions qw[catpath splitpath rel2abs];

__PACKAGE__->config(
    root => rel2abs( catpath( ( splitpath($0) )[0,1], '' ) )
);

__PACKAGE__->setup();

1;

