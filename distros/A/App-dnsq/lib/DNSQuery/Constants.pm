package DNSQuery::Constants;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = '1.1.0';

our @EXPORT_OK = qw(
    %VALID_QUERY_TYPES
    %VALID_QUERY_CLASSES
    $MIN_PORT $MAX_PORT
    $MIN_TIMEOUT $MIN_RETRIES
    $MAX_DOMAIN_LENGTH $MAX_LABEL_LENGTH
    $DEFAULT_CACHE_TTL $MAX_CACHE_SIZE
    $MAX_BATCH_FILE_SIZE
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
    types => [qw(%VALID_QUERY_TYPES %VALID_QUERY_CLASSES)],
    limits => [qw($MIN_PORT $MAX_PORT $MIN_TIMEOUT $MIN_RETRIES)],
    dns => [qw($MAX_DOMAIN_LENGTH $MAX_LABEL_LENGTH)],
    cache => [qw($DEFAULT_CACHE_TTL $MAX_CACHE_SIZE)],
);

# DNS Query Types (RFC 1035 and extensions)
our %VALID_QUERY_TYPES = map { $_ => 1 } qw(
    A AAAA CNAME MX NS PTR SOA TXT SRV CAA 
    DNSKEY DS RRSIG NSEC NSEC3 TLSA ANY
);

# DNS Query Classes
our %VALID_QUERY_CLASSES = map { $_ => 1 } qw(IN CH HS);

# Network limits
our $MIN_PORT = 1;
our $MAX_PORT = 65535;

# Query limits
our $MIN_TIMEOUT = 1;
our $MIN_RETRIES = 0;

# DNS specification limits (RFC 1035)
our $MAX_DOMAIN_LENGTH = 253;
our $MAX_LABEL_LENGTH = 63;

# Cache configuration
our $DEFAULT_CACHE_TTL = 60;  # seconds
our $MAX_CACHE_SIZE = 100;    # entries

# Batch processing limits
our $MAX_BATCH_FILE_SIZE = 10_000_000;  # 10MB

1;

__END__

=head1 NAME

DNSQuery::Constants - Shared constants for DNSQuery

=head1 SYNOPSIS

    use DNSQuery::Constants qw(:all);
    
    if ($VALID_QUERY_TYPES{$type}) {
        # valid type
    }

=head1 DESCRIPTION

This module provides shared constants used throughout the DNSQuery application.

=head1 EXPORTS

=head2 Export Tags

=over 4

=item :all - Export all constants

=item :types - Export query type and class hashes

=item :limits - Export port and timeout limits

=item :dns - Export DNS specification limits

=item :cache - Export cache configuration

=back

=cut
