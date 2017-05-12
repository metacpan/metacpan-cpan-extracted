#
# Courier::Error class
#
# (C) 2003-2008 Julian Mehnle <julian@mehnle.net>
# $Id: Error.pm 210 2008-03-21 19:30:31Z julian $
#
###############################################################################

=head1 NAME

Courier::Error - Exception class for Perl modules related to the Courier MTA

=cut

package Courier::Error;

use warnings;
use strict;

use Error;

use base 'Error::Simple';

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

=head1 SYNOPSIS

=head2 Exception handling

    use Error qw(:try);
    use Courier::Error;
    
    try {
        ...
        throw Courier::Error($error_message) if $error_condition;
        ...
    }
    catch Courier::Error with {
        ...
    };
    # See "Error" for more exception handling syntax.

=head2 Deriving new exception classes

    package Courier::Error::My;
    use base qw(Courier::Error);

=head1 DESCRIPTION

This class is a simple exception class for Perl modules related to the Courier
MTA.  See L<Error> for detailed instructions on how to use it.

=head1 SEE ALSO

For AVAILABILITY, SUPPORT, and LICENSE information, see
L<Courier::Filter::Overview>.

=head1 AUTHOR

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;
