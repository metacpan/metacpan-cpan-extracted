#!/usr/bin/env perl

use strict;
use warnings;

use feature qw(say);

our $VERSION = "0.01";
my @here = ( <<"FIRST", <<'SECOND', <<END);
the inside of here document must be excluded from parsing
    require FIRST;
    use HERE::First;
FIRST
here is still inside..
    require SECOND;
    use HERE::Second;
SECOND
here is still inside..
    require END;
    use HERE::End;
END

# now it is outside

require Dummy;    # does not exist anywhere

exit;
