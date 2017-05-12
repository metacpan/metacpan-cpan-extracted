
package dev::speed;

use common::sense;
use base 'ASP4::FormHandler';
use vars __PACKAGE__->VARS;

sub run {
my ($__self, $__context) = @_;
#line 1
;$Response->Write(q~~);$Response->Write( "Hello, World!\n"x5 );$Response->Write(q~
~);
}

1;# return true:

