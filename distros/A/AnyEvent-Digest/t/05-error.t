use Test::More tests => 7;
use Test::Exception;
use Symbol;

use_ok 'AnyEvent::Digest';

my $our;

throws_ok { $our = AnyEvent::Digest->new('Digest::NotExistOnEarth') }
    qr/^AnyEvent::Digest: Unknown base digest module `Digest::NotExistOnEarth' is specified/, 'unknown base';
throws_ok { $our = AnyEvent::Digest->new('Digest::MD5', backend => '') }
    qr/^AnyEvent::Digest: Unknown backend `' is specified/, 'unknown backend';
lives_ok  { $our = AnyEvent::Digest->new('Digest::MD5') } 'construction for idle';

throws_ok { $our->notfound() }
    qr/^AnyEvent::Digest: Unknown method `notfound' is called for `Digest::MD5'/, 'unknown method';

my $fh = gensym;
throws_ok { $our->addfile_async($fh)->recv; } qr/^AnyEvent::Digest: Read error occurs/, "can't read by idle";
throws_ok { $our->addfile_async('NotExistOnEarth')->recv; } qr/^AnyEvent::Digest: Open error occurs for `NotExistOnEarth'/, "can't open";

# aio_read checks filehandle validity, so it is not easy to check read error.
#lives_ok  { $our = AnyEvent::Digest->new('Digest::MD5', backend => 'aio') } 'construction for aio';
#throws_ok { $our->addfile_async($fh)->recv; } qr/^AnyEvent::Digest: Read error occurs/, "can't read by aio";
