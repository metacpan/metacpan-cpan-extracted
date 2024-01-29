use strict;
use warnings;
#
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use At;                              # Or use At::Bluesky
use At::Lexicon::app::bsky::feed;    # Or use At::Bluesky
use Config::Tiny;
use Time::Piece;
$|++;
#
my $config = Config::Tiny->read('bluesky.conf');
my $at     = At->new( host => 'https://bsky.social', %{ $config->{_} } );
$at->repo_createRecord(
    repo       => $at->did,
    collection => 'app.bsky.feed.post',
    record     => { '$type' => 'app.bsky.feed.post', text => 'Hello world! I posted this via the API.', createdAt => gmtime->datetime . 'Z' }
);
__END__
Create a config file named bluesky.conf with contents that look like this:

identifier=sanko
password=eee-sss-wwww-dddd
