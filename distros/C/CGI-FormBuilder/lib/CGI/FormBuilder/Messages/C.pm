
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Messages::locale;

use strict;

use CGI::FormBuilder::Messages::default;
use base 'CGI::FormBuilder::Messages::default';

our $VERSION = '3.10';

# Inherit all messages from default (English) messages
#
# This structure is needed so that we can have a ::default class and
# have all languages inherit from that.  Before, we ran into oddities
# where ::default != ::locale and got "base class is empty" errors.

1;
__END__

