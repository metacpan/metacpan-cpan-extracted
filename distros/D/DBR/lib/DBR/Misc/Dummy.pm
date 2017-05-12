# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Misc::Dummy;
# I only ever evaluate to false...  false false falsey false
# plus, when you call any method, I just return myself.

use Carp;
use overload 
  #values
  '""'   => sub { '' },
  '0+'   => sub { 0 },
  'bool' => sub { 0 },

  #operators
  '+'  => sub { $_[1] },
  '-'  => sub { return $_[2] ? $_[1] : 0 - $_[1] },

  '*'  => sub { 0 },
  '/'  => sub { 0 },

 'fallback' => 1
 ;

sub TO_JSON { undef }

our $AUTOLOAD;
sub AUTOLOAD { shift }
1;
