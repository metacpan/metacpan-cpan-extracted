package TestProject::SystemCalls;
use warnings;
use strict;

our $VERSION = '1.0';

=head2 do_ping()

Returns true

=head3 XMLRPC system.ping

=for xmlrpc system.ping do_ping

=head3 JSONRPC system.ping

=for jsonrpc system.ping do_ping

=head3 RESTRPC /rest/system/ping

=for restrpc ping do_ping

=cut

sub do_ping {
    return { response => \1 };
}

=head2 do_version()

Returns the current version

=head3 XMLRPC system.version

=for xmlrpc system.version do_version

=head3 RESTRPC /rest/system/version

=for restrpc version do_version

=cut

sub do_version {
    return { software_version => $VERSION };
}
1;
