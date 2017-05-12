use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

# inheritance tree looks like:
#
#    SuperL        SuperR
#      \             /
#      MiddleL  MiddleR
#         \       /
#          -Child-

# the Child and MiddleR modules use modifiers
# Child will modify a method in SuperL (sl_c)
# Child will modify a method in SuperR (sr_c)
# Child will modify a method in SuperR already modified by MiddleR (sr_m_c)
# SuperL and MiddleR will both have a method of the same name, doing different
#     things (called 'conflict' and 'cnf_mod')

# every method and modifier will just return <Class:Method:STUFF>

my $SuperL = SuperL->new();
my $SuperR = SuperR->new();
my $MiddleL = MiddleL->new();
my $MiddleR = MiddleR->new();
my $Child = Child->new();

is($SuperL->superl, "<SuperL:superl>", "SuperL loaded correctly");
is($SuperR->superr, "<SuperR:superr>", "SuperR loaded correctly");
is($MiddleL->middlel, "<MiddleL:middlel>", "MiddleL loaded correctly");
is($MiddleR->middler, "<MiddleR:middler>", "MiddleR loaded correctly");
is($Child->child, "<Child:child>", "Child loaded correctly");

is($SuperL->sl_c, "<SuperL:sl_c>", "SuperL->sl_c on SuperL");
is($Child->sl_c, "<Child:sl_c:<SuperL:sl_c>>", "SuperL->sl_c wrapped by Child's around");

is($SuperR->sr_c, "<SuperR:sr_c>", "SuperR->sr_c on SuperR");
is($Child->sr_c, "<Child:sr_c:<SuperR:sr_c>>", "SuperR->sr_c wrapped by Child's around");

is($SuperR->sr_m_c, "<SuperR:sr_m_c>", "SuperR->sr_m_c on SuperR");
is($MiddleR->sr_m_c, "<MiddleR:sr_m_c:<SuperR:sr_m_c>>", "SuperR->sr_m_c wrapped by MiddleR's around");
is($Child->sr_m_c, "<Child:sr_m_c:<MiddleR:sr_m_c:<SuperR:sr_m_c>>>", "MiddleR->sr_m_c's wrapping wrapped by Child's around");

is($SuperL->conflict, "<SuperL:conflict>", "SuperL->conflict on SuperL");
is($MiddleR->conflict, "<MiddleR:conflict>", "MiddleR->conflict on MiddleR");
is($Child->conflict, "<SuperL:conflict>", "SuperL->conflict on Child");

is($SuperL->cnf_mod, "<SuperL:cnf_mod>", "SuperL->cnf_mod on SuperL");
is($MiddleR->cnf_mod, "<MiddleR:cnf_mod>", "MiddleR->cnf_mod on MiddleR");
is($Child->cnf_mod, "<Child:cnf_mod:<SuperL:cnf_mod>>", "SuperL->cnf_mod wrapped by Child's around");

BEGIN
{
    {
        package SuperL;

        sub new { bless {}, shift }
        sub superl { "<SuperL:superl>" }
        sub conflict { "<SuperL:conflict>" }
        sub cnf_mod { "<SuperL:cnf_mod>" }
        sub sl_c { "<SuperL:sl_c>" }
    }

    {
        package SuperR;

        sub new { bless {}, shift }
        sub superr { "<SuperR:superr>" }
        sub sr_c { "<SuperR:sr_c>" }
        sub sr_m_c { "<SuperR:sr_m_c>" }
    }

    {
        package MiddleL;
        our @ISA = 'SuperL';

        sub middlel { "<MiddleL:middlel>" }
    }

    {
        package MiddleR;
        our @ISA = 'SuperR';
        use Class::Method::Modifiers;

        sub middler { "<MiddleR:middler>" }
        sub conflict { "<MiddleR:conflict>" }
        sub cnf_mod { "<MiddleR:cnf_mod>" }
        around sr_m_c => sub {
            my $orig = shift;
            return "<MiddleR:sr_m_c:".$orig->(@_).">"
        };
    }

    {
        package Child;
        our @ISA = ('MiddleL', 'MiddleR');
        use Class::Method::Modifiers;

        sub child { "<Child:child>" }
        around cnf_mod => sub { "<Child:cnf_mod:".shift->(@_).">" };
        around sl_c => sub { "<Child:sl_c:".shift->(@_).">" };
        around sr_c => sub { "<Child:sr_c:".shift->(@_).">" };
        around sr_m_c => sub {
            my $orig = shift;
            return "<Child:sr_m_c:".$orig->(@_).">"
        };
    }
}

done_testing;
