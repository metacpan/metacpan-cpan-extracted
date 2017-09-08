use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::MediaHaven';
    use_ok $pkg;
}
require_ok $pkg;

my $url  = $ENV{MEDIAHAVEN_URL} || "";
my $user = $ENV{MEDIAHAVEN_USER} || "";
my $pwd  = $ENV{MEDIAHAVEN_PWD} || "";

SKIP: {
    skip "No Mediahaven server environment settings found (MEDIAHAVEN_URL,"
	 . "MEDIAHAVEN_USER,MEDIAHAVEN_PWD).",
	100 if (! $url || ! $user || ! $pwd);

    my $store = Catmandu->store('File::MediaHaven',url => $url, username => $user, password => $pwd);

    ok $store , 'got a MediaHaven handle';
}

done_testing;
