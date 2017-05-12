package Alt::Bar::two;
# test check=>0, Bar does not define $ALT but it's okay
use base qw(Alt::Base);
our %ALT = (check => 0);
1;
