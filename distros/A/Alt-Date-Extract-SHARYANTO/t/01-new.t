#!perl -T
use strict;
use warnings;
use Test::More tests => 37;
use Date::Extract;

my $parser = Date::Extract->new();
ok($parser, "got a parser out of Date::Extract->new");
ok($parser->isa("Date::Extract"), "new parser is a Date::Extract object");

# returns {{{
for my $opt (qw/first last earliest latest all all_cron/) {
    $parser = Date::Extract->new(returns => $opt);
    ok($parser, "got a parser out of Date::Extract->new(returns => '$opt')");
    ok($parser->isa("Date::Extract"), "new parser is a Date::Extract object");
}

$parser = eval { Date::Extract->new(returns => "invalid argument") };
ok(!$parser, "did NOT get a parser out of Date::Extract->new(returns => 'invalid argument')");
like($@, qr/Invalid `returns` passed to constructor/, "(returns => 'invalid argument') gave a sensible error message");
like($@, qr/01-new\.t/, "invalid `returns` error reported from caller's perspective");

# }}}
# prefer nearest, prefer future, prefer past {{{
for my $opt (qw/nearest future past/) {
    $parser = Date::Extract->new(prefer => $opt);
    ok($parser, "got a parser out of Date::Extract->new(prefers => '$opt')");
    ok($parser->isa("Date::Extract"), "new parser is a Date::Extract object");
}

$parser = eval { Date::Extract->new(prefers => "invalid argument") };
ok(!$parser, "did NOT get a parser out of Date::Extract->new(prefers => 'invalid argument')");
like($@, qr/Invalid `prefers` passed to constructor/, "(prefers => 'invalid argument') gave a sensible error message");
like($@, qr/01-new\.t/, "invalid `prefers` error reported from caller's perspective");

# }}}

# format {{{
$parser = eval { Date::Extract->new(format => "invalid argument") };
ok(!$parser, "did NOT get a parser out of Date::Extract->new(format => 'invalid argument')");
like($@, qr/Invalid `format` passed to constructor/, "(format => 'invalid argument') gave a sensible error message");
like($@, qr/01-new\.t/, "invalid `format` error reported from caller's perspective");

for my $opt (qw/DateTime verbatim epoch combined/) {
    $parser = Date::Extract->new(format => $opt);
    ok($parser, "got a parser out of Date::Extract->new(format => '$opt')");
    ok($parser->isa("Date::Extract"), "new parser is a Date::Extract object");
}
# }}}
