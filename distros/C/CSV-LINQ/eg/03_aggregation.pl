use strict;
BEGIN {
    if (!defined(&warnings::import)) {
        package warnings;
        sub import {}
        $INC{'warnings.pm'} = __FILE__;
    }
}
use warnings;
local $^W = 1;

BEGIN { pop @INC if $INC[-1] eq '.' }

use FindBin;
use lib "$FindBin::Bin/../lib";

use CSV::LINQ;

# Demonstrates: From, Range, SelectMany, Union, Intersect, Except,
#               Aggregate, Contains, SequenceEqual, Zip, ToArray

print "=== Range and aggregation ===\n";
my $sum  = CSV::LINQ->Range(1, 100)->Sum();
my $avg  = CSV::LINQ->Range(1, 100)->Average();
my $prod = CSV::LINQ->Range(1, 5)->Aggregate(1, sub { $_[0] * $_[1] });
print "  Sum(1..100) = $sum\n";
print "  Avg(1..100) = $avg\n";
print "  5!          = $prod\n";

print "\n=== Set operations ===\n";
my $q1 = CSV::LINQ->From([ 1, 2, 3, 4, 5 ]);
my $q2 = CSV::LINQ->From([ 3, 4, 5, 6, 7 ]);

my @union  = $q1->Union($q2)->ToArray();
$q1 = CSV::LINQ->From([ 1, 2, 3, 4, 5 ]);
$q2 = CSV::LINQ->From([ 3, 4, 5, 6, 7 ]);
my @inter  = $q1->Intersect($q2)->ToArray();
$q1 = CSV::LINQ->From([ 1, 2, 3, 4, 5 ]);
$q2 = CSV::LINQ->From([ 3, 4, 5, 6, 7 ]);
my @except = $q1->Except($q2)->ToArray();

print "  Union:     ", join(", ", @union),  "\n";
print "  Intersect: ", join(", ", @inter),  "\n";
print "  Except:    ", join(", ", @except), "\n";

print "\n=== Zip ===\n";
my @names  = ('Alice', 'Bob', 'Carol');
my @scores = (95, 87, 92);
my @zipped = CSV::LINQ->From([ @names ])->Zip(
    CSV::LINQ->From([ @scores ]),
    sub { { name => $_[0], score => $_[1] } }
)->OrderByNumDescending(sub { $_[0]{score} })->ToArray();

for my $r (@zipped) {
    printf "  %-8s %d\n", $r->{name}, $r->{score};
}

print "\n=== SelectMany (flatten tags) ===\n";
my @posts = (
    {title => 'Post A', tags => ['perl', 'csv']},
    {title => 'Post B', tags => ['perl', 'linq']},
    {title => 'Post C', tags => ['csv', 'data']},
);
my @all_tags = CSV::LINQ->From([ @posts ])
    ->SelectMany(sub { $_[0]{tags} })
    ->Distinct()
    ->OrderByStr(sub { $_[0] })
    ->ToArray();
print "  All tags: ", join(", ", @all_tags), "\n";
