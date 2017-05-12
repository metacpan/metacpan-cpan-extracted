#!perl -w

use Test::More tests => 22;
use Acme::Numbers;

is(four.pounds."",                       "4.00", "No pence");
is(four.pounds.fifty."",                 "4.50", "Trailing zero");
is(four.pounds.five."",                  "4.05", "Leading zero");
is(four.pounds.fifty.five."",            "4.55", "No zero");

is(four.pound."",                        "4.00", "No pence (no 's')");
is(four.pound.fifty."",                  "4.50", "Trailing zero (no 's')");
is(four.pound.five."",                   "4.05", "Leading zero (no 's')");
is(four.pound.fifty.five."",             "4.55", "No zero  (no 's')");

is(fifty.five.pence."",                  "0.55", "Pence no pounds");
is(fifty.pence."",                       "0.50", "Pence no pounds, trailing zero");
is(four.pounds.fifty.pence."",           "4.50", "Pence with pounds, trailing zero");
is(four.pounds.fifty.five.pence."",      "4.55", "Pence with pounds");
is(four.pounds.and.fifty.five.pence."",  "4.55", "Pence and pounds");

is(fifty.five.p."",                      "0.55", "p no pounds");
is(fifty.p."",                           "0.50", "p no pounds, trailing zero");
is(four.pounds.fifty.p."",               "4.50", "p with pounds, trailing zero");
is(four.pounds.fifty.five.p."",          "4.55", "p with pounds");
is(four.pounds.and.fifty.five.p."",      "4.55", "p and pounds");

is(fifty.five.cents."",                  "0.55", "Cents no dollars");
is(fifty.cents."",                       "0.50", "Cents no dollars, trailing zero");
is(four.dollars.fifty.five.cents."",     "4.55", "Cents with dollars");
is(four.dollars.and.fifty.five.cents."", "4.55", "Cents and dollars");
