use strict;
use Test::More;
use Carp;
use Data::Dumper;

use Data::Cube;

my @records;
my @header = split /\s+/, (<DATA>);
my %distincts;
while(<DATA>){
    chomp;
    my @data = split(/\s+/, $_);
    my %obj;
    foreach my $attr (@header) {
        if($attr !~ /^\s*$/){
            $obj{$attr} = shift @data;
            $distincts{$attr} = {} unless exists $distincts{$attr};
            $distincts{$attr}{$obj{$attr}} = 0 unless exists $distincts{$attr}{$obj{$attr}};
            $distincts{$attr}{$obj{$attr}}++;
        }else{
            shift @data;
        }
    }
    push @records, \%obj;
}

############################################################

# instance
sub instance_test {
    my $cube = new Data::Cube();
    is_deeply $cube->{dims}, [], "not set dimension";
    is_deeply $cube->{currentdims}, [], "not set current dimension";
    is scalar keys %{$cube->{measures}}, 1, "set default measure";


    $cube = new Data::Cube("Country", "Product");
    is_deeply $cube->{dims}, ["Country", "Product"], "set dimension";
    is_deeply $cube->{currentdims}, ["Country", "Product"], "set current dimension";

    my $subcube = $cube->clone();
    is_deeply $subcube->{dims}, ["Country", "Product"], "set dimension of cloned cube";
    is_deeply $subcube->{currentdims}, ["Country", "Product"], "set current dimension of cloned cube";
}
instance_test();

sub utils_test {
    my $cube = new Data::Cube();
    is $cube->is_same(1, 1), 1, "compare number 1, 1";
    is $cube->is_same(1, 3), 0, "compare number 1, 2";
    is $cube->is_same("hoge", "hoge"), 1, "compare number hoge, hoge";
    is $cube->is_same("hoge", "hogege"), 0, "compare number hoge, hogege";
    is $cube->is_same(1, "1"), 1, "compare 1, '1'";
    is $cube->is_same("1", 1), 1, "compare '1', 1";

    is $cube->recordFilter({x => 1}, {x => 1}), 1, "filter {x => 1}, {x => 1}";
    is $cube->recordFilter({x => 1}, {x => 2}), 0, "filter {x => 1}, {x => 2}";
    is $cube->recordFilter({x => "1"}, {x => 1}), 1, "filter {x => '1'}, {x => 1}";
    is $cube->recordFilter({x => [1, 3]}, {x => 1}), 1, "filter {x => [1, 3]}, {x => 1}";
    is $cube->recordFilter({x => sub {my $x = shift; $x > 0}}, {x => 1}), 1, "filter {x => [1, 3]}, {x => 1}";
}
utils_test();

sub dimension_test {
    my $cube = new Data::Cube("Country", "Product");
    $cube->add_dimension("SalesPerson");
    is_deeply $cube->{dims}, ["Country", "Product", "SalesPerson"], "add dimension";
    is_deeply $cube->{currentdims}, ["Country", "Product", "SalesPerson"], "add current dimension";

    $cube->remove_dimension("Product");
    is_deeply $cube->{dims}, ["Country", "SalesPerson"], "remove dimension";
    is_deeply $cube->{currentdims}, ["Country", "SalesPerson"], "remove current dimension";

    $cube->get_dimension();
    $cube->get_current_dimension();
    # $cube->reorder_dimension(["SalesPerson", "Country"]);
    # is_deeply $cube->{dims}, ["SalesPerson", "Country"];
    # is_deeply $cube->{currentdims}, ["SalesPerson", "Country"];
}
dimension_test();

sub put_test {
    my $cube = new Data::Cube("Country", "Product");
    is scalar @{$cube->{records}}, 0, "initial record number";
    $cube->put($records[0]);
    is scalar @{$cube->{records}}, 1, "record number after put";
    $cube->put($records[2], $records[3], $records[4]);
    is scalar @{$cube->{records}}, 4, "record number after bulk put";
    $cube->put([@records[5..8]]);
    is scalar @{$cube->{records}}, 8, "record number after array ref put";
}

put_test();

sub measure_test {
    my $cube = new Data::Cube("Country", "Product");
    $cube->add_measure("sum", sub {});
    ok exists $cube->{measures}{"sum"}, "add measure";
}
measure_test();

sub rollup_test {
    my $cube = new Data::Cube("Country", "Product");
    $cube->put([@records]);

    is_deeply $cube->get_dimension_component(), {}, "get_dimension_component with no args";
    is_deeply $cube->get_dimension_component("Country"), $distincts{"Country"}, "get_dimension_component with \"Country\"";
    is_deeply $cube->get_dimension_component("Product"), $distincts{"Product"}, "get_dimension_component with \"Product\"";
    my $results = $cube->rollup();
    for my $entry_first (@$results){
        ok exists $distincts{"Country"}->{$entry_first->{dim}}, "check first dimension";
        for my $entry_second (@{$entry_first->{values}}){
            ok exists $distincts{"Product"}->{$entry_second->{dim}}, "check second dimension";
            ok exists $entry_second->{count}, "has measure \"count\"";
        }
    }

    $cube->add_measure("sumUnits", sub { my $sum = 0; foreach my $d (@_){ $sum += $d->{Units}; } $sum; });

    $results = $cube->rollup();
    for my $entry_first (@$results){
        for my $entry_second (@{$entry_first->{values}}){
            ok exists $entry_second->{sumUnits}, "has measure \"sumUnits\"";
        }
    }

    $results = $cube->rollup(noValues => 1);
    for my $entry_first (@$results){
        for my $entry_second (@{$entry_first->{values}}){
            ok exists $entry_second->{sumUnits}, "has measure \"sumUnits\"";
            ok !exists $entry_second->{values}, "has no values";
        }
    }
}
rollup_test();

sub hierarchy_test {
    my $cube = new Data::Cube("Country", "Product");

    $cube->put([@records]);
    $cube->add_hierarchy("SalesPerson", "Country");

    is $cube->{hiers}{"Country"}, "SalesPerson", "add hierarchy";
    is $cube->{invHiers}{"SalesPerson"}, "Country", "add hierarchy";

    my $fromDateToMonth = sub {
        my $d = shift;
        if($d =~ /^(\d+)\/(\d+)\/(\d+)$/){
            my ($m, $d, $Y) = ($1, $2, $3);
            return "$Y/$m";
        }
        undef;
    };
    $cube->add_hierarchy("Date", "Month", $fromDateToMonth);

    is $cube->{hiers}{"Month"}, "Date", "add hierarchy";
    is $cube->{invHiers}{"Date"}, "Month", "add hierarchy";

    for my $record (@{$cube->{records}}){
        is $fromDateToMonth->($record->{Date}), $record->{Month}, "rollup new measure";
    }

    $cube->drilldown("Country");
    is_deeply $cube->{currentdims}, ["SalesPerson", "Product"];
    my $results = $cube->rollup();

    foreach my $result (@$results){
        ok exists $distincts{"SalesPerson"}{$result->{dim}}, "rolluped results";
    }

    $cube->drillup("Country");
    is_deeply $cube->{currentdims}, ["SalesPerson", "Product"];
    $results = $cube->rollup();

    foreach my $result (@$results){
        ok exists $distincts{"SalesPerson"}{$result->{dim}}, "rolluped results";
    }
}
hierarchy_test();

sub dice_test {
    my %UKPencilSalesPerson = ("Jardine" => 2, "Morgan" => 1);
    my $cube = new Data::Cube("Country", "Product");
    $cube->add_hierarchy("SalesPerson", "Country");
    $cube->put([@records]);

    my $subcube = $cube->dice(Country => "UK", Product => "Pencil");
    my $results = $subcube->drilldown("Country")->rollup();

    for my $result (@{$results}){
        ok exists $UKPencilSalesPerson{$result->{dim}}, "uk pencil";
    }
}
dice_test();

sub slice_test {
    my $cube = new Data::Cube("Country", "Product");
    $cube->add_hierarchy("SalesPerson", "Country");
    $cube->put([@records]);

    my $slice = $cube->slice("Country" => "US");
    ok $slice->{dim} eq "US", "slice test: dim matches sliceed dim";
}
slice_test();

done_testing;

__DATA__
    Date         Country   SalesPerson     Product     Units   Unit_Cost       Total
    3/15/2005         US       Sorvino      Pencil        56        2.99      167.44
    3/7/2006          US       Sorvino      Binder         7       19.99      139.93
    8/24/2006         US       Sorvino        Desk         3      275.00      825.00
    9/27/2006         US       Sorvino         Pen        76        1.99      151.24
    5/22/2005         US      Thompson      Pencil        32        1.99       63.68
    10/14/2006        US      Thompson      Binder        57       19.99     1139.43
    4/18/2005         US       Andrews      Pencil        75        1.99      149.25
    4/10/2006         US       Andrews      Pencil        66        1.99      131.34
    10/31/2006        US       Andrews      Pencil       114        1.29      147.06
    12/21/2006        US       Andrews      Binder        28        4.99      139.72
    2/26/2005         CA          Gill         Pen        51       19.99     1019.49
    1/15/2006         CA          Gill      Binder        46        8.99      413.54
    5/14/2006         CA          Gill      Pencil        94        1.29      121.26
    5/31/2006         CA          Gill      Binder       102        8.99      916.98
    9/10/2006         CA          Gill      Pencil        98        1.29      126.42
    2/9/2005          UK       Jardine      Pencil       125        4.99      623.75
    5/5/2005          UK       Jardine      Pencil        90        4.99      449.10
    3/24/2006         UK       Jardine      PenSet        76        4.99      379.24
    11/17/2006        UK       Jardine      Binder        39        4.99      194.61
    12/4/2006         UK       Jardine      Binder        94       19.99     1879.06
    1/23/2005         US        Kivell      Binder        50       19.99      999.50
    11/25/2005        US        Kivell      PenSet        96        4.99      479.04
    6/17/2006         US        Kivell        Desk         5      125.00      625.00
    8/7/2006          US        Kivell      PenSet        42       23.95     1005.90
    6/25/2005         UK        Morgan      Pencil        90        4.99      449.10
    10/5/2005         UK        Morgan      Binder        28        8.99      251.72
    7/21/2006         UK        Morgan      PenSet        55       12.49      686.95
    9/1/2005          US         Smith        Desk         2      125.00      250.00
    12/12/2005        US         Smith      Pencil        67        1.29       86.43
    2/1/2006          US         Smith      Binder        87       15.00     1305.00
    7/12/2005         US        Howard      Binder        29        1.99       57.71
    4/27/2006         US        Howard         Pen        96        4.99      479.04
    1/6/2005          CA         Jones      Pencil        95        1.99      189.05
    4/1/2005          CA         Jones      Binder        76        4.99      379.24
    6/8/2005          CA         Jones      Binder        60        8.99      539.40
    8/15/2005         US         Jones      Pencil        35        4.99      174.65
    9/18/2005         US         Jones      PenSet        16       15.99      255.84
    10/22/2005        US         Jones         Pen        64        8.99      575.36
    2/18/2006         CA         Jones      Binder         4        4.99       19.96
    7/4/2006          CA         Jones      PenSet        61        4.99      304.39
    7/29/2005         UK         Hogan      Binder        81       19.99     1619.19
    11/8/2005         UK         Hogan         Pen        12       19.99      239.88
    12/29/2005        UK         Hogan      PenSet        74       15.99     1183.26
