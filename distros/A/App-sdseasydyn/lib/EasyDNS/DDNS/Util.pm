package EasyDNS::DDNS::Util;

use strict;
use warnings;

sub trim {
    my ($s) = @_;
    return '' if !defined $s;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    return $s;
}

sub redact_basic_auth_in_url {
    my ($url) = @_;
    return '' if !defined $url;

    # Redact user:pass@ in URL authority.
    # Examples:
    #   https://user:token@host/path  -> https://user:***@host/path
    #   http://user:pass@host        -> http://user:***@host
    $url =~ s{(https?://)([^:/\@]+):([^@\s]+)\@}{$1$2:***@}ig;
    return $url;
}

sub redact_header_value {
    my ($name, $value) = @_;
    return $value if !defined $name;

    my $n = lc $name;
    return '***' if $n eq 'authorization';
    return $value;
}

1;

__END__

=pod

=head1 NAME

EasyDNS::DDNS::Util - Small utilities (trimming, redaction)

=head1 DESCRIPTION

Utility helpers used across the project. Redaction helpers are intended
to prevent accidental disclosure of secrets in logs and diagnostics.

=cut

