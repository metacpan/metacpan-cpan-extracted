use strict;
use Test::More;
use AnyEvent::Twitter;
use Time::Piece;

{
    my $created_at = AnyEvent::Twitter->parse_timestamp("Mon Jun 11 05:58:31 +0000 2007");
    isa_ok $created_at, "Time::Piece";
}

{
    my $original = gmtime->strptime("2012-03-01 17:38:56", '%Y-%m-%d %T');
    my $parsed   = AnyEvent::Twitter->parse_timestamp("Thu Mar 01 17:38:56 +0000 2012");

    note sprintf "%s (tzoffset: %s)", $original->datetime, $original->tzoffset;
    note sprintf "%s (tzoffset: %s)", $parsed->datetime, $parsed->tzoffset;

    ok $original->epoch == $parsed->epoch;
}

done_testing;

