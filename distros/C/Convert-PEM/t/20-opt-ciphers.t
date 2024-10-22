use strict;
use Test::More;
use Test::Exception;
use Convert::PEM;

plan tests => 18;

my $expected = join ':', sort qw(DES-CBC DES-EDE3-CBC AES-128-CBC AES-192-CBC AES-256-CBC CAMELLIA-128-CBC CAMELLIA-192-CBC CAMELLIA-256-CBC IDEA-CBC SEED-CBC);
my @ciphers;
my $ciphers;

# object oriented
ok (Convert::PEM->has_cipher('idea') eq 'IDEA-CBC', "IDEA-CBC cipher recognized via OO interface");
ok (Convert::PEM->has_cipher('aes') eq 'AES-128-CBC', "AES-128-CBC cipher recognized via OO interface");
ok (Convert::PEM->has_cipher('aes128') eq 'AES-128-CBC', "AES-128-CBC cipher recognized via OO interface");
ok (Convert::PEM->has_cipher('aes192') eq 'AES-192-CBC', "AES-192-CBC cipher recognized via OO interface");
ok (Convert::PEM->has_cipher('aes256') eq 'AES-256-CBC', "AES-256-CBC cipher recognized via OO interface");
ok (Convert::PEM->has_cipher('des') eq 'DES-CBC', "DES-CBC cipher recognized via OO interface");
ok (Convert::PEM->has_cipher('3des') eq 'DES-EDE3-CBC',"DES-EDE3-CBC cipher recognized via OO interface");


lives_ok { @ciphers = Convert::PEM->list_ciphers } "retrieve list of supported ciphers as array";
ok @ciphers >= 1, "list of ciphers contains one or more items";

lives_ok { $ciphers = Convert::PEM->list_ciphers } "retrieve list of supported ciphers as scalar";
ok $ciphers eq $expected, "list of ciphers contains items";
note("ciphers: $ciphers");
note("retrieved ciphers:".$/."  ".join("$/  ",@ciphers));

# directly access functions
ok (Convert::PEM::has_cipher('idea') eq 'IDEA-CBC', "IDEA-CBC cipher recognized via functional interface");
ok (Convert::PEM::has_cipher('aes') eq 'AES-128-CBC', "AES-128-CBC cipher recognized via functional interface");
ok (Convert::PEM::has_cipher('aes128') eq 'AES-128-CBC', "AES-128-CBC cipher recognized via functional interface");
ok (Convert::PEM::has_cipher('aes192') eq 'AES-192-CBC', "AES-192-CBC cipher recognized via functional interface");
ok (Convert::PEM::has_cipher('aes256') eq 'AES-256-CBC', "AES-256-CBC cipher recognized via functional interface");
ok (Convert::PEM::has_cipher('des') eq 'DES-CBC', "DES-CBC cipher recognized via functional interface");
ok (Convert::PEM::has_cipher('3des') eq 'DES-EDE3-CBC', "DES-EDE3-CBC cipher recognized via functional interface");
