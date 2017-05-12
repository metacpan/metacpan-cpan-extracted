package Bloodbowl::Coach;

use Moo;
with 'DBIx::Mint::Table';

has id       => ( is => 'rwp' );
has name     => ( is => 'rw', required => 1);
has email    => ( is => 'rw');
has password => ( is => 'rw');

1;
