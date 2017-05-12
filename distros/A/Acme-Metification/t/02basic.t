use strict;
use warnings;
#use lib 'lib';

use Test::More tests => 3;

use Acme::Metification;
ok(1, "Module loaded.");

# Execute code from the pod docs:

ok(1, "Applied filter.");
meta 13, 13

=pod

=head1 BLA

=head2 Example

  ok(1, "Filter application successful.");

=cut
