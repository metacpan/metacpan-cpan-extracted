use strict;
use warnings;

use feature qw(say);

our $VERSION = "0.01";
my @here = ( <<"FIRST", <<'SECOND', <<END);
the inside of here document must be excluded from parsing
    require Module::Exists::In::HERE;
    use Module::Exists::In::HERE;
FIRST
here is still inside..
    require Module::Exists::In::HERE;
    use Module::Exists::In::HERE;
SECOND
here is still inside too ..
    require Module::Exists::In::HERE;
    use Module::Exists::In::HERE;
END

# now it is outside

require Acme::BadExample;    # does not exist anywhere

