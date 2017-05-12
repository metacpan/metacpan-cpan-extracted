package B::DeparseTree;

use rlib '.';
use strict;
use vars qw(@ISA $VERSION);

$VERSION = '2.1.3';

my $module;
if ($] >= 5.018 and $] < 5.022) {
    # For now 5.18 and 5.20 are the same.  If in the future they
    # shoudl be different, we can deal with that here.
    $module = "P520";
    require "B/DeparseTree/${module}.pm";
# } elsif ($] >= 5.020 and $] < 5.022) {
#     require "B/DeparseTree/${module}.pm";
#     *compile = \&B::DeparseTree::P520::compile;
} elsif ($] >= 5.022) {
    $module = "P522";
    require "B/DeparseTree/${module}.pm";
} elsif ($] >= 5.024) {
    $module = "P524";
    require "B/DeparseTree/${module}.pm";
} else {
    die "Can only handle Perl 5.18, 5.20, 5.22 and 5.24";
}
*compile = \&B::DeparseTree::Common::compile;

@ISA = ("B::DeparseTree::$module");

1;

__END__
