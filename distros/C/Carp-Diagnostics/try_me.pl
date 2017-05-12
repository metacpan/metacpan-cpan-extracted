
use strict ;
use warnings ;

use lib qw(lib) ;

use Data::TreeDumper ;

use Carp::Diagnostics qw(cluck carp croak confess) ;
 
CroakingSub() ;

sub CroakingSub
{

=head2 CroakingSub

An example of how to use Carp::Diagnostics.

=head3 Diagnostics

=cut

my ($default_rule_name, $name) = ('c_objects', 'o_cs_meta') ;

carp
	(
	"Default rule '$default_rule_name', in rule '$name', doesn't exist.\n",
	
	<<EOD,

=over

=item Default rule '$default_rule_name', in rule '$name', doesn't exist.


The default rule of a I<FirstAndOnlyOneOnDisk> B<META_RULE> must be registrated before
the B<META_RULE> definiton. Here is an example of declaration:

 AddRule 'c_o', [ '*/*.o' => '*.c' ] => \&C_Builder ;
 AddRule 'cpp_o', [ '*/*.o' => '*.cpp' ] => \&CPP_Builder ;
 
 AddRule [META_RULE], 'o_cs_meta' =>
 	[\&FirstAndOnlyOneOnDisk, ['cpp_o', 'c_o' ], 'c_o'] ;
 	                          ^- slave rules -^    ^-default

=back

=cut

EOD
	) ;
}


