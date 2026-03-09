use v5.40;
use At;
use InterPlanetary::Node;

# Initialize an IPFS node to enable P2P capabilities
say 'Initializing IPFS node...';
my $node = InterPlanetary::Node->new( enable_upnp => 0 );

# Initialize the At client with the IPFS node
my $at = At->new( host => 'bsky.social', ipfs_node => $node );

# Resolve a Bluesky user to their P2P PeerID
my $did = 'did:plc:z72i7hdynmk6r22z27h6tvur';    # why.bsky.social
say "Bridging DID $did to libp2p...";
my $peer_id = $at->peer_id_for_did($did);
say 'Successfully resolved to PeerID: ' . $peer_id->to_string() if $peer_id;

# Fetch a repository block
# In a real scenario, you would first get the root CID via $at->get_repo_head($did)
my $root_cid_str = 'bafyreia2izlj2wnxrwzoh4skwlahyc2conqdjugbsvy6eu5qtyc7ws6dsu';
say "Fetching repository block $root_cid_str via P2P...";
my $f = $at->get_block( $root_cid_str, $peer_id ? $peer_id->to_string : undef );

# Since this is an asynchronous operation, we drive the loop until the block arrives
# or the request fails.
while ( !$f->is_ready ) {
    $node->host->io_utils->loop->loop_once(0.1);
}
if ( $f->is_done ) {
    my $data = $f->get;
    say 'Successfully retrieved ' . length($data) . ' bytes from the P2P network!';
}
else {
    say 'P2P retrieval failed: ' . $f->failure;
    say 'The library would normally fall back to HTTP XRPC here.';
}
