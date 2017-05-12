package DBR::Misc::General;
use strict;
use base 'Exporter';
our @EXPORT = qw(_expandstr _expandstrs);
use Scalar::Util 'blessed';

# Non-oo stuff goes here


# _expandstr... I'm probably going to hell for this
# The point here is to stringify things as fast as possible, as it affects
# how quickly I can identify whether two where clauses are the same, or different

my ($v,$r);
sub _expandstr{
      $v = shift;
      $r = ref($v);
      return $r?
           # yes its a ref
 	   blessed($v) ?
 		 $v->stringify # it's blessed
 	   :
                 # not blessed
 		 $r eq 'ARRAY'? '['. join("\0|",map { _expandstr($_) } @{$v} ) . ']' : # Arrayref
 		 $r eq 'HASH' ? '{'. join("\0|",map { $_ => _expandstr( $_->{$_} ) } sort keys %$v) . '}' : # Hashref
 		 $v # Unknown type of ref, let it go
      : $v # not a ref, just use the value
}

1;
