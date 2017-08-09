#
# This file is part of App-Milter-Limit
#
# This software is copyright (c) 2010 by Michael Schout.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

package App::Milter::Limit::Plugin::Test;

use strict;
use warnings;
use base qw(App::Milter::Limit::Plugin);

sub init {
    # driver init
}

# the test driver merely returns whatever numbers are in the from address as
# the number of hits, or "1"
sub query {
    my ($self, $from) = @_;

    $from =~ s/[^0-9]//g;

    return $from || 1;
}

1;
