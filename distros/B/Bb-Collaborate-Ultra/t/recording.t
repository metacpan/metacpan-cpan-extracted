use warnings; use strict;
use Test::More tests => 6;
use Test::Fatal;
use Date::Parse;
use lib '.';
use t::Ultra;
use Bb::Collaborate::Ultra::Recording;

SKIP: {
    my %t = t::Ultra->test_connection;
    my $connection = $t{connection};
    skip $t{skip} || 'skipping live tests', 6
	unless $connection;

    $connection->connect;
    my @recordings;
    is exception {
	@recordings = Bb::Collaborate::Ultra::Recording->get($connection, {
	    limit => 5,
	    startTime => time() - 31 * 60 * 60 * 24,
	  });
    }, undef, 'get recordings - lives';

    skip "no recordings found", 5
        unless @recordings;
    ok scalar @recordings <= 5 && scalar @recordings > 0, 'get sessions - with limits';

    my $recording = $recordings[0];
    isa_ok $recording, 'Bb::Collaborate::Ultra::Recording';
    ok $recording->sessionStartTime, 'got startTime';

    my $url;
    is exception { $url = $recording->url }, undef, '$recording->url - lives';
    ok $url && (!ref $url), 'got url';
    

}
