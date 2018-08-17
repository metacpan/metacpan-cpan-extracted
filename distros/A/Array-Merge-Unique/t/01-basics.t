use Test::More;

use Array::Merge::Unique qw/unique_array/;

my $arrayref = unique_array([qw/one two three/], qw/one two/);
my @array = unique_array([qw/one two three/], qw/one two/);
my $hash = { hash => 'okay' };
my @aoaoa = unique_array([qw/one two three/, $hash], [qw/one/, $hash, [qw/two/, [qw/three/]]]); 

my $testing = [qw/one two three/];
is_deeply($arrayref, $testing, "yep one, two, three");
is_deeply(\@array, $testing, "yes one, two, three");
is_deeply(\@aoaoa, [@{$testing}, { hash => 'okay'}], "yes one, two, three");

done_testing();
