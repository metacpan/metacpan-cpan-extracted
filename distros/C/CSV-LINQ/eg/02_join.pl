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

# Demonstrates: FromCSV, Join, GroupJoin, ToArray, OrderByNumDescending

my $orders_csv    = "/tmp/eg02_orders_$$.csv";
my $customers_csv = "/tmp/eg02_customers_$$.csv";

open(FH, ">$orders_csv") or die;
print FH "id,customer_id,amount,product\n";
print FH "1,C01,1500,Widget\n";
print FH "2,C02,800,Gadget\n";
print FH "3,C01,2000,Widget\n";
print FH "4,C03,300,Doohickey\n";
print FH "5,C02,1200,Widget\n";
close(FH);

open(FH, ">$customers_csv") or die;
print FH "id,name,city\n";
print FH "C01,Alice,Tokyo\n";
print FH "C02,Bob,Osaka\n";
print FH "C03,Carol,Nagoya\n";
close(FH);

print "=== Orders with customer name (inner join) ===\n";
my @joined = CSV::LINQ->FromCSV($orders_csv)->Join(
    CSV::LINQ->FromCSV($customers_csv),
    sub { $_[0]{customer_id} },
    sub { $_[0]{id} },
    sub {
        {
            order_id => $_[0]{id},
            name     => $_[1]{name},
            city     => $_[1]{city},
            amount   => $_[0]{amount},
            product  => $_[0]{product},
        }
    }
)->OrderByNumDescending(sub { $_[0]{amount} })->ToArray();

for my $r (@joined) {
    printf "  Order#%s  %-8s  %-8s  %5d  %s\n",
        $r->{order_id}, $r->{name}, $r->{city},
        $r->{amount}, $r->{product};
}

print "\n=== Total per customer (group join) ===\n";
my @totals = CSV::LINQ->FromCSV($customers_csv)->GroupJoin(
    CSV::LINQ->FromCSV($orders_csv),
    sub { $_[0]{id} },
    sub { $_[0]{customer_id} },
    sub {
        my($cust, $ord_q) = @_;
        my @orders = $ord_q->ToArray();
        my $total  = CSV::LINQ->From([ @orders ])
                        ->Sum(sub { $_[0]{amount} });
        return {
            name   => $cust->{name},
            count  => scalar(@orders),
            total  => $total,
        };
    }
)->OrderByNumDescending(sub { $_[0]{total} })->ToArray();

for my $r (@totals) {
    printf "  %-8s  orders=%d  total=%d\n",
        $r->{name}, $r->{count}, $r->{total};
}

unlink $orders_csv;
unlink $customers_csv;
