# $Id: Biblio-EndnoteStyle.t,v 1.4 2007/03/14 11:12:49 mike Exp $

use strict;
use warnings;

use vars qw(@tests);

BEGIN {
    @tests = (
	[ ";Author: ", ";Taylor: ", "author provided" ],
	[ ";`Author`: ", ";Author: ", "author quoted" ],
	[ ";Title: ", "", "title empty" ],
	[ ";Title|: ", ": ", "title empty 2" ],
	[ ";Title|: ", ": ", "title empty 2" ],
	[ ";Title |: ", ": ", "title empty 3" ],
	[ ";Title¬|: ", ": ", "absent title with nbsp" ],
	[ ";Author¬|: ", ";Taylor : ", "present author with nbsp" ],
	[ ";NoSuchField: ", ";NoSuchField: ", "NoSuchField absent" ],
    );
};

use Test::More tests => 2+@tests;

BEGIN { use_ok('Biblio::EndnoteStyle') };

my $style = new Biblio::EndnoteStyle();
ok(1, "made style object");

my $data = { Author => "Taylor", Title => "" };

foreach my $test (@tests) {
    my($template, $result, $description) = @$test;
    #print("[", $style->format($template, $data), "]\n");
    my $actual = $style->format($template, $data);
    if ($actual eq $result) {
	ok(1, $description);
    } else {
	ok(0, qq[$description: expected "$result", got "$actual"]);
    }
}
