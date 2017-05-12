#!/usr/bin/perl -w
use strict;

use Data::FormValidator::Constraints::Words;
use Test::More tests => 98;

# list items:
# 0 .... test pattern
# 1 .... valid_realname
# 2 .... match_realname
# 3 .... valid_basicwords
# 4 .... match_basicwords
# 5 .... valid_simplewords
# 6 .... match_simplewords
# 7 .... valid_printsafe
# 8 .... match_printsafe
# 9 .... valid_paragraph
# 10 ... match_paragraph
# 11 ... valid_username
# 12 ... match_username
# 13 ... valid_password
# 14 ... match_password

my @examples = (
    [ undef,        0, undef,      '', undef,   '', undef,        undef, undef,        '', undef,        '', undef,   '', undef         ],
    [ '',           0, '',         '', undef,   '', undef,        0,     undef,        '', undef,        '', undef,   '', undef         ],
    [ 'hello',      1, 'hello',    1,  'hello', 1,  'hello',      1,     'hello',      1,  'hello',      1,  'hello', 1,  'hello'       ],
    [ 'Pr;n+.5afe', 0, 'Prn.5afe', '', undef,   1,  'Pr;n+.5afe', 1,     'Pr;n+.5afe', 1,  'Pr;n+.5afe', '', undef,   1,  'Pr;n+.5afe'  ],
    [ '$@pare',     0, 'pare',     '', undef,   '', undef,        1,     '$@pare',     1,  '$@pare',     '', undef,   1,  '$@pare'      ],
    [ 'a to b',     1, 'a to b',   1, 'a to b', 1, 'a to b',      1,     'a to b',     1,  'a to b',     '', undef,   '', undef         ],
    [ 'bãrbïé',     1, 'bãrbïé',   1, 'bãrbïé', 1, 'bãrbïé',      1,     'bãrbïé',     1,  'bãrbïé',     1, 'bãrbïé', 1,  'bãrbïé'      ],
);

for my $ex (@examples) {
    is(valid_realname(   undef,$ex->[0]), $ex->[1],  (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " validates as expected for realname"    );
    is(match_realname(   undef,$ex->[0]), $ex->[2],  (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " matches as expected for realname"      );
    is(valid_basicwords( undef,$ex->[0]), $ex->[3],  (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " validates as expected for basicwords"  );
    is(match_basicwords( undef,$ex->[0]), $ex->[4],  (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " matches as expected for basicwords"    );
    is(valid_simplewords(undef,$ex->[0]), $ex->[5],  (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " validates as expected for simplewords" );
    is(match_simplewords(undef,$ex->[0]), $ex->[6],  (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " matches as expected for simplewords"   );
    is(valid_printsafe(  undef,$ex->[0]), $ex->[7],  (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " validates as expected for printsafe"   );
    is(match_printsafe(  undef,$ex->[0]), $ex->[8],  (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " matches as expected for printsafe"     );
    is(valid_paragraph(  undef,$ex->[0]), $ex->[9],  (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " validates as expected for paragraph"   );
    is(match_paragraph(  undef,$ex->[0]), $ex->[10], (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " matches as expected for paragraph"     );
    is(valid_username(   undef,$ex->[0]), $ex->[11], (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " validates as expected for username"    );
    is(match_username(   undef,$ex->[0]), $ex->[12], (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " matches as expected for username"      );
    is(valid_password(   undef,$ex->[0]), $ex->[13], (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " validates as expected for password"    );
    is(match_password(   undef,$ex->[0]), $ex->[14], (defined $ex->[0] ? "'$ex->[0]'" : "'undef'") . " matches as expected for password"      );
}
