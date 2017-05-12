#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

my $CLASS = "Local::Test::Dialect";

# Test making a dialect
{

    package Local::Test::Dialect;

    use SQL::Dialects::Role;

    sub get_config
    {
        # There's some deliberate whitespace abuse in here
        return <<END;
  
[THINGS]
elephants
FEELINGS
stuff
  

[RESERVED WORDS]
FOO
BAR
BAZ

END

    }
}

is_deeply(
           $CLASS->get_config_as_hash(),
           {
              things => {
                          ELEPHANTS => 1,
                          FEELINGS  => 1,
                          STUFF     => 1,
                        },
              reserved_words => {
                                  FOO => 1,
                                  BAR => 1,
                                  BAZ => 1
                                }
           }
         );

# Test role injection
{
    {

        package SQL::Dialects::Test::NoRole;

        sub get_config
        {
            return <<DONE;
[FOO]
bar
baz
DONE
        }
    }

    use SQL::Parser;
    my $parser = SQL::Parser->new();
    ok eval { $parser->dialect("Test::NoRole"); 1; } or diag($@);
}
