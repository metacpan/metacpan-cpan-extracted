#$Id: 00_compile.t,v 1.1 2005/11/14 03:39:09 naoya Exp $
use strict;
use Test::More qw(no_plan);

## basic classes
BEGIN { use_ok 'Acme::Web20::Validator' }
BEGIN { use_ok 'Acme::Web20::Validator::Rule' }

use Acme::Web20::Validator::Rule;
my $rule = Acme::Web20::Validator::Rule->new;
for ($rule->plugins) {
    use_ok($_);
}

