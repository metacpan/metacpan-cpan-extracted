package Mock;

use strict;
use warnings;

use parent 'Exporter';
our @EXPORT_OK = qw(mock_method);

sub mock_method {
    my ($method, $sub) = @_;

    no warnings 'redefine';
    no strict 'refs';

    *$method = $sub;
}

1;
