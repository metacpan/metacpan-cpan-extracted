# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use Data::Fax;
my $class = 'Data::Fax';
my $df = Data::Fax->new; 
isa_ok($df, "Data::Fax");

diag("Test scalar parameter methods...");
my @md1 = (    # '$' - scalar parameter
    qw(ifs IFS ofs OFS sfr SFR debug init_file reset DirSep dfdb_fn sn)
);
my %df1 = (    # default values for '$' type parameters 
    ifs=>'|', IFS=>'|', ofs=>'|', OFS=>'|', sfr=>0, SFR=>0,
    debug=>0, init_file=>'', reset=>'Y', DirSep=>'/', 
    sn=>'0'
);
my ($d, $n, $v, @a);
foreach my $m (@md1) { 
    if (exists $df1{$m}) { $d = $df1{$m}; 
    } else { $d = $df->$m; }
    is($df->$m, $d, "$class->$m");         # check default
    if ($d =~ /^[\d\.]+$/) { $v = 1; 
    } else { $v = 'xxx'; }
    $n = "set_$m"; 
    ok($df->$n($v),"$class->$n($v)");      # assign new value
    $n = "get_$m"; 
    is($df->$n, $v, "$class->$n=$v");      # check new value
    @a = ($m, "set_$m", "get_$m");
    can_ok($class, @a);
    $df->$m($d);                           # set back to default
}

1;

