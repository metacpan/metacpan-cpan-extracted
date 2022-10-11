package TestProject::SystemCalls;
use warnings;
use strict;

our $VERSION = '1.0';

=head2 do_ping()

Returns true

=head3 RESTISH GET /system/ping

=for restish GET@ping do_ping /system

=cut

sub do_ping {
    return { response => \1 };
}

=head2 do_version()

Returns the current version

=head3 RESTISH GET /system/version

=for restish GET@version do_version /system

=cut

sub do_version {
    return { software_version => $VERSION };
}

1;
