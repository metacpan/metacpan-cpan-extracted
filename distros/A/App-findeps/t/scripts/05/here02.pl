use strict;
use warnings;

# the inside of here document must be excluded from parsing
my $here = <<'EOL';
    require Module::Exists;
    use Here;
EOL

$here = <<"EOL";
    require Here;
    use Module::Exists;
EOL

require Dummy;    # does not exist anywhere

exit;
