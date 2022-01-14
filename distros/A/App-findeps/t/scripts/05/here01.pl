use strict;
use warnings;

my $here = <<EOL;    # the inside of here document must be excluded from parsing
    require Module::Exists::In::HERE;
    use Module::Exists::In::HERE;
EOL

require Acme::BadExample;    # does not exist anywhere

