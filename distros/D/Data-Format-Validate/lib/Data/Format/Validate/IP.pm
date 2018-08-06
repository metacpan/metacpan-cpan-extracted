package Data::Format::Validate::IP;
our $VERSION = q/0.3/;

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

    my $ip = shift || croak q/Value must be provided/;
    $ip =~ /^
        (?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}   # Three groups of numbers from 0 to 255 joined by '.'
        (?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)            # Final group of numbers, but without '.'
    $/x
}

sub looks_like_ipv6 ($) {

    my $ip = shift || croak q/Value must be provided/;
    $ip =~ /^
        (?:[A-F0-9]{1,4}:){7}   # Seven groups with 1 to 4 hexadecimal digits joined by ':'
        [A-F0-9]{1,4}           # Final group of digits, but without ':'
    $/ix
}
1;

=pod

=encoding utf8

=head1 NAME

Data::Format::Validate::IP - A IP validating module.

=head1 SYNOPSIS

Function-oriented module capable of validating the format of IPV4 or IPV6 addresses.

=head1 UTILITIES

=over 4

=item IP (ipv4)

    use Data::Format::Validate::IP 'looks_like_ipv4';

    looks_like_ipv4 '127.0.0.1';    # returns 1
    looks_like_ipv4 '255255255255'; # returns 0

=item IP (ipv6)

    use Data::Format::Validate::IP 'looks_like_ipv6';

    looks_like_ipv6 '1762:0:0:0:0:B03:1:AF18';  # returns 1
    looks_like_ipv6 '17620000AFFFB031AF187';    # returns 0

=back

=head1 CONTRIBUITION

This source is on Github:

	https://github.com/rozcovo/Data-Format-Validate/blob/master/lib/Data/Format/Validate/IP.pm

=head1 AUTHOR

Created by Israel Batista <rozcovo@cpan.org>

=cut
