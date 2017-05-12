# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
package TestComplete::Type1;
use base 'TestComplete::Base';

use strict;
use warnings;

use Class::Dot qw(-new :std);

property in_type1 => isa_String();

my $CLOSURE;

sub BUILD {
    my ($self, $options_ref) = @_;

    $CLOSURE = 'built with Type1';

    return;
}

sub get_closure {
    return $CLOSURE;
}

1;

__END__


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
