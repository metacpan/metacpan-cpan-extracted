use strict;
use warnings;
use MIME::Base64;
use Encode qw/decode encode/;
use Crypt::Mode::ECB;
use Crypt::CBC;
use Crypt::Cipher::DES;
my $m = Crypt::Mode::ECB->new('DES',1);
#my $c= $m->encrypt('landisgyr', 'c600land');
#my $d = encode_base64($c);
#my $bb = decode_base64($d);
#print $m->decrypt($bb,'c600land');
my $c= $m->encrypt('P@ssw0rd', 'c600land');
my $d = encode_base64($c);
print $d;
