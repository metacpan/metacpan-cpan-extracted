use Test::More;

if (eval "use Devel::Size qw[total_size]; 1") {
  plan tests => 1;
} else {
  plan skip_all => "Devel::Size required for testing memory";
}

use ExtUtils::testlib;
use Crypt::GCrypt;

my $c = Crypt::GCrypt->new(
                           type => 'cipher',
                           algorithm => 'aes',
                           mode => 'cbc',
                           padding => 'null'
);
$c->start('encrypting');
$c->setkey("the key, the key");

my $fp = total_size($c);

my $e;
for (1..50) {
  print "$_\n";
  $e .= $c->encrypt('plain text' x 4);
}
$e .= $c->finish;

my $fp2 = total_size($c);
ok($fp == $fp2, 'constant memory allocation');
