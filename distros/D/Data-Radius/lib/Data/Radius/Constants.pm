package Data::Radius::Constants;
use strict;
use warnings;

use constant {
    # RADIUS Codes
    ACCESS_REQUEST      => 1,
    ACCESS_ACCEPT       => 2,
    ACCESS_REJECT       => 3,
    ACCOUNTING_REQUEST  => 4,
    ACCOUNTING_RESPONSE => 5,
    ACCOUNTING_STATUS   => 6,
    ACCESS_CHALLENGE    => 11,
    # unused - not exported
    STATUS_SERVER       => 12,
    STATUS_CLIENT       => 13,
    # rfc3576
    DISCONNECT_REQUEST  => 40,
    DISCONNECT_ACCEPT   => 41,
    DISCONNECT_REJECT   => 42,
    COA_REQUEST         => 43,
    COA_ACCEPT          => 44,
    COA_REJECT          => 45,
};

use Exporter qw(import);

our @EXPORT_OK = qw(
    ACCESS_REQUEST ACCESS_ACCEPT ACCESS_REJECT
    ACCOUNTING_REQUEST ACCOUNTING_RESPONSE ACCOUNTING_STATUS
    ACCESS_CHALLENGE
    DISCONNECT_REQUEST DISCONNECT_ACCEPT DISCONNECT_REJECT
    COA_REQUEST COA_ACCEPT COA_REJECT
);

our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

1;

__END__

=head1 NAME

Data::Radius::Constants - export constants for Data::Radius::Packet

=head1 SYNOPSIS

    use Data::Radius::Constants qw(:all);

or

    use Data::Radius::Constants qw(ACCESS_REQUEST ACCESS_ACCEPT ACCESS_REJECT);

=head1 SEE ALSO

L<Data::Radius::Packet>

=head1 AUTHOR

Sergey Leschenko <sergle.ua at gmail.com>

PortaOne Development Team <perl-radius at portaone.com> is the current module's maintainer at CPAN.

=cut

