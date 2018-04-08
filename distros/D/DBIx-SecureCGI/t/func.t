use lib 't';
use share;

plan tests => 39;

my $dbh = new_dbh {RaiseError=>1,PrintError=>0};
my $table = new_table "id $PK, i INT, s VARCHAR(255), d DATETIME";
my $D1 = '2000-01-01 01:00:00';
my $D2 = '2000-01-01 02:00:00';
my $D3 = '2000-01-01 03:00:00';
my $D4 = '2000-01-01 04:00:00';
$dbh->Insert($table, $_) for
    {i=>0}, {s=>q{}}, {i=>1,d=>$D1}, {s=>'two',d=>$D2},
    {i=>3,s=>'three',d=>$D3}, {i=>4,s=>'four',d=>$D4};
my @R = (
    undef,
    {id=>1, i=>0,       s=>undef,   d=>undef},
    {id=>2, i=>undef,   s=>q{},     d=>undef},
    {id=>3, i=>1,       s=>undef,   d=>$D1},
    {id=>4, i=>undef,   s=>'two',   d=>$D2},
    {id=>5, i=>3,       s=>'three', d=>$D3},
    {id=>6, i=>4,       s=>'four',  d=>$D4},
);

sub sel {
    is_deeply([$dbh->Select($table, shift)], [@R[@_]]);
}
sel {i=>undef},                     2,4;
sel {i__eq=>undef},                 2,4;
sel {i__ne=>undef},                 1,3,5,6;
sel {i=>0},                         1;
sel {i__eq=>0},                     1;
sel {i__ne=>0},                     2,3,4,5,6;
sel {i__eq=>[]},                    ();
sel {i__ne=>[]},                    1..6;
sel {i__eq=>[undef]},               2,4;
sel {i__ne=>[undef]},               1,3,5,6;
sel {i__eq=>[0]},                   1;
sel {i__ne=>[0]},                   2,3,4,5,6;
sel {i__ne=>undef,s__ne=>undef},    5,6;
sel {i__eq=>[undef,1,3]},           2,3,4,5;
sel {i__ne=>[undef,1,3]},           1,6;
sel {i__eq=>[1,3]},                 3,5;
sel {i__ne=>[1,3]},                 1,2,4,6;
sel {i__gt=>1},                     5,6;
sel {i__lt=>1},                     1;
sel {i__ge=>1},                     3,5,6;
sel {i__le=>1},                     1,3;
sel {s__like=>'t'},                 ();
sel {s__like=>'t%'},                4,5;
sel {s__like=>'%o%'},               4,6;
sel {s__like=>'%'},                 2,4,5,6;
sel {s__not_like=>'%'},             ();
sel {s__not_like=>'X'},             2,4,5,6;
sel {s__not_like=>'t%'},            2,6;
sel {d=>$D2},                       4;
sel {d__date_lt=>'0 SECOND'},       3,4,5,6;
sel {d__date_gt=>'0 SECOND'},       ();
sel {d__date_gt=>'-100 YEAR'},      3,4,5,6;

is 0+(()=$dbh->Select($table, {d__date_gt=>'-5 SECOND'})), 0;
ok $dbh->Insert($table, {d__set_date=>'NoW'});
is 0+(()=$dbh->Select($table, {d__date_gt=>'-5 SECOND'})), 1;

is 0+(()=$dbh->Select($table, {i__gt=>100})), 0;
ok $dbh->Update($table, {i__set_add=>100, i__gt=>1});
is 0+(()=$dbh->Select($table, {i__gt=>100})), 2;

throws_ok { $dbh->Select($table, {d__date_gt=>'-5 DAYS'}) }
    qr/bad value/;


done_testing();
