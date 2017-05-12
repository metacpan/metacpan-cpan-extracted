#!perl -T

use Test::More tests => 3;

BEGIN {
	use_ok( 'Acme::Grep2D' );
}

diag( "Testing Acme::Grep2D $Acme::Grep2D::VERSION, Perl $], $^X" );
my $text = <<'EOF';

   foobaraboof
raboof
EOF

my $g2d = Acme::Grep2D->new(text => $text);
my @m = $g2d->Grep('foobar');
my $found = 0;
my $correct = 0;
map {
    $correct++ if $_->[0] == 6;
} @m;
ok($correct == 3);

map {
   my ($length, $x, $y, $dx, $dy) = @$_;
   $found++ if $x==3 && $y==1;
   $found++ if $x==13 && $y==1;
   $found++ if $x==5 && $y==2;
} @m;
ok($found == 3);
