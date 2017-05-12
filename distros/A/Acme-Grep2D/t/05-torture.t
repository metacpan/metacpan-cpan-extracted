#!perl -T

use Test::More tests => 12;
use Data::Dumper;

BEGIN {
	use_ok( 'Acme::Grep2D' );
}

diag( "Testing Acme::Grep2D $Acme::Grep2D::VERSION, Perl $], $^X" );
my $text = <<'EOF';
finderkb
      e     n
     ee  x  i     1
    n p f   j    .
      eu    o   2
      r     k
       arbezebra   r
    happy   e     e
         p   b   n
          p   r n
           a   a
        yppah b
EOF

my $g2d = Acme::Grep2D->new(text => $text);
my @m = $g2d->Grep(qr(f\w+));
print STDERR $text;
print STDERR Dumper(\@m);
map {
   my ($length, $x, $y, $dx, $dy, $ref) = @$_;
   print STDERR $$ref, "\n";
} @m;
my $found = 0;

map {
   my ($length, $x, $y, $dx, $dy, $ref) = @$_;
   $found++ if $length==8 && $x==0 && $y==0 && $dx==1 && $dy==0;
   $found++ if $length==3 && $x==8 && $y==3 && $dx==-1 && $dy==1;
   $found++ if $length==2 && $x==8 && $y==3 && $dx==1 && $dy==-1;
} @m;
ok($found == 3);

my $perfect = 0;
map {
    $perfect++ if $g2d->extract($_) eq 'finderkb';
    $perfect++ if $g2d->extract($_) eq 'fur';
    $perfect++ if $g2d->extract($_) eq 'fx';
} @m;
ok($perfect == 3);


@m = $g2d->Grep(qr(keep\w+));
#print STDERR scalar(@m), "\n";
ok(@m == 1);
ok($g2d->extract($m[0]) eq 'keeper');

@m = $g2d->Grep(qr(j\w+));
$perfect = 0;
map {
    $perfect++ if $g2d->extract($_) eq 'jin';
    $perfect++ if $g2d->extract($_) eq 'jokee';
} @m;
ok($perfect == 2);

@m = $g2d->Grep(qr(\d\.\d));
ok(@m == 2);
$perfect = 0;
map {
    $perfect++ if $g2d->extract($_) eq '1.2';
    $perfect++ if $g2d->extract($_) eq '2.1';
} @m;
ok($perfect == 2);

@m = $g2d->Grep(qr(happy));
ok(@m == 3);
#print STDERR Dumper(\@m);
$perfect = 0;
map {
    $perfect++ if $g2d->extract($_) eq 'happy';
} @m;
ok($perfect == 3);

@m = $g2d->Grep(qr(zebra));
ok(@m == 3);
$perfect = 0;
map {
    $perfect++ if $g2d->extract($_) eq 'zebra';
} @m;
ok($perfect == 3);

