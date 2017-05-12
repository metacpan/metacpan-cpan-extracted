use strict;
use Test::More;

BEGIN
{
    eval { require GTop };
    if ($@) {
        plan skip_all => 'Gtop not available';
    } else {
        plan tests => 1;
        use_ok("Catalyst::Plugin::Apoptosis::GTop");
    }
}

1;