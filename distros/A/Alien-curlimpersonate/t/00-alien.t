use v5.10; use strict; use warnings;
use Test::More;
use Test::Alien;
use DynaLoader ();
use Alien::curlimpersonate;

alien_ok 'Alien::curlimpersonate';

# cflags/libs metadata is present
my $cflags = Alien::curlimpersonate->cflags;
my $libs   = Alien::curlimpersonate->libs;
like $cflags, qr/-I\S+/, 'cflags has an include path';
like $libs,   qr/-lcurl-impersonate\b/, 'libs links curl-impersonate';

# An rpath here would break consumers at runtime rather than at build time.
unlike $libs, qr/-Wl,-rpath/, 'libs carries no rpath (the consumer adds it)';

# After relocation -- a different claim from the alienfile's build-time check.
my ($inc) = $cflags =~ /-I(\S+)/;
ok $inc && -f "$inc/curl/curl.h", 'the include path cflags names really holds curl/curl.h'
    or diag "cflags=$cflags";

# the built shared library exists ...
my @dl = Alien::curlimpersonate->dynamic_libs;
ok scalar(@dl), 'dynamic_libs lists the shared library'
    or diag 'nothing built -- the assertions below cannot mean anything';
my ($so) = grep { -e } @dl;
ok defined($so), 'shared library present on disk' . (defined $so ? " ($so)" : '');

# ... and exports the entry point. By full path, so the absent rpath cannot matter.
SKIP: {
    skip 'no shared library to load', 2 unless defined $so;
    my $lib = eval { DynaLoader::dl_load_file($so, 0) };
    ok $lib, 'shared library loads' or diag($@ || DynaLoader::dl_error());
    skip 'shared library failed to load', 1 unless $lib;
    my $sym = DynaLoader::dl_find_symbol($lib, 'curl_easy_impersonate');
    ok $sym, 'libcurl-impersonate exports curl_easy_impersonate';
}

done_testing;
