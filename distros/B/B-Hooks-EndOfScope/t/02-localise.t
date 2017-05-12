use strict;
use warnings;

use Test::More 0.89;

use B::Hooks::EndOfScope;

{
    my $fired;

    {
        BEGIN { on_scope_end { $fired++ } }

        BEGIN { ok(!$fired) }

        BEGIN { local %^H }

        BEGIN { ok(!$fired) }
    }

    BEGIN { ok($fired) }
}

{
    my $fired;

    {
        BEGIN { on_scope_end { $fired++ } }
        BEGIN { ok(!$fired) }

        BEGIN {
            local %^H;

            my $fired2;
            {
                BEGIN { on_scope_end { $fired2++ } }
                BEGIN { ok(!$fired2) }
                BEGIN { local %^H }
                BEGIN { ok(!$fired2) }
            }
            BEGIN { ok($fired2) }
        }

        BEGIN { ok(!$fired) }
    }

    BEGIN { ok($fired) }
}

done_testing;
