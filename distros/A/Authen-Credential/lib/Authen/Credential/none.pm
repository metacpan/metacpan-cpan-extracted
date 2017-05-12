#+##############################################################################
#                                                                              #
# File: Authen/Credential/none.pm                                              #
#                                                                              #
# Description: abstraction of a "none" credential                              #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Authen::Credential::none;
use strict;
use warnings;
our $VERSION  = "1.1";
our $REVISION = sprintf("%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/);

#
# inheritance
#

our @ISA = qw(Authen::Credential);

#
# used modules
#

use Authen::Credential qw();

#
# Params::Validate specification
#

$Authen::Credential::ValidationSpec{none} = {};

1;

__DATA__

=head1 NAME

Authen::Credential::none - abstraction of a "none" credential

=head1 DESCRIPTION

This helper module for Authen::Credential implements a "none"
credential, that is the absence of authentication credential.

It does not support any attributes.

=head1 SEE ALSO

L<Authen::Credential>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2011-2015
