package TestProject::Bogus;
use warnings;
use strict;

=head2 nonexistent

This function actually doesn't exist. It's only here to test that
DispatchFromPod throws an error when given a nonexistent target function.

=head3 XMLRPC bogus.nonexistent

=for xmlrpc bogus.nonexistent nonexistent

=head3 JSONRPC: bogus.nonexistent

=for jsonrpc bogus.nonexistent nonexistent

=cut

1;
