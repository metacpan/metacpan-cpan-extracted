use strict;
use warnings;

my $here = <<EOL;    # the inside of here document must be excluded from parsing
    require HERE;
    use HERE::Somthing;
EOL

require Dummy;       # does not exist anywhere

exit;
