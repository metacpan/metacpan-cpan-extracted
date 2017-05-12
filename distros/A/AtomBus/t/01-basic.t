use Test::More import => ['!pass'], tests => 12;
use Dancer qw(:syntax);
use Dancer::Test;

use Dancer::Plugin::DBIC qw(schema);
use Capture::Tiny qw(capture);

BEGIN {
    set atombus => {
        db => {
            dsn => 'dbi:SQLite:dbname=:memory:',
        }
    };
}

use AtomBus;

my $xml1 = q{
    <entry>
        <title>title111</title>
        <content type="xhtml">
            <div xmlns="http://www.w3.org/1999/xhtml">content111</div>
        </content>
    </entry>
};

(my $xml2 = $xml1) =~ s/111/222/g;
my $feed = 'foo';

# Confirm that feed doesn't exist yet.
capture { # Silence output from schema->deploy in before filter.
    response_status_is [ GET => "/feeds/$feed" ], 404;
};

my $res = dancer_response POST => "/feeds/$feed", { body => $xml1 };
is $res->{status} => 201, 'Got 201 for posting entry1.';

is schema->resultset('AtomBusEntry')->count() => 1, '1 entries in db.';
is schema->resultset('AtomBusFeed')->count() => 1, '1 feed in db.';

my ($entry1) = schema->resultset('AtomBusEntry')->search(
    { title => 'title111', content => 'content111', feed_title => $feed });
ok $entry1, 'Found entry 1.';

$res = dancer_response POST => "/feeds/$feed", { body => $xml2 };
is $res->{status} => 201, 'Got 201 for posting entry2.';

is schema->resultset('AtomBusEntry')->count() => 2, '2 entries in db.';
is schema->resultset('AtomBusFeed')->count() => 1, '1 feed in db.';

response_content_like [ GET => "/feeds/$feed" ], qr/content111/,
    "Response has first message.";

my ($entry2) = schema->resultset('AtomBusEntry')->search(
    { title => 'title222', content => 'content222', feed_title => $feed });
ok $entry2, 'Found entry 2.';
ok $entry2->order_id > $entry1->order_id, 'The order_id field got incremented.';

response_content_like [ GET => "/feeds/$feed" ], qr/content111.+content222/s,
    "Response has both messages in order.";

done_testing;
