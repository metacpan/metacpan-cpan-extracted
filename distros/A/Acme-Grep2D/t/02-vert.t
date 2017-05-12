#!perl -T

use Test::More tests => 3;
use Data::Dumper;

BEGIN {
	use_ok( 'Acme::Grep2D' );
}

diag( "Testing Acme::Grep2D $Acme::Grep2D::VERSION, Perl $], $^X" );
my $text = <<'EOF';

f
o r
o a
b b
a o
r o
  f


EOF

my $g2d = Acme::Grep2D->new(text => $text);
my @m = $g2d->Grep('foobar');
print STDERR $text;
#print STDERR Dumper(\@m);
my $found = 0;
my $correct = 0;
map {
    $correct++ if $_->[0] == 6;
} @m;
ok($correct == 2);

map {
   my ($length, $x, $y, $dx, $dy) = @$_;
   $found++ if $x==0 && $y==1 && $dy==1;
   $found++ if $x==2 && $y==7 && $dy==-1;
} @m;
ok($found == 2);
