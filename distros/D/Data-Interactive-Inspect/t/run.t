# -*-perl-*-

use Test::More tests => 10;
#use Test::More qw(no_plan);

require_ok( 'Data::Interactive::Inspect' );

my $cfg = {
            'v27' => '10',
            'v28' => 'ten',

            'AoA' => [ 1, 2, 3, 4 ],

            'AoH' => {
		      'Homer' => { user => 'homer', uid => 100 },
		      'Bart'  =>  { user => 'bart',  uid => 101 },
		      'Lisa'  => { user => 'lisa',  uid => 102 },
            },
           };

my $shell = new_ok('Data::Interactive::Inspect', [ $cfg ]);
ok($shell, "Data::Interactive::Inspect->new() returns an obj");

my $orig;
foreach my $k (keys %{$cfg}) {
  $orig->{$k} = $cfg->{$k};
}


my $m1 = $shell->inspect("set v27 888\n");
isnt($orig->{v27}, $m1->{v27}, "hash modified");

my $m2 = $shell->inspect("set GY { nom => 400 }");
is_deeply($m2->{GY}, { nom => 400 }, "add a sub hash");

my $m3 = $shell->inspect("pop AoA");
is_deeply($m3->{AoA}, [1,2,3], "remove last element of array");

my $m4 = $shell->inspect("shift AoA");
is_deeply($m4->{AoA}, [2,3], "remove 1st element of arry");

my $m5 = $shell->inspect("append AoA 9");
is_deeply($m5->{AoA}, [2,3,9], "append to array");

my $m6 = $shell->inspect("drop v28");
isnt($orig->{v28}, $m6->{v28}, "delete a key");

my $m7 = $shell->inspect("enter AoH\nenter Bart\nset uid 0\n");
is_deeply($m7->{AoH}->{Bart}, { user => 'bart',  uid => 0 }, "browse and modify deeply");

done_testing();
