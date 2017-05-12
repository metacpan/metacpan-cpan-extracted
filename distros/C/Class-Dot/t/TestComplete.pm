# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
package TestComplete;

use strict;
use warnings;

use Class::Dot qw(-new -rebuild :std);

use TestComplete::Type1;
use TestComplete::Type2;

sub BUILD {
    my ($class, $options_ref) = @_;
    $options_ref ||= @_;

    my $type = $options_ref->{type};

    $type    = "TestComplete::$type";

    my $delegated_to = $type->new($options_ref);

    return $delegated_to;
}

1;

__END__

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
