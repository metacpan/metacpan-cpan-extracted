package DBR::Config::Trans::Dollars;

use strict;
use base 'DBR::Config::Trans';

sub new { die "Should not get here" }


sub forward{
      my $self = shift;
      my $cents = shift;
      return bless( [$cents] , 'DBR::_DOLLARS');
}

sub backward{
      my $self = shift;
      my $value = shift;

      return undef unless defined($value) && length($value);

      if( ref($value) eq 'DBR::_DOLLARS' ){ # looks like it's a dollar object, yay!
	    return $value->cents;
      }

      $value =~ tr/0-9.-//cd; # the items listed are ALLOWED values
      unless(length($value)){
	    $self->_error('invalid value specified');
	    return ();
      }
      return sprintf("%.0f", ($value * 100) );
}

package DBR::_DOLLARS;

use strict;
use Carp;
use overload 
#values
'""' => sub { $_[0]->format },
'0+' => sub { $_[0]->dollars },

# comparisons
'==' => sub { $_[0]->dollars == $_[1] },
'!=' => sub { $_[0]->dollars != $_[1] },

#operators
'+'  => sub { new($_[0]->cents + _getcents($_[1])) },
'-'  => sub {
      my ($a,$b) = ($_[0]->cents, _getcents($_[1]));
      new ($_[2] ? $b - $a : $a - $b);
},

'*'  => sub { new($_[0]->cents * $_[1]) },
'/'  => sub {
      my ($a,$b) = ($_[0]->cents, $_[1] );
      new ($_[2] ? $b / $a : $a / $b);
},

'fallback' => 1;

*TO_JSON = \&dollars;

sub cents   {
      return '' unless defined($_[0][0]);
      return $_[0][0]
};
sub dollars {
      return '' unless defined($_[0][0]);
      return sprintf("%.02f",$_[0][0]/100)
};

sub format  {
      return '' unless defined($_[0][0]);
      my $dollars = shift->dollars;
      $dollars =~ s/\G(\d{1,3})(?=(?:\d\d\d)+(?:\.|$))/$1,/g;
      return '$' . $dollars;
}

#utilities
sub new{ bless([ $_[1] || $_[0] ],'DBR::_DOLLARS') } # will work OO or functional
sub _getcents{
      my $val = $_[1] || $_[0]; # can be OO or functional
      return $val->cents if ref($val) eq __PACKAGE__;
      return sprintf("%.0f", ($val * 100) )
}


1;
