
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

# hidden and password fields are rendered exactly like text fields

package CGI::FormBuilder::Field::hidden;

use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field::text;
use base 'CGI::FormBuilder::Field::text';


our $VERSION = '3.20';

sub script {
    return '';  # hidden fields are never checked
}

1;

__END__

