#
# This file is part of Dancer-Plugin-Redis
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package FakeRedis;

use strict;
use warnings;
{

    package Redis;
    $INC{'Redis.pm'} = 1;
    our $VERSION = 2;
    our $AUTOLOAD;

    sub new {
        my ( $class, %args ) = @_;
        bless \%args => $class;
    }

    sub AUTOLOAD {
        shift;
        my $name = $AUTOLOAD;
        $name =~ s/.*://;
        return $name, @_;
    }
}

1;
