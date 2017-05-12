
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

# file fields are rendered exactly like text fields

package CGI::FormBuilder::Field::file;

use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field::text;
use base 'CGI::FormBuilder::Field::text';


our $VERSION = '3.10';

*render = \&tag;
sub tag {
    my $self = shift;
    # special catch to make life easier (too action-at-a-distance?)
    # if there's a 'file' field, set the form enctype if they forgot
    if ($self->{_form}->smartness) {
        $self->{_form}{enctype} ||= 'multipart/form-data';
        debug 2, "verified enctype => 'multipart/form-data' for 'file' field";
    }
    return $self->SUPER::tag(@_);
}

1;

__END__

