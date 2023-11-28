use strict;
use warnings;
#
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';

#~ use Mojo::UserAgent;
use At::Bluesky;
use At;
use Config::Tiny;
$|++;
#
my $config = Config::Tiny->read('bluesky.conf');
use Data::Dump;

#~ ddx( At::Bluesky->new( %{ $config->{_} } )->repo->createRecord( text => 'Nice.' ) );
ddx( At::Bluesky->new( %{ $config->{_} } )->post( text => 'Nice.' ) );
use At;
my $at = At->new( host => 'https://bsky.social' );
$at->server;
$at->server->createSession( %{ $config->{_} } );

#~ my $at = At->new( host => 'https://fun.example', identifier => 'sanko', password => '1111-aaaa-zzzz-0000' );
{
    use Time::Piece;
    ddx $at->repo->createRecord(    # Or use At::Bluesky->text_post( ... )
        collection => 'app.bsky.feed.post',
        record     => { '$type' => 'app.bsky.feed.post', text => "Hello world! I posted this via the API.", createdAt => gmtime->datetime . 'Z' }
    );
}
__END__
Create a config file named bluesky.conf with contents that look like this:

identifier=sanko
password=eee-sss-wwww-dddd
