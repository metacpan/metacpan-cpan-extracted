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

# Demonstrates: FromCSV, Where, Select, OrderByNumDescending,
#               Distinct, GroupBy, Sum, ToArray, ToCSV

# Create sample CSV in memory for demo
my $tmpcsv = "/tmp/eg01_sales_$$.csv";
open(FH, ">$tmpcsv") or die "Cannot open: $!";
print FH "name,amount,category,city\n";
print FH "Alice,1500,Electronics,Tokyo\n";
print FH "Bob,800,Books,Osaka\n";
print FH "Carol,2000,Electronics,Tokyo\n";
print FH "Dave,300,Books,Nagoya\n";
print FH "Eve,1200,Electronics,Osaka\n";
print FH "Frank,600,Books,Tokyo\n";
close(FH);

print "=== High-value Electronics sales ===\n";
my @high = CSV::LINQ->FromCSV($tmpcsv)
    ->Where(category => 'Electronics')
    ->Where(sub { $_[0]{amount} >= 1200 })
    ->OrderByNumDescending(sub { $_[0]{amount} })
    ->ToArray();

for my $r (@high) {
    printf "  %-10s %5d  %s\n", $r->{name}, $r->{amount}, $r->{city};
}

print "\n=== Sales by category ===\n";
my @by_cat = CSV::LINQ->FromCSV($tmpcsv)
    ->GroupBy(sub { $_[0]{category} })
    ->Select(sub {
        my $g = shift;
        return {
            Category => $g->{Key},
            Count    => scalar(@{$g->{Elements}}),
            Total    => CSV::LINQ->From($g->{Elements})
                            ->Sum(sub { $_[0]{amount} }),
        };
    })
    ->OrderByNumDescending(sub { $_[0]{Total} })
    ->ToArray();

for my $r (@by_cat) {
    printf "  %-15s  count=%d  total=%d\n",
        $r->{Category}, $r->{Count}, $r->{Total};
}

print "\n=== Cities (distinct) ===\n";
my @cities = CSV::LINQ->FromCSV($tmpcsv)
    ->Select(sub { $_[0]{city} })
    ->Distinct()
    ->OrderByStr(sub { $_[0] })
    ->ToArray();

print "  ", join(", ", @cities), "\n";

print "\n=== Write filtered CSV ===\n";
my $outcsv = "/tmp/eg01_out_$$.csv";
CSV::LINQ->FromCSV($tmpcsv)
    ->Where(city => 'Tokyo')
    ->ToCSV($outcsv);

open(FH, $outcsv) or die;
while (<FH>) { print "  $_" }
close(FH);

unlink $tmpcsv;
unlink $outcsv;
