
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Messages::base;

use strict;
use utf8;

our $VERSION = '3.20';
our %MESSAGES = ();

sub define_messages {
    my $class = shift;
    my %hash = ref($_[0]) eq 'HASH' ? %{$_[0]} : @_;
    while(my($k,$v) = each %hash) {
        $MESSAGES{$k} = $v;  # support inheritance
    }
    {
        no strict 'refs';
        while(my($k,$v) = each %MESSAGES) {
            *{$k} = sub { $v };
        }
    }
}

# This method should remain unchanged
sub messages {
    return wantarray ? %MESSAGES : \%MESSAGES;
}

1;
__END__

