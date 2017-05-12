use Acme::Lingua::EN::Inflect::Modern qw(PL_N classical);
use Test::More 'no_plan';

# DEFAULT...

is PL_N('error', 0)    => "error's";          # classical 'zero' not active

# "person" PLURALS ACTIVATED...

classical zero => 1;
is PL_N('error', 0)    => 'error';            # classical 'zero' active

# OTHER CLASSICALS NOT ACTIVATED...

is PL_N('wildebeest')  => "wildebeest's";     # classical 'herd' not active
is PL_N('Sally')       => "Sally's";          # classical 'names' active
is PL_N('brother')     => "brother's";        # classical 'all' not active
is PL_N('person')      => "people";           # classical 'persons' not active
is PL_N('formula')     => "formula's";        # classical 'ancient' not active
