use Test2::V0;
use Crypt::SecretBuffer qw( secret );

skip_all 'Require /proc/self/maps for this test'
   unless -r '/proc/self/maps';
skip_all '_count_matches_in_mem not implemented on this platform'
   unless eval { Crypt::SecretBuffer->new("x")->_count_matches_in_mem(0,0); 1 };

sub count_copies_in_mem {
   my $buf= shift;
   my $map_spec= do { local $/; open my $fh, '</proc/self/maps'; <$fh> };
   my $n= 0;
   # Scan the memory maps looking for read/writeable ranges
   while ($map_spec =~ /^([0-9a-f]+)-([0-9a-f]+) rw/img) {
      no warnings 'portable';
      $n += $buf->_count_matches_in_mem(hex $1, hex $2);
   }
   return $n;
}

my $buf= secret();
$buf->append_random(64);
is( count_copies_in_mem($buf), 1, 'one instance' );

my $clone= secret($buf);
is( count_copies_in_mem($buf), 2, 'original + copy' );

my $clone2= secret($buf);
is( count_copies_in_mem($buf), 3, 'original + 2x copy' );

undef $clone;
print "# after undef\n";
$clone2->clear;
print "# after clear\n";
is( count_copies_in_mem($buf), 1, 'copies cleared' );

done_testing;
