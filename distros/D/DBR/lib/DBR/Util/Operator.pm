package DBR::Util::Operator;

use strict;
use base 'Exporter';
our @EXPORT = qw(GT LT GE LE NOT LIKE NOTLIKE BETWEEN NOTBETWEEN AND OR);
use DBR::Misc::General; # imported utils

# Object oriented
sub new{
      my $package  = shift;
      my $operator = shift;
      my $value    = shift;

      my $self  = [$operator,$value];
      bless ( $self, $package );
      return ( $self );
}

sub operator {$_[0]->[0]}
sub value    {$_[0]->[1]}
sub stringify{ 'OP-' . $_[0][0] . ':' . _expandstr( $_[0][1] ) }

# EXPORTED:

sub GT   ($) { __PACKAGE__->new('gt',  $_[0]) }
sub LT   ($) { __PACKAGE__->new('lt',  $_[0]) }
sub GE   ($) { __PACKAGE__->new('ge',  $_[0]) }
sub LE   ($) { __PACKAGE__->new('le',  $_[0]) }
sub NOT  ($) { __PACKAGE__->new('not', $_[0]) }
sub LIKE ($) { __PACKAGE__->new('like',$_[0]) }
sub NOTLIKE ($) { __PACKAGE__->new('notlike',$_[0]) }

sub BETWEEN    ($$) { __PACKAGE__->new('between',   [ $_[0],$_[1] ]) }
sub NOTBETWEEN ($$) { __PACKAGE__->new('notbetween',[ $_[0],$_[1] ]) }

# Yes, having an AND operator is a little silly,
# given that AND is the default operation,
# but it's necessary to represent some of the more
# esoteric queries out there now that OR is in the mix.
# A AND (B OR C) is not equivelant to A AND B OR C
sub AND {
      bless ([
	      'And', [ @_ ],
	      (scalar ( grep { !(ref($_) eq 'DBR::_LOP') || $_->operator eq 'And' } @_ ) == @_) ? 1 : 0, # calculate only_contains_and
	     ], 'DBR::_LOP');
}
sub OR {
      bless ([
	      'Or', [ @_ ],
	      (scalar (  grep { !(ref($_) eq 'DBR::_LOP') || $_->operator eq 'And' } @_ ) == @_) ? 1 : 0, # calculate only_contains_and
	     ], 'DBR::_LOP' );
     }

package DBR::_LOP;
use base 'DBR::Util::Operator';
use DBR::Misc::General; # imported utils

sub only_contains_and{ $_[0][2] }

sub stringify{ 'LOP-' . $_[0][0] . ':' . _expandstr( $_[0][1] ) }

1;
