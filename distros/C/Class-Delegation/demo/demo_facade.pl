package Levorotatory;

sub rotate { print "rotating left by $_[1] degrees...\n" }

package Dextrorotatory;

sub rotate { print "rotating right by $_[1] degrees...\n" }

package Bilateral;

%Bilateral = ( left  => 'Levorotatory',
	       right => 'Dextrorotatory',
	     );
	     
use Class::Delegation
	send => qr/(left|right)_(.*)/,
	  to => sub { $1 },
	  as => sub { $2 },
	;

sub AUTOLOAD  { 
	use Carp;
	carp "$AUTOLOAD does not begin with 'left_...' or 'right_...'"
}


package main;

Bilateral->left_rotate(45);
Bilateral->right_rotate(60);
