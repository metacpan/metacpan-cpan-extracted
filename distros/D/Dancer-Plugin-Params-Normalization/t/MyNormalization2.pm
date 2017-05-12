#
# This file is part of Dancer-Plugin-Params-Normalization
#
# This software is copyright (c) 2011 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package MyNormalization2;
use strict;
use warnings;
use base qw(Dancer::Plugin::Params::Normalization::Abstract);

# shorten to 3 last caracters
sub normalize {
    my ($self, $params) = @_;
    $params->{substr($_, -3, 3)} = delete $params->{$_} foreach keys %$params;
    return $params;
}

1;
