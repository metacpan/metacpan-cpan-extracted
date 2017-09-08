use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::MediaHaven::Searcher';
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

}

done_testing;
