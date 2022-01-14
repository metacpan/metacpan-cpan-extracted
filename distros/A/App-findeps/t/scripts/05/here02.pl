use strict;
use warnings;

# the inside of here document must be excluded from parsing
my $here = <<'EOL';
    require Module::Exists::In::HERE;
    use Module::Exists::In::HERE;
EOL

$here = <<"EOL";
    require Module::Exists::In::HERE;
    use Module::Exists::In::HERE;
EOL

require Acme::BadExample;    # does not exist anywhere

