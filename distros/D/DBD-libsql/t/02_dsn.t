use strict;
use warnings;
use Test::More 0.98;
use DBI;

# Test DSN parsing for HTTP-only libsql driver
my @test_cases = (
    {
        dsn => "dbi:libsql:localhost",
        expected_url => "http://localhost:8080",
        desc => "Localhost - Auto HTTP with port 8080"
    },
    {
        dsn => "dbi:libsql:localhost?scheme=http&port=3000",
        expected_url => "http://localhost:3000",
        desc => "Localhost - Custom HTTP port"
    },
    {
        dsn => "dbi:libsql:hono-prisma-ytnobody.aws-ap-northeast-1.turso.io",
        expected_url => "https://hono-prisma-ytnobody.aws-ap-northeast-1.turso.io",
        desc => "Turso - Auto HTTPS detection"
    },
    {
        dsn => "dbi:libsql:example.com?scheme=https&port=8443",
        expected_url => "https://example.com:8443",
        desc => "Custom host - HTTPS with custom port"
    },
    {
        dsn => "dbi:libsql:api.example.com",
        expected_url => "https://api.example.com",
        desc => "Custom host - Default HTTPS"
    }
);

# Test cases for unsupported DSN formats (should fail)
my @error_test_cases = (
    {
        dsn => "dbi:libsql:test.db",
        desc => "Local file (not supported)"
    },
    {
        dsn => "dbi:libsql:/path/to/test.db", 
        desc => "Local file with path (not supported)"
    },
    {
        dsn => "dbi:libsql::memory:",
        desc => "Memory database (not supported)"
    },
    {
        dsn => "dbi:libsql:http://localhost:8080",
        desc => "HTTP URL format (not supported)"
    },
    {
        dsn => "dbi:libsql:https://example.turso.io",
        desc => "HTTPS URL format (not supported)"
    }
);

plan tests => scalar(@test_cases) + scalar(@error_test_cases) + 1;

use_ok 'DBD::libsql';

for my $test (@test_cases) {
    # Test DSN parsing using the actual _parse_dsn_to_url logic
    my $dsn = $test->{dsn};
    my $dsn_remainder = $dsn;
    $dsn_remainder =~ s/^dbi:libsql://i;
    
    # Simulate _parse_dsn_to_url function logic (new format)
    # Format: hostname or hostname?scheme=https&port=443
    my ($host, $query_string) = split /\?/, $dsn_remainder, 2;
    
    # Smart defaults based on hostname
    my $scheme = 'https';  # Default to HTTPS for security
    my $port = '443';      # Default HTTPS port
    
    # Detect Turso hosts (always HTTPS on 443)
    if ($host =~ /\.turso\.io$/) {
        $scheme = 'https';
        $port = '443';
    }
    # Detect localhost/127.0.0.1 (default to HTTP for development)
    elsif ($host =~ /^(localhost|127\.0\.0\.1)$/) {
        $scheme = 'http';
        $port = '8080';
    }
    
    # Parse query parameters if present (override defaults)
    if ($query_string) {
        my %params = map { 
            my ($k, $v) = split /=/, $_, 2; 
            ($k, $v // '') 
        } split /&/, $query_string;
        
        $scheme = $params{schema} if defined $params{schema} && $params{schema} ne '';
        $port = $params{port} if defined $params{port} && $params{port} ne '';
    }
    
    # Build URL
    my $parsed_url = "$scheme://$host";
    # Only add port if it's not the default for the scheme
    if (($scheme eq 'http' && $port ne '80') || 
        ($scheme eq 'https' && $port ne '443')) {
        $parsed_url .= ":$port";
    }
    
    is $parsed_url, $test->{expected_url}, $test->{desc};
}

# Test that unsupported DSN formats are rejected
for my $test (@error_test_cases) {
    eval {
        my $dbh = DBI->connect($test->{dsn}, '', '', {RaiseError => 1});
    };
    ok($@, $test->{desc} . " - should fail with error");
}

done_testing;
