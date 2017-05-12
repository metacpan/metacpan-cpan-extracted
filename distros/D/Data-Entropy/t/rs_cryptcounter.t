use warnings;
use strict;

use Test::More tests => 58;

use Crypt::Rijndael;

BEGIN { use_ok "Data::Entropy::RawSource::CryptCounter"; }

use constant SEEK_SET => 0;
use constant SEEK_CUR => 1;
use constant SEEK_END => 2;

my $ctr = Data::Entropy::RawSource::CryptCounter
		->new(Crypt::Rijndael->new("\0" x 32));
ok $ctr;

my $d;
is $ctr->tell, 0;
is $ctr->getc, "\xdc";
is $ctr->getc, "\x95";
$ctr->ungetc(3);
is $ctr->getc, "\x95";
is $ctr->read($d, 14), 14;
is $d, "\xc0\x78\xa2\x40\x89\x89\xad\x48\xa2\x14\x92\x84\x20\x87";
is $ctr->getc, "\x52";
is $ctr->tell, 17;
is $ctr->seek(5, SEEK_CUR), 1;
is $ctr->getc, "\xb8";
is $ctr->seek(17, SEEK_CUR), 1;
is $ctr->read($d, 14), 14;
is $d, "\x8d\x60\x9d\x55\x1a\x5c\xc9\x8e\x39\xd6\xe9\xae\x76\xa9";
is $ctr->seek(-16, SEEK_CUR), 1;
is $ctr->read($d, 3), 3;
is $d, "\xb6\x3d\x8d";
is $ctr->tell, 41;
is $ctr->getc, "\x60";
my $pos = $ctr->getpos;
is $ctr->seek(207, SEEK_SET), 1;
is $ctr->getc, "\xd2";
is $ctr->getc, "\x0f";
is $ctr->setpos($pos), "0 but true";
is $ctr->tell, 42;
is $ctr->getc, "\x9d";
is $ctr->seek(-3, SEEK_SET), 0;
is $ctr->tell, 43;
is $ctr->seek(-300, SEEK_CUR), 0;
is $ctr->tell, 43;
is $ctr->seek(-3, SEEK_END), 0;
is $ctr->tell, 43;
is $ctr->sysseek(-3, SEEK_CUR), 40;
is $ctr->tell, 40;
is $ctr->sysseek(3, SEEK_SET), 3;
is $ctr->tell, 3;
is $ctr->sysseek(-4, SEEK_CUR), undef;
is $ctr->tell, 3;
is $ctr->sysseek(-3, SEEK_CUR), "0 but true";
is $ctr->tell, 0;
is $ctr->sysseek(0, SEEK_SET), "0 but true";
is $ctr->tell, 0;
is $ctr->sysread($d, 16), 16;
is $d, "\xdc\x95\xc0\x78\xa2\x40\x89\x89\xad\x48\xa2\x14\x92\x84\x20\x87";
is $ctr->read($d, 6, 2), 6;
is $d, "\xdc\x95\x52\x75\xf3\xd8\x6b\x4f";
is $ctr->tell, 22;
is $ctr->read($d, 3, -2), 3;
is $d, "\xdc\x95\x52\x75\xf3\xd8\xb8\x68\x45";
is $ctr->read($d, 3, 11), 3;
is $d, "\xdc\x95\x52\x75\xf3\xd8\xb8\x68\x45\x00\x00\x93\x13\x3e";
ok $ctr->close;
is $ctr->getc, "\xbf";
ok !$ctr->error;
is $ctr->clearerr, 0;
ok $ctr->opened;
ok !$ctr->eof;
is $ctr->getc, "\xa5";

1;
