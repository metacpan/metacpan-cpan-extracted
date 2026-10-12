# eg/chat.pl - list conversations, read one, optionally reply.
#
#   cd eg
#   perl chat.pl [convo-id] [message text...]
use v5.40;
use blib;
$|++;
use Bluesky;
#
my $bsky   = Bluesky->new->ensure_auth( handle => 'atperl.bsky.social', scope => 'atproto transition:generic transition:chat.bsky' );
my $wanted = shift;
my $convos = $bsky->listConvos( limit => 10 );
say sprintf '%d conversations', scalar @$convos;
for my $convo (@$convos) {
    my $members = join ', ', map { $_->{handle} // $_->{did} } @{ $convo->{members} // [] };
    say sprintf '%s | unread %d | %s', $convo->{id}, $convo->{unreadCount} // 0, $members;
}
my $id = $wanted // $convos->[0]{id} or die "No conversation to read\n";
say "\nMessages in $id:";
my $messages = $bsky->getMessages( convoId => $id, limit => 10 );
for my $msg (@$messages) {
    next unless $msg->{text};
    say sprintf '%s: %s', $msg->{sender}{did} // '?', substr( $msg->{text}, 0, 120 );
}
if (@ARGV) {
    my $text = join ' ', @ARGV;
    $bsky->sendMessage( $id, { text => $text } );
    say 'Sent.';
}
$bsky->updateRead($id);
say 'Marked as read.';
