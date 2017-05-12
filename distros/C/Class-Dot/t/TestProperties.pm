# $Id: TestProperties.pm 27 2007-10-29 17:29:12Z asksol $
# $Source$
# $Author: asksol $
# $HeadURL: https://class-dot.googlecode.com/svn/branches/stable-1.5.0/t/TestProperties.pm $
# $Revision: 27 $
# $Date: 2007-10-29 18:29:12 +0100 (Mon, 29 Oct 2007) $
package TestProperties;

use strict;
use warnings;

use Class::Dot qw( -new :std );
use FindBin qw($Bin);
use lib $Bin;
use Cat;
use English qw( -no_match_vars );

property foo => isa_Data;
property bar => isa_Data;
property defval => isa_String('la liberation');
property array  => isa_Array(qw(the quick brown fox ...));
property hash   => isa_Hash(hello => 'world', goobye => 'wonderful');
property digit  => isa_Int(303);
property intnoval => isa_Int;
property obj    => isa_Object('Cat', auto => 1);
property nofunc => 'This does not use isa_*';
property 'nodefault';
property string => isa_String();
property mystery_object => isa_Object();
property code   => isa_Code;
if ($] >= 5.00800) {
   eval 'property codedef => isa_Code {return 10}';
}
else {
   property codedef => isa_Code sub {return 10};
}
   
property filehandle => isa_File;
open my $myself, '<', $PROGRAM_NAME;
property myself     => isa_File($myself);

property override  => isa_String('obladi oblada');
{
    my $MODIFY_ME = 'not modified';

    after_property_get override => sub {
        return $MODIFY_ME;        
    };

    after_property_set override => sub {
        my ($self, $value) = @_;
        $MODIFY_ME = $value;
        return;
    };

}

property override2 => isa_String('oblada obladi');
{
    my $MODIFY_ME = 'xxx not modified';
    
    sub override2 {
        return $MODIFY_ME;
    }

    sub set_override2 {
        my ($self, $value) = @_;
        $MODIFY_ME = $value;
        return;
    }
}


1;

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
