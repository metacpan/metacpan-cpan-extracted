package P;
use Class::Privacy;
sub new { bless {}, shift }
sub get { $_[0]->{$_[1]} }
sub set { $_[0]->{$_[1]} = $_[2] }
1;
