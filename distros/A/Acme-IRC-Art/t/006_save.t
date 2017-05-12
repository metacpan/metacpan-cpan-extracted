# -*- perl -*-

use Test::More tests => 2;
use Acme::IRC::Art;

my $art = Acme::IRC::Art->new(5, 5);

$art->rectangle(0, 0, 4, 4, 5);
$art->save("t_test.aia");
open FILE, "t_test.aia" or die $!;
my @tab = <FILE>;
my @tab2;
push @tab2, chomp $_ for @tab;
is_deeply([@tab], [$art->result]);
is_deeply([@tab], [("\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5,"\0035,5 \003"x5)]);
qx(rm t_test.aia);
