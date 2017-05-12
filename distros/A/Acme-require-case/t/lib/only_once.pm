package only_once;

our $count;
$count++;

die if $count > 1;

1;
