use 5.010;
use warnings;
use Data::UUID::MT;

for my $v (qw/1 4 4s/) {
  my $ug = Data::UUID::MT->new( version => $v );
  say "Version $v UUIDs:";
  for ( 1 .. 5 ) {
    say "  " . $ug->create_string;
  }
}

