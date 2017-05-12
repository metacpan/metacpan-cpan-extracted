BEGIN { $^W= 1; }
use Test qw( plan );

my $ok;
sub ok($;$$) {
    for(  &Test::ok(@_)  ) {
        $ok= 0
            if  ! $_;
        return $_;
    }
}
END {
    print STDERR "# ( ", join " ", @Acme::ESP::Scanner::fail, ")\n"
        if  @Acme::ESP::Scanner::fail;
    if(  defined $ok  &&  1 != $ok  ) {
        print STDERR "# fmt = '$Acme::ESP::Scanner::fmt'\n"
            if  defined $Acme::ESP::Scanner::fmt;
    }
    ok( $ok )
        if  defined $ok;
}

if(  5.009 <= $]  &&  $] < 5.009_005  ) {
    print "1..0 # Skip This Perl experiment is dead. Long live 5.9.5+!\n";
    exit( 0 );
}
$^W= 0;
my $mind= 'blank'; my $head= \$mind; $mind= pack "L", $head;
if(  ! unpack "L", $mind  ) {
    print "1..0 # Skip Since this Perl can't pack a reference!\n";
    exit( 0 );
}
$^W= 1;
plan(
    tests => 15,
    todo => [ ],
);
$Test::TestLevel= 1;
$ok= -1;

if(  ! eval { require Acme::ESP; 1 }  ) {
    warn $@, $/;
    exit( 1 );
}
ok(1);
Acme::ESP->import();
ok(1);

local $/;
eval join '', "\n#line ", 3+__LINE__, '"', __FILE__, qq("\n), <DATA>, "; 1"
    or  die $@;
__END__

$i= "person";
1 for $i.oO("I exist");
$Rene{descartes}++ if $i . o O ( );
ok( exists $Rene{descartes} );

ok(  $i .oO ( "Did I leave the oven on?" ), "I exist" );
ok(( $i . o O { } ), '/leave/' );
ok(( $i . o O [ ] ), '/oven/' );
ok(( $i . o O [ 1,2 ] ), '/on/' );
ok(( $i.oO{ 4..9 } ), '1; 2' );
ok(( $i.oO[ '' ] ), '/^8.*\.  6:/' );
ok(( $i . o O < oh wow > ), '' );
ok(( $i.oO< > ), 'oh ... wow' );
ok(  $i.oO( '' ), '' );
$i= 1;
ok( ! eval { 0 for $i..oO('Independent thought is fatal'); 1 } );
ok( ! eval { 0 for $i,oO('meta thought').oO("I don't like"); 1 } );
$ok &&= 1;
