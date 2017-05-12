
package t::coderef;
use strict;
use warnings;

{
  my $i = 0;
  sub counterv { \$i }
  sub counter { sub{ $i++ } }
}

1;
__END__
