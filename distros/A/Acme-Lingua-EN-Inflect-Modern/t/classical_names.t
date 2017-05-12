use Acme::Lingua::EN::Inflect::Modern qw(PL_N classical);
use Test::More "no_plan";

# DEFAULT...

is PL_N("Sally")       => "Sally's";           # classical "names" active
is PL_N("Jones", 0)    => "Jones's";          # always inflects that way

# "person" PLURALS ACTIVATED...

classical "names";
is PL_N("Sally")       => "Sally's";          # classical "names" active
is PL_N("Jones", 0)    => "Jones's";          # always inflects that way

# OTHER CLASSICALS NOT ACTIVATED...

is PL_N("wildebeest")  => "wildebeest's";     # classical "herd" not active
is PL_N("error", 0)    => "error's";          # classical "zero" not active
is PL_N("brother")     => "brother's";        # classical "all" not active
is PL_N("person")      => "people";           # classical "persons" not active
is PL_N("formula")     => "formula's";        # classical "ancient" not active

# "person" PLURALS DEACTIVATED...

classical names=>0;
is PL_N("Sally")       => "Sally's";          # classical "names" not active
is PL_N("Jones", 0)    => "Jones's";          # always inflects that way

