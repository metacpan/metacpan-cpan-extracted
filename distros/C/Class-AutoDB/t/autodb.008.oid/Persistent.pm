########################################
# test class for oid series
########################################
package Persistent;
use strict;
use base qw(Class::AutoDB::Object);

# use base qw(Class::AutoClass);
# use vars qw(%AUTODB);
# %AUTODB=(collection=>'Serialize_OK',keys=>qq(id int, name string));

use vars qw(@AUTO_ATTRIBUTES);
@AUTO_ATTRIBUTES=qw(id name obj);
Class::AutoClass::declare;

our $VERSION=1.23;

# # Oid defines oid, defined, deleted, put, del methods. 
# # override them here to make sure these don't hit AUTOLOAD
# sub oid {'oid method in test class '.__PACKAGE__}
# sub defined {'defined method in test class '.__PACKAGE__}
# sub deleted {'deleted method in test class '.__PACKAGE__}
# sub put {'put method in test class '.__PACKAGE__}
# sub del {'del method in test class '.__PACKAGE__}


1;
