use strict;
use warnings;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my $Fourth = Fourth->new();
is($Fourth->orig, "FourthSecondFirst", "Third not called");

BEGIN
{
    package First;
    sub new { bless {}, shift }
    sub orig { "First" }

    package Second;
    use Class::Method::Modifiers;
    our @ISA = ('First');
    around orig => sub { "Second" . shift->() };

    package Third;
    use Class::Method::Modifiers;
    our @ISA = ('First');
    around orig => sub { "Third" . shift->() };

    package Fourth;
    use Class::Method::Modifiers;
    our @ISA = ('Second', 'Third');
    around orig => sub { "Fourth" . shift->() };
}

done_testing;
