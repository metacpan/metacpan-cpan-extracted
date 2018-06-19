package Data::Format::Validate::String 0.3;

use base 'Exporter';

use Carp qw/croak/;

our @EXPORT_OK = qw/
    looks_like_ipv4
    looks_like_ipv6
/;

our %EXPORT_TAGS = (
    'ip' => [qw/
        looks_like_ipv4
        looks_like_ipv6
    /]
);

sub looks_like_ipv4 {

    my $value = shift || croak 'Value must be provided';
    $value =~ /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
}

sub looks_like_ipv6 {

    my $value = shift || croak 'Value must be provided';
    $value =~ /^(?:[A-F0-9]{1,4}:){7}[A-F0-9]{1,4}$/i;
}

1;
