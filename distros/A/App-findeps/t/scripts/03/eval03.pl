use strict;
use warnings;

use lib 't/lib';

=pod

these below are SHOLD be warned because they're inside of C<eval>

=cut

eval {    # braced
    require Module::Exists::Unexpected;

    #    use Module::Exists::Unexpected;    # use in eval is TODO
};        # line ends

delete $INC{'Module/Exists/Unexpected.pm'};

eval "    # double quoted
    require Module::Exists::Unexpected;
#    use Module::Exists::Unexpected;    # use in eval is TODO
" or die $@;    # line continues

delete $INC{'Module/Exists/Unexpected.pm'};

my $eval = eval '    # single quoted
    require Module::Exists::Unexpected;
#    use Module::Exists::Unexpected;    # use in eval is TODO
' || {};        # line continues

require Acme::BadExample;    # does not exist anywhere
