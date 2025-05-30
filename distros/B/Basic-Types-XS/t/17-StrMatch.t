use strict;
use warnings;
use Test::More;
use Basic::Types::XS qw(StrMatch);

my $type = StrMatch(validate => qr/^\d+$/);
is($type->("12345"), "12345", 'digits match');

eval { $type->("abc") };
like($@, qr/value did not pass type constraint "StrMatch"/, 'non-matching string croaks');

$type = StrMatch(validate => qr/foo/, message => "Not foo!");
is($type->("foo bar"), "foo bar");

eval { $type->("bar") };
like($@, qr/Not foo!/, 'custom error message croaks');

$type = StrMatch(validate => qr/^.+$/u);

is($type->("αβγ"), "αβγ", 'unicode letters match');
$type = StrMatch(validate => qr/^abc$/i);
is($type->("ABC"), "ABC", 'case-insensitive match');

$type = StrMatch(validate => qr/^$/);
is($type->(""), "", 'empty string matches empty pattern');

done_testing;
