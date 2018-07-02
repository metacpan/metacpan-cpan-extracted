package Data::Format::Validate::IP;
our $VERSION = q/0.2/;

use Carp qw/croak/;
use base q/Exporter/;

our @EXPORT_OK = qw/
    looks_like_ipv4
    looks_like_ipv6
/;

our %EXPORT_TAGS = (
    q/all/ => [qw/
        looks_like_ipv4
        looks_like_ipv6
    /]
);

sub looks_like_ipv4 ($) {

    $_ = shift || croak q/Value must be provided/;
    /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
}

sub looks_like_ipv6 ($) {

    $_ = shift || croak q/Value must be provided/;
    /^(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}$/i
}
1;

=pod

=encoding utf8

=head1 NAME

Data::Format::Validate::IP - A IP validating module.

=head1 SYNOPSIS

Module that validate IP addressess.

=head1 Utilities

=over 4

=item IP (ipv4)

    use Data::Format::Validate::IP 'looks_like_ipv4';

    looks_like_ipv4 '127.0.0.1';        # 1
    looks_like_ipv4 '192.168.0.1';      # 1
    looks_like_ipv4 '255.255.255.255';  # 1

    looks_like_ipv4 '255255255255';     # 0
    looks_like_ipv4 '255.255.255.256';  # 0

=item IP (ipv6)

    use Data::Format::Validate::IP 'looks_like_ipv6';

    looks_like_ipv6 '1762:0:0:0:0:B03:1:AF18';                  # 1
    looks_like_ipv6 '1762:ABC:464:4564:0:BA03:1000:AA1F';       # 1
    looks_like_ipv6 '1762:4546:A54f:d6fd:5455:B03:1fda:dFde';   # 1

    looks_like_ipv6 '17620000AFFFB031AF187';                    # 0
    looks_like_ipv6 '1762:0:0:0:0:B03:AF18';                    # 0
    looks_like_ipv6 '1762:0:0:0:0:B03:1:Ag18';                  # 0
    looks_like_ipv6 '1762:0:0:0:0:AFFFB03:1:AF187';             # 0

=back

=head1 CONTRIBUITION

This source is on Github:

	https://github.com/rozcovo/Data-Format-Validate/blob/master/lib/Data/Format/Validate/IP.pm

=head1 AUTHOR

Created by Israel Batista <<israel.batista@univem.edu.br>>

=cut
