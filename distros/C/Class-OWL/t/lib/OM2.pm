package OM2;
use lib qw(lib);
use Class::OWL 
        package => 'OM2',
	url => 'http://www.openmetadir.org/om2/om2-1.owl',
 	debug => 1;

package OM2::PRIM;
use lib qw(lib);
use Class::OWL
        package => 'OM2::Prim',
	url => 'http://www.openmetadir.org/om2/prim-3.owl',
	debug => 1;

package OM2::Node;
use lib qw(lib);
use Class::OWL
        package => 'OM2::Node',
        url => 'http://www.openmetadir.org/om2/node.owl',
        debug => 1;

package OM2;

1;
