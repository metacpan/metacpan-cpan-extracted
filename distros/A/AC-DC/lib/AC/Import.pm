# -*- perl -*-

# Copyright (c) 2008 by AdCopy
# Author: Jeff Weisberg
# Created: 2008-Dec-18 20:26 (EST)
# Function: import/export
#
# $Id$

package AC::Import;
use strict;

our @EXPORT = 'import';


sub import {
    my $class  = shift;
    my $caller = caller;

    no strict;
    no warnings;
    for my $f ( @{$class . '::EXPORT'} ){
        *{$caller . '::' . $f} = \&{ $class . '::' . $f };
    }
}

=head1 NAME

AC::Import - Import/Export functions

=head1 SYNOPSIS

    use AC::Import;
    use strict;
    our @EXPORT = qw(function1 function2);

=head1 SEE ALSO

    Exporter

=cut

1;

