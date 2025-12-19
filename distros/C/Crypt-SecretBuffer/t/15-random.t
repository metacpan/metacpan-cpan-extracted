use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw( secret NONBLOCK );

# This test attempts to verify that the random function fills the first and last byte
# requested and no more or less.

# fills with 0 by default
my $buf= secret(capacity => 16, stringify_mask => undef);

# verify first and last bytes are not NUL.  This will fail 1/256 chance, so keep trying
# until we are sure it isn't just chance.
my ($first_nonzero, $last_nonzero);
for my $attempt (1..10_000) {
   my $n= $buf->append_random(10, NONBLOCK);
   skip_all "Not enough entropy on this host"
      unless $n == 10;
   $first_nonzero ||= $buf->index("\0") != 0;
   $last_nonzero  ||= $buf->index("\0", 9) != 9;
   last if $first_nonzero && $last_nonzero;
   $buf->length(0); # zeroes buffer
   note "Trying again...";
}
ok( $first_nonzero, 'wrote first byte' );
ok( $last_nonzero,  'wrote last byte' );
is( $buf->length, 10, 'length' );

# Now grow by one byte, which current implementation relies on having already zeroed the buffer,
# and if random call was overwriting beyond the requested range it would result in 1/256 chance
# that the byte is not NUL.
$buf->length(11);
is( $buf->index("\0", 10), 10, 'byte beyond random range is zero' )
   or diag escape_nonprintable $buf;

# A more interesting test might be to collect statistics about each byte, and ensure they
# approach an even distribution, but this would take a bunch of CPU and time and possibly
# run people out of entropy on older headless hosts.

done_testing;
