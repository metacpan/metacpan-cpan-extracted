use strict;
use warnings;

use lib 't/lib';

=pod

these below are not parsed because they're inside of C<eval> 

=cut

eval {    # braced
    require Eval::With::Brace;
};    # line ends

eval "    # double quoted
        require Eval::With::DoubleQuote;
    " or die $@;    # line continues

my $eval = eval '    # single quoted
    require Eval::With::SingleQuote;
' || {};            # line continues

require Dummy;      # does not exist anywhere

exit;
