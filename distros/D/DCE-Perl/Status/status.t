
BEGIN {
foreach (qw(..  .  ../..)) {
    last if -e ($conf = "$_/config");
}
eval { require "$conf"; };
die $@ if $@;
}


use DCE::Status qw(&error_string);

tie $status => DCE::Status;

$msg = error_string(0);
print "$msg\n"; #should be null

$status = 387064044;
$status = 387064049;
print "$status\n" if $status;
printf "%d\n", $status;

