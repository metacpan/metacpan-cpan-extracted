use strict;
use warnings;

use Test::More;

# This test is the internal parsing logic, separated for testing

is( parse_string('fr'), 'fr');
is( parse_string('en-US'), 'en');
is( parse_string('da, en-gb;q=0.8, en;q=0.7'), 'da');
is( parse_string("de-DE,en-GB;q=0.8,de;q=0.5,en;q=0.3"), 'de');

done_testing;


sub parse_string {
    my $lang = shift;

    $lang =~ s/-\w+//g;
print "-- $lang \n";
    $lang = (split(/,\s*/,$lang))[0] if index($lang,',');
print "-- $lang \n";
    return $lang;
}
