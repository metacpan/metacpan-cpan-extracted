#!perl
Bad::Class->bad_method;
new Bad::Class;
Maybe::Class->bad_method;
Good::Class->bad_method;
Good::Class->good_method;
use constant nothing => 'special';

package Maybe;
package Good::Class;
sub good_method {}
