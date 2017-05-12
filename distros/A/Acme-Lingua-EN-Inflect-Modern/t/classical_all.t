use Acme::Lingua::EN::Inflect::Modern qw(PL_N classical);
use Test::More 'no_plan';

# DEFAULT...

is PL_N("error", 0)    => "error's";          # classical "zero" not active
is PL_N("wildebeest")  => "wildebeest's";     # classical "herd" not active
is PL_N("Sally")       => "Sally's";          # classical "names" active
is PL_N("brother")     => "brother's";        # classical others not active
is PL_N("person")      => "people";           # classical "persons" not active
is PL_N("formula")     => "formula's";        # classical "ancient" not active

# CLASSICAL PLURALS ACTIVATED...

classical "all";
is PL_N("error", 0)    => "error";           # classical "zero" active
is PL_N("wildebeest")  => "wildebeest";      # classical "herd" active
is PL_N("Sally")       => "Sally's";         # classical "names" active
is PL_N("brother")     => "brethren";        # classical others active
is PL_N("person")      => "person's";        # classical "persons" active
is PL_N("formula")     => "formulae";        # classical "ancient" active


# CLASSICAL PLURALS DEACTIVATED...

classical all => 0;
is PL_N("error", 0)    => "error's";          # classical "zero" not active
is PL_N("wildebeest")  => "wildebeest's";     # classical "herd" not active
is PL_N("Sally")       => "Sally's";          # classical "names" not active
is PL_N("brother")     => "brother's";        # classical others not active
is PL_N("person")      => "people";           # classical "persons" not active
is PL_N("formula")     => "formula's";        # classical "ancient" not active


# CLASSICAL PLURALS REACTIVATED...

classical all => 1;
is PL_N("error", 0)    => "error";           # classical "zero" active
is PL_N("wildebeest")  => "wildebeest";      # classical "herd" active
is PL_N("Sally")       => "Sally's";         # classical "names" active
is PL_N("brother")     => "brethren";        # classical others active
is PL_N("person")      => "person's";        # classical "persons" active
is PL_N("formula")     => "formulae";        # classical "ancient" active


# CLASSICAL PLURALS REDEACTIVATED...

classical 0;
is PL_N("error", 0)    => "error's";          # classical "zero" not active
is PL_N("wildebeest")  => "wildebeest's";     # classical "herd" not active
is PL_N("Sally")       => "Sally's";          # classical "names" not active
is PL_N("brother")     => "brother's";        # classical others not active
is PL_N("person")      => "people";           # classical "persons" not active
is PL_N("formula")     => "formula's";        # classical "ancient" not active


# CLASSICAL PLURALS REREACTIVATED...

classical 1;
is PL_N("error", 0)    => "error";           # classical "zero" active
is PL_N("wildebeest")  => "wildebeest";      # classical "herd" active
is PL_N("Sally")       => "Sally's";         # classical "names" active
is PL_N("brother")     => "brethren";        # classical others active
is PL_N("person")      => "person's";        # classical "persons" active
is PL_N("formula")     => "formulae";        # classical "ancient" active


# CLASSICAL PLURALS REREDEACTIVATED...

classical 0;
is PL_N("error", 0)    => "error's";          # classical "zero" not active
is PL_N("wildebeest")  => "wildebeest's";     # classical "herd" not active
is PL_N("Sally")       => "Sally's";          # classical "names" not active
is PL_N("brother")     => "brother's";        # classical others not active
is PL_N("person")      => "people";           # classical "persons" not active
is PL_N("formula")     => "formula's";        # classical "ancient" not active


# CLASSICAL PLURALS REREREACTIVATED...

classical;
is PL_N("error", 0)    => "error";           # classical "zero" active
is PL_N("wildebeest")  => "wildebeest";      # classical "herd" active
is PL_N("Sally")       => "Sally's";         # classical "names" active
is PL_N("brother")     => "brethren";        # classical others active
is PL_N("person")      => "person's";        # classical "persons" active
is PL_N("formula")     => "formulae";        # classical "ancient" active
