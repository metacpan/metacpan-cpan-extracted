use 5.10.1;
use strict;
use warnings;

use Test::More tests=>5;

BEGIN { use_ok( 'Crypt::NSS::X509' ); }

my $pem = slurp("certs/rapidssl.crt");
my $cert = Crypt::NSS::X509::Certificate->new_from_pem($pem);

isa_ok($cert, 'Crypt::NSS::X509::Certificate');
ok($cert->match_name('www.rapidssl.com'));
ok($cert->match_name('rapidssl.com')); # in alternative name
ok(!$cert->match_name('google.com')); 

sub slurp {
  local $/=undef;
  open (my $file, shift) or die "Couldn't open file: $!";
  my $string = <$file>;
  close $file;
  return $string;
}
