package B::DeparseTree;

use rlib '.';
use strict;
use vars qw(@ISA $VERSION);

$VERSION = '2.1.5';

my $module;
if ($] >= 5.016 and $] < 5.018) {
    $module = "P516";
} elsif ($] >= 5.018 and $] < 5.022) {
    # For now 5.18 and 5.20 are the same.  If in the future they
    # should be different, we can deal with that here.
    $module = "P520";
# } elsif ($] >= 5.020 and $] < 5.022) {
#     require "B/DeparseTree/${module}.pm";
#     *compile = \&B::DeparseTree::P520::compile;
} elsif ($] >= 5.022 and $] < 5.024) {
    $module = "P522";
} elsif ($] >= 5.024 and $] < 5.026) {
    $module = "P524";
} elsif ($] >= 5.026) {
    $module = "P526";
} else {
    die "Can only handle Perl 5.16..5.26";
}
require "B/DeparseTree/${module}.pm";
*compile = \&B::DeparseTree::Common::compile;

@ISA = ("B::DeparseTree::$module");

1;

__END__
