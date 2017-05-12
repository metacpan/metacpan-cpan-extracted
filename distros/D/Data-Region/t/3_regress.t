use Test::More tests => 37;
BEGIN { use_ok('Data::Region') };

#########################

# bounds_test implicitly tests coords()
sub bounds_test {
  my $rgn = shift;
  my @c = @_;
  my @rc = $rgn->coords();
  foreach my $i (0..3) {
    return undef unless $c[$i]==$rc[$i];
  }
  return 1;
}

sub pair_test {
  my($ax,$ay, $bx,$by) = @_;
  return (($ax==$bx) && ($ay==$by));
}

my $testdata = {foo=>bar};

my($r, $x);

# new
$r = Data::Region->new(100,100);
ok( bounds_test($r, 0,0,100,100) ); #2

# new+data
$r = Data::Region->new(100,100, {data=>$testdata});
ok( bounds_test($r, 0,0,100,100) ); #3
ok( $r->data()->{foo} eq 'bar' ); #4

my($a,$b);

# area()
$r = Data::Region->new(100,100);
$a = $r->area(25,25, 75,75);
$b = $a->area(10,10, 20,20);
ok( bounds_test($a, 25,25,75,75) ); #5
ok( bounds_test($b, 35,35,45,45) ); #6
$a = $r->area(25,25, -25,-25);
$b = $a->area(10,10, -30,-30);
ok( bounds_test($a, 25,25,75,75) ); #7
ok( bounds_test($b, 35,35,45,45) ); #8

my @aa;

# subdivide
$r = Data::Region->new(100,100);
@aa = $r->subdivide( 10, 10 );
ok( @aa == 100 ); #9
ok( bounds_test( $aa[10], 0,10, 10,20 ) ); #10
ok( bounds_test( $aa[99], 90,90, 100,100) ); #11

# split_vertical
$r = Data::Region->new(100,100);
@aa = $r->split_vertical( 2, 5, 1 );
ok( @aa == 4 ); #12
ok( bounds_test( $aa[0], 0,0, 100,2 ) ); #13
ok( bounds_test( $aa[3], 0,8, 100,100) ); #14

# split_horizontal
$r = Data::Region->new(100,100);
@aa = $r->split_horizontal( 2, 5, 1 );
ok( @aa == 4 ); #15
ok( bounds_test( $aa[0], 0,0, 2,100 ) ); #15
ok( bounds_test( $aa[3], 8,0, 100,100) ); #17

# split_vertical_abs
$r = Data::Region->new(100,100);
@aa = $r->split_vertical_abs( 2, 5, 15 );
ok( @aa == 3 ); #18
ok( bounds_test( $aa[0], 0,2, 100,5 ) ); #19
ok( bounds_test( $aa[1], 0,5, 100,15 ) ); #20
ok( bounds_test( $aa[2], 0,15, 100,100 ) ); #21

# split_horizontal_abs
$r = Data::Region->new(100,100);
@aa = $r->split_horizontal_abs( 2, 5, 15 );
ok( @aa == 3 ); #22
ok( bounds_test( $aa[0], 2,0, 5,100 ) ); #23
ok( bounds_test( $aa[1], 5,0, 15,100 ) ); #24
ok( bounds_test( $aa[2], 15,0, 100,100 ) ); #25

# query methods
$r = Data::Region->new(100,100);
$a = $r->area( 1,2, -3,-4 );
ok( bounds_test( $a, 1,2, 97,96 ) ); #26
ok( $a->width() == 96 ); #27
ok( $a->height() == 94 ); #28
ok( pair_test( $a->top_left(), 1,2 ) ); #29
ok( pair_test( $a->top_right(), 97,2 ) ); #30
ok( pair_test( $a->bottom_right(), 97,96 ) ); #31
ok( pair_test( $a->bottom_left(), 1,96 ) ); #32

# data
my $d1 = { foo => 'bar' };
my $d2 = { foo => 'gleh' };
$r = Data::Region->new(100,100, {data=>$d1} );
$a = $r->area(15,15, -15,-15);
$a->data($d2);
$b = $a->area(10,10, -10,-10);
ok( $b->data()->{foo} eq 'gleh' ); # 33

# actions
my $count = 0;
$r->action( sub { $count++; $_[0]->data()->{r} = 1; } );
$a->action( sub { $count++; $_[0]->data()->{a} = 1; } );
$b->action( sub { $count++; $_[0]->data()->{b} = 1; } );
$r->render();
ok( $count == 3 ); #34
ok( $d1->{r} ); #35
ok( $d2->{a} ); #36
ok( $d2->{b} ); #37

