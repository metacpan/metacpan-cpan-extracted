use warnings;
use strict;
use Test::More;
use FindBin '$Bin';
BEGIN { use_ok('Data::MATFile') };
use Data::MATFile 'read_matfile';
my $file = "$Bin/dataset1.mat";
my $obj = read_matfile ($file);
ok ($obj);
ok ($obj->{data}, "got data");
my $d = $obj->{data};
ok ($d->{pos_examples_nobias}, "got right data");
my $p = $d->{pos_examples_nobias};
is_deeply ($p->{dimensions}, [4, 2], "array has right dimensions");
my $eps = 0.00001;
ok (abs ($p->{array}->[0][0] - 0.871428571428571) < $eps, "element 0, 0 ok");
ok (abs ($p->{array}->[3][1] - -0.8704318936877078) < $eps, "element 3, 1 ok");
done_testing ();
# Local variables:
# mode: perl
# End:
