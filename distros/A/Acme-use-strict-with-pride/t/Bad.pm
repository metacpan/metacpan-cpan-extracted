package Bad;
BEGIN {$::loaded{+__PACKAGE__}++;}
my ($a);

# It's true, but it's undefined. And it's line 5
$a = 5 + $a;
