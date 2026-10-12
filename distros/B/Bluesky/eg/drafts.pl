# eg/drafts.pl - full draft round-trip: create, list, update, delete.
#
#   cd eg
#   perl drafts.pl
use v5.40;
use blib;
$|++;
use Bluesky;
#
my $bsky    = Bluesky->new->ensure_auth( handle => 'atperl.bsky.social', scope => 'atproto transition:generic transition:chat.bsky' );
my $created = $bsky->createDraft( { posts => [ { text => 'Unfinished thought, saved from Perl' } ] } );
my $id      = $created->{id} or die "No draft id returned\n";
say "Created draft $id";
my $drafts = $bsky->getDrafts();
say sprintf '%d drafts stored', scalar @$drafts;
$bsky->updateDraft( { id => $id, draft => { posts => [ { text => 'Finished thought, saved from Perl' } ] } } );
say "Updated draft $id";
$bsky->deleteDraft($id);
say "Deleted draft $id";
