package DNSQuery::Validator;
use strict;
use warnings;
use Exporter 'import';
use DNSQuery::Constants qw(:all);

our $VERSION = '1.1.0';

our @EXPORT_OK = qw(
    validate_domain
    validate_ip
    validate_query_type
    validate_query_class
    validate_port
    validate_timeout
    validate_retries
    validate_file_path
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

=head1 NAME

DNSQuery::Validator - Input validation for DNSQuery

=head1 SYNOPSIS

    use DNSQuery::Validator qw(:all);
    
    my ($valid, $error) = validate_domain($domain);
    die $error unless $valid;

=head1 DESCRIPTION

Provides validation functions for DNS queries and configuration.
All validation functions return a list: (success_boolean, error_message).

=head1 FUNCTIONS

=head2 validate_domain($domain)

Validates a domain name according to RFC 1035.

Returns: (1, undef) on success, (0, error_message) on failure.

=cut

sub validate_domain {
    my ($domain) = @_;
    
    return (0, "Domain name is required") 
        unless defined $domain && length($domain) > 0;
    
    # Trim whitespace
    $domain =~ s/^\s+|\s+$//g;
    
    return (0, "Domain name too long (max $MAX_DOMAIN_LENGTH characters)")
        if length($domain) > $MAX_DOMAIN_LENGTH;
    
    return (0, "Domain name contains consecutive dots")
        if $domain =~ /\.\./;
    
    return (0, "Domain name cannot start with hyphen")
        if $domain =~ /^-/;
    
    return (0, "Domain name cannot end with hyphen")
        if $domain =~ /-$/;
    
    # Validate each label
    my @labels = split(/\./, $domain);
    for my $label (@labels) {
        return (0, "Label cannot be empty")
            if length($label) == 0;
        
        return (0, "Label too long (max $MAX_LABEL_LENGTH characters): $label")
            if length($label) > $MAX_LABEL_LENGTH;
        
        return (0, "Invalid label format: $label")
            unless $label =~ /^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?$/;
    }
    
    return (1, undef);
}

=head2 validate_ip($ip)

Validates an IPv4 or IPv6 address.

Returns: (1, undef) on success, (0, error_message) on failure.

=cut

sub validate_ip {
    my ($ip) = @_;
    
    return (0, "IP address is required")
        unless defined $ip && length($ip) > 0;
    
    # IPv6 validation
    if ($ip =~ /:/) {
        return (0, "Invalid IPv6 address format")
            unless $ip =~ /^[0-9a-fA-F:]+$/ && $ip =~ /:/;
        
        # Basic IPv6 structure check
        my @parts = split(/:/, $ip);
        return (0, "Invalid IPv6 address structure")
            if @parts > 8;
        
        return (1, undef);
    }
    
    # IPv4 validation
    return (0, "Invalid IPv4 address format")
        unless $ip =~ /^(\d{1,3}\.){3}\d{1,3}$/;
    
    my @octets = split(/\./, $ip);
    for my $octet (@octets) {
        return (0, "Invalid IPv4 octet: $octet (must be 0-255)")
            if $octet > 255;
    }
    
    return (1, undef);
}

=head2 validate_query_type($type)

Validates a DNS query type.

Returns: (1, undef) on success, (0, error_message) on failure.

=cut

sub validate_query_type {
    my ($type) = @_;
    
    return (0, "Query type is required")
        unless defined $type && length($type) > 0;
    
    $type = uc($type);
    
    return (0, "Invalid query type: $type")
        unless $VALID_QUERY_TYPES{$type};
    
    return (1, undef);
}

=head2 validate_query_class($class)

Validates a DNS query class.

Returns: (1, undef) on success, (0, error_message) on failure.

=cut

sub validate_query_class {
    my ($class) = @_;
    
    return (0, "Query class is required")
        unless defined $class && length($class) > 0;
    
    my $uc_class = uc($class);
    
    return (0, "Invalid query class: $class")
        unless $VALID_QUERY_CLASSES{$uc_class};
    
    return (1, undef);
}

=head2 validate_port($port)

Validates a network port number.

Returns: (1, undef) on success, (0, error_message) on failure.

=cut

sub validate_port {
    my ($port) = @_;
    
    return (0, "Port is required")
        unless defined $port;
    
    return (0, "Port must be numeric")
        unless $port =~ /^\d+$/;
    
    return (0, "Port must be between $MIN_PORT and $MAX_PORT")
        if $port < $MIN_PORT || $port > $MAX_PORT;
    
    return (1, undef);
}

=head2 validate_timeout($timeout)

Validates a timeout value in seconds.

Returns: (1, undef) on success, (0, error_message) on failure.

=cut

sub validate_timeout {
    my ($timeout) = @_;
    
    return (0, "Timeout is required")
        unless defined $timeout;
    
    return (0, "Timeout must be numeric")
        unless $timeout =~ /^\d+$/;
    
    return (0, "Timeout must be at least $MIN_TIMEOUT second(s)")
        if $timeout < $MIN_TIMEOUT;
    
    return (1, undef);
}

=head2 validate_retries($retries)

Validates a retry count.

Returns: (1, undef) on success, (0, error_message) on failure.

=cut

sub validate_retries {
    my ($retries) = @_;
    
    return (0, "Retries value is required")
        unless defined $retries;
    
    return (0, "Retries must be numeric")
        unless $retries =~ /^\d+$/;
    
    return (0, "Retries must be at least $MIN_RETRIES")
        if $retries < $MIN_RETRIES;
    
    return (1, undef);
}

=head2 validate_file_path($path, $must_exist)

Validates a file path for batch processing.

If $must_exist is true, checks that the file exists and is readable.

Returns: (1, undef) on success, (0, error_message) on failure.

=cut

sub validate_file_path {
    my ($path, $must_exist) = @_;
    
    return (0, "File path is required")
        unless defined $path && length($path) > 0;
    
    return (1, undef) unless $must_exist;
    
    return (0, "File does not exist: $path")
        unless -e $path;
    
    return (0, "Not a regular file: $path")
        unless -f $path;
    
    return (0, "File is not readable: $path")
        unless -r $path;
    
    my $size = -s $path;
    return (0, "File is empty: $path")
        if $size == 0;
    
    return (0, "File too large (max " . int($MAX_BATCH_FILE_SIZE / 1_000_000) . "MB): $path")
        if $size > $MAX_BATCH_FILE_SIZE;
    
    return (1, undef);
}

1;

__END__

=head1 AUTHOR

DNSQuery Project

=head1 LICENSE

MIT License

=cut
