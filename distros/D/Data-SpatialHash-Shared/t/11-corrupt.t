use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;
use Fcntl qw(SEEK_SET);

# sph_validate_header must reject corrupt / truncated / mismatched backing files
# rather than mapping garbage.

my $tmp  = "/tmp/sph-corrupt-$$.bin";
my @args = (20, 0, 1.0);

sub make_valid {
    unlink $tmp;
    my $s = Data::SpatialHash::Shared->new($tmp, @args);
    $s->sync;       # flush the mmap'd header to the file before we tamper via syscalls
    undef $s;
}
sub rejected { !eval { Data::SpatialHash::Shared->new($tmp, @args); 1 } }

make_valid();
ok eval { my $s = Data::SpatialHash::Shared->new($tmp, @args); 1 }, 'a freshly created file reopens';

{ open my $fh, '>', $tmp or die $!; print $fh "junk"; close $fh;
  ok rejected(), 'too-small file rejected'; }

{ make_valid();
  open my $fh, '+<', $tmp or die $!; binmode $fh;
  sysseek($fh, 0, SEEK_SET); syswrite($fh, "\xFF\xFF\xFF\xFF"); close $fh;
  ok !eval { Data::SpatialHash::Shared->new($tmp, @args); 1 }, 'wrong-magic file rejected';
  like $@, qr/invalid/i, 'magic mismatch error mentions invalid'; }

{ make_valid();
  open my $fh, '+<', $tmp or die $!; binmode $fh;
  sysseek($fh, 4, SEEK_SET); syswrite($fh, pack('V', 999)); close $fh;   # version field
  ok rejected(), 'wrong-version file rejected'; }

{ make_valid();
  open my $fh, '>>', $tmp or die $!; binmode $fh; print $fh ("\0" x 4096); close $fh;
  ok rejected(), 'oversized file (size != total_size) rejected'; }

{ make_valid();
  my $sz = -s $tmp; truncate($tmp, $sz - 128) or die $!;
  ok rejected(), 'truncated file rejected'; }

{ # sphere and wrap cannot coexist: a wrap file with sphere_radius poked in is rejected
  unlink $tmp;
  my $w = Data::SpatialHash::Shared->new($tmp, 20, 0, 1.0, wrap => [4, 4]);
  $w->sync; undef $w;
  open my $fh, '+<', $tmp or die $!; binmode $fh;
  sysseek($fh, 128, SEEK_SET); syswrite($fh, pack('d', 100.0)); close $fh;   # sphere_radius field (offset 128)
  ok !eval { Data::SpatialHash::Shared->new($tmp, 20, 0, 1.0); 1 }, 'sphere_radius set with wrap flag rejected on reopen'; }

unlink $tmp;
done_testing;
