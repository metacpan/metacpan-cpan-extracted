use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require threads };
    plan skip_all => "threads not available" if $@;
}

plan tests => 2;
use_ok('Crypt::OpenSSL::AES');

my $key = pack("H*", "0" x 64);

# Create object in main thread
my $cipher = Crypt::OpenSSL::AES->new($key, { cipher => 'AES-256-ECB' });

# CLONE_SKIP prevents the object being cloned into the child thread
my $thread = threads->create(sub {
    return $cipher;
});
my $result = $thread->join();
ok(ref($result) && !defined($$result) && !ref($$result),
   "Object is not cloned into child thread (CLONE_SKIP)");

