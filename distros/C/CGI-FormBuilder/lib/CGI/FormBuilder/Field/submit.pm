
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

# Create <submit> fields

package CGI::FormBuilder::Field::submit;

use strict;
use warnings;
no  warnings 'uninitialized';

# rendered just like a text field (ala button)

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field::text;
use base 'CGI::FormBuilder::Field::text';


our $VERSION = '3.20';

sub script { '' }

1;

__END__

