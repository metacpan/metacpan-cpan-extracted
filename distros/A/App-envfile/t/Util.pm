package t::Util;

use strict;
use warnings;
use base 'Exporter';
use Test::More;

our @EXPORT = 'runtest';

# subtest like function
sub runtest {
    my ($desc, $code) = @_;
    note '-'x80;
    note $desc;
    note '-'x80;
    $code->();
}

1;
