package # hide from PAUSE
  LuaMunger;
use 5.14.0;
use warnings;

use Exporter 'import';
our @EXPORT = qw(from_to);

sub from_to {
  my ($in, $out, $root) = (@_ ? @_ : @ARGV);
  open my $fh, "<", $in
    or die "Could not open input file '$in': $!";
  open my $oh, ">", $out
    or die "Could not open output file '$out' for writing: $!";
  while (defined(my $line = <$fh>)) {
    $line =~ s/%%LUAROOT%%/$root/g;
    print $oh $line;
  }
  return 1;
}

1;
