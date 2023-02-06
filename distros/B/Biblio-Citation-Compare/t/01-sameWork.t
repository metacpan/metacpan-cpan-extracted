use lib '../lib';
use Biblio::Citation::Compare 'sameWork','sameAuthors','toString', 'sameAuthorBits';
use Test::Most;
die_on_fail;

my @samePersonYes = ( 
    [ [ 'D. Bourget', 'Chalmers D' ], ['David J. R. Bourget','David C Chalmers'] ],
    [ [ 'J wilson' ], ['Jessica WILSON'] ],
    [ [ 'J. Wilson' ], ['Jessica M. WILSON'] ],
    [ [ 'D. Bourget', 'J Wilson' ], ['J Wilson'] ]
);

my @samePersonNo = (
    [ [ 'Hunter, David' ], ['Hunter, Daniel'] ],
    [ [ 'D. Bourget', 'J Wilson' ], ['D. Chalmers', 'J Wilson'] ]
);

ok( sameAuthorBits(['Bourget, David','Joseph, richard'], ['David Joseph Richard Bourget']), 'same authors bits works'); 
ok(!sameAuthorBits(['A, A'],['B, B']), 'same authors bits does not overgenerates');

ok( sameAuthors($_->[0],$_->[1]), join(";",@{$_->[0]}) . " = " . join(";",@{$_->[1]})) for @samePersonYes;
ok( !sameAuthors($_->[0],$_->[1]), join(";",@{$_->[0]}) . " != " . join(";",@{$_->[1]})) for @samePersonNo;

my $e1 = {};
my $e2 = {};
my @authors = ('Bourget, David');
$e1->{authors} = \@authors;
$e2->{authors} = \@authors;
$e1->{date} = 2009;
$e2->{date} = 2009;

# Test numeric difference
$e1->{title} = "Chapter 1 of xyz";
$e2->{title} = "Chapter 2 of xyz";
same($e1,$e2,0);

# Test numeric difference
$e1->{title} = "Chapter one of xyz";
$e2->{title} = "Chapter two of xyz";
same($e1,$e2,0);


$e1->{title} = "IV- The first pakladjs lkasdjf ";
$e2->{title} = "X- The first pakladjs lkasdjft ";
same($e1,$e2,0);

$e1->{title} = "Theories of consciousness I";
$e2->{title} = "Theories of consciousness 2";
same($e1,$e2,0);

$e1->{title} = "Theories of consciousness:part I";
$e2->{title} = "Theories of consciousness:part 2";
same($e1,$e2,0);

$e1->{title} = "A book with a bracket (yes? !)";
$e2->{title} = "A book with a bracket";
same($e1,$e2,1);

$e1->{title} = "Coyer and the Enlightenment (Studies on Voltaire)";
$e2->{title} = "Coyer and the Enlightenment";
same($e1,$e2,1);

$e1 = {};
$e2 = {};
@authors = ('Abernethy, George L.');
$e1->{authors} = \@authors;
$e2->{authors} = [@authors,'Langford, Thomas A.'];
$e1->{date} = 1968;
$e2->{date} = 1968;

$e1->{title} = "Philosophy of Religion";
$e2->{title} = "Philosophy of Religion: A Book of Readings";
same($e1,$e2,1);

$e1 = {};
$e2 = {};
@authors = ('Abbot, Francis Ellingwood');
$e1->{authors} = \@authors;
$e2->{authors} = \@authors;
$e1->{date} = 1890;
$e2->{date} = 2010;

$e1->{title} = "The Way Out of Agnosticism: Or, the Philosophy of Free Religion";
$e2->{title} = "The Way Out of Agnosticism, Or, the Philosophy of Free Religion [Microform]";
same($e1,$e2,1);

$e1->{date} = 2008;
$e2->{date} = 2008;
$e1->{title} = "Market Versus Nature: The Social Phiosophy [I.E. Philosophy] of Friedrich Hayek";
$e2->{title} = "Market Versus Nature: the Social Philosophy of Friedrich Hayek";
same($e1,$e2,1);

$e1->{title} = "The Philosophy of John Norris of Bemerton: (1657-1712)";
$e2->{title} = "The philosophy of John Norris of Bemerton: (1657-1712) (Studien und Materialien zur Geschichte der Philosophie : Kleine Reihe ; Bd. 6)";
same($e1,$e2,1);

$e1->{title} = "The Philosophy of John Norris of Bemerton: (1657-1712)";
$e2->{title} = "The philosophy of John Norris of Bemerton: (1657-1712)";
same($e1,$e2,1);

$e1->{title} = "The Philosophy of John Norris of Bemerton: (1657-1712)";
$e2->{title} = "The philosophy of John Norris of Bemerton: (1657-2000)";
same($e1,$e2,0);

$e1->{title} = "Communitarian International Relations: The Epistemic Foundations of International Relations";
$e2->{title} = "Communitarian International Relations: The Epistemic Foundations of International Relations (New International Relations)";
same($e1,$e2,1);

$e1->{title} = '"What is an Apparatus?" and Other Essays';
$e2->{title} = '"What Is an Apparatus?" and Other Essays (Meridian: Crossing Aesthetics)';
same($e1,$e2,1);

$e1->{title} = 'Clearly not the same kalsdfjl;sdfajdfsa lfdkasjfadslkajsdf lasdfkjaf';
$e2->{title} = 'Clearny same the not .x,zcmnvcx zm,xcvnxvc ,mxcvzn xcvxm,zcvnvxc zvv';
same($e1,$e2,0);

$e1->{title} = "Much Ado About 'Something': Critical Notice of Chalmers, Manley, Wasserman, Metametaphysics.";
$e2->{title} = "Much Ado About 'Something'.";

$e1->{authors} = ['Wilson, Jessica M.'];
$e2->{authors} = ['Wilson, J.'];
same($e1,$e2,1);

check(
    ['Dummett, Michael'],
    1973,
    'Frege',
    ['Dummett, Michael'],
    1991,
    'Frege (2nd edition)',
    0
);


check(
    ['Dummett, Michael'],
    1973,
    'Frege',
    ['Dummett, Michael'],
    1991,
    'Frege: Philosophy of Mathematics',
    0
);

check(
    ['Russell, Bertrand'],
    "2009",
    "Bertrand Russell's Best",
    ['Russell, Bertrand'],
    "2009",
    "Bertrand Russell's Best",
    1
);

#
# Common cases of degraded metadata
#

# missing firstname
#check(
#    ['Russell, '],
#    "2009",
#    "Short",
#    ['Russell, B'],
#    "2009",
#    "Short",
#    1
#);
check(
    ['Bourget, David'],
    2008,
    "The title of the work",
    ['Other, Person'],
    2008,
    "The title of the work",
    0
);

check(
    ['John Doe, By'],
    2009,
    'The same title',
    ['Doe, John'],
    2009,
    'The same title',
    1
);

#unsplit name
check(
    ['John Doe'],
    2009,
    'The same title',
    ['Doe, John'],
    2009,
    'The same title',
    1
);

# missing authors
check(
    ['Henry Allison'],2002,"Debating Allison on Transcendental Idealism",
    ['John Doe','Bob Dylan','Henry Allison'],2002,"Debating Allison on Transcendental Idealism",
    1
);

# missing authors with slight typo
check(
    ['H Allison'],2002,"Debating Allison on Transcendental Idealsm",
    ['John Doe','Bob Dylan','Henry Allison'],2002,"Debating Allison on Transcendental Idealism",
    1
);

# missing authors not clear due to date difference
check(
    ['Henry Allison'],2000,"Debating Allison on Transcendental Idealsm",
    ['John Doe','Bob Dylan','Henry Allison'],2002,"Debating Allison on Transcendental Idealism",
    1
);

# missing authors not clear due to date difference
check(
    ['Henry Allison'],2000,"Debating Allison on Idealsm",
    ['John Doe','Bob Dylan','Henry Allison'],2002,"Debating Allison on Transcendental Idealism",
    0
);

check(
    ['J. Nagel'],1974, "What is It Like to Be a Bat? Philosophical Review",
    ['J. Nagel'],1974, "What is It Like to Be a Bat?",
    1
);

check(
    ['J. Nagel'],1974, "What is It Like to Be a Bat: Philosophical Review",
    ['J. Nagel'],1974, "What is It Like to Be a Bat:",
    1
);

check(
    ['J. Nagel'],1974, "What is It Like to Be a Bat. Philosophical Review",
    ['J. Nagel'],1974, "What is It Like to Be a Bat.",
    1
);

check(
    ['J. Nagel'],1974, "What is It Like to Be a Bat. Philosophical Review",
    ['J. Nagel'],1974, "What is It Like to Be a Bat",
    1
);

check(
    ['Fredrik Björklund', 'Gunnar Björnsson', 'John Eriksson', 'Ragnar Francén Olinder', 'Caj Strandberg'],2012,"Recent Work on Motivational Internalism",
    ['F. Bjorklund', 'G. Bjornsson', 'J. Eriksson', 'R. Francen Olinder', 'C. Strandberg'],2012,"Recent Work on Motivational Internalism",
    1
);

check(
    ['Gunnar Björnsson','Fredrik Björklund'],2012,"Recent Work on Motivational Internalism",
    ['F. Bjorklund', 'G. Bjornsson'],2012,"Recent Work on Motivational Internalism!",
    1
);

check(
    ['Gunnar Björnsson'],2012,"Recent Work on Motivational Internalism",
    ['F. Bjorklund', 'G. Bjornsson'],2012,"Recent Work on Motivational Internalism!",
    1
);

check(
    ['Uriah Kriegel'],2011,"The Sources of Intentionality",
    ['Uriah Kriegel'],2014,"_The Sources of Intentionality_",
    1
);

check(
    ['Uriah Kriegel'],2005,"Real Intentionality V.2: Why intentionality entails consciousness",
    ['Uriah Kriegel'],2008,"Real Intentionality 3: Why intentionality entails consciousness",
    0
);




ok(
  sameWork(
    # first item
    {
        authors => ['Bourget, D','Lukasiak, Zbigniew'],
        title => "A paper with such and such a title",
        date => 2010
    },
    # second item
    {
        authors => ['Bourget, David J. R.','Lukasiak, Zbigniew'],
        title => "A paper with such nd such a tlitle",
        date => undef
    }
  ),

  'Documentation example'
);


sub same {
    my ($e1,$e2,$same) = @_;
    is(sameWork($e1,$e2),$same, toString($e1) . ' ' . ($same ? ' == ' : ' != ') . ' ' . toString($e2));
}

sub check {
    my ($authors1, $date1, $title1, $authors2, $date2, $title2, $yes) = @_;
    my $e1 = {title=>$title1,date=>$date1};
    $e1->{authors} = $authors1;
    my $e2 = {title=>$title2,date=>$date2};
    $e2->{authors} = $authors2;
    return same($e1,$e2,$yes);
}

done_testing();
