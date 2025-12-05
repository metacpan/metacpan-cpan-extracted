# DNSQuery Usage Guide - New Features

## Smart Caching

### TTL-Aware Caching
The cache now respects DNS record TTL values instead of using a fixed expiration time.

```perl
# Cache automatically uses TTL from DNS responses
my $resolver = DNSQuery::Resolver->new(\%config);
my $result = $resolver->query('google.com');  # Cached based on actual TTL
```

### Cache Persistence
Enable disk persistence to maintain cache across restarts:

```perl
my %config = (
    # ... other config ...
    cache_persist => 1,  # Enable persistence
    cache_size => 200,   # Increase cache size
);

my $resolver = DNSQuery::Resolver->new(\%config);
```

Cache file location: `/tmp/dnsq_cache_<uid>.dat`

### Cache Statistics
View detailed cache statistics in interactive mode:

```bash
$ bin/dnsq --interactive
dnsq> google.com
dnsq> example.com
dnsq> stats

Current settings:
  # ... settings ...

Query Statistics:
  Total queries: 2
  Cache hits: 0 (0.0%)
  Failed queries: 0
  Avg query time: 15.0 ms
```

### Cache Management
Clear cache in interactive mode:

```bash
dnsq> clear cache
Cache cleared
```

## Input Validation

### Comprehensive Validation
All inputs are now validated with clear error messages:

```bash
# Invalid domain
$ bin/dnsq invalid..domain.com
Error: Domain name contains consecutive dots

# Invalid query type
$ bin/dnsq google.com INVALID
Error: Invalid query type: INVALID

# Invalid port
$ bin/dnsq -p 99999 google.com
Error: Port must be between 1 and 65535
```

### Batch File Validation
Batch files are validated line-by-line with helpful warnings:

```bash
$ bin/dnsq --batch queries.txt
Warning: Line 5: Domain name contains consecutive dots, skipping
Warning: Line 12: Invalid query type 'BADTYPE', skipping
Warning: Skipped 2 invalid entries
;; Batch complete: 10 queries, 0 failed, 0.15s (66.7 q/s)
```

## Module Usage

### Using the Validator Module

```perl
use DNSQuery::Validator qw(:all);

# Validate domain
my ($valid, $error) = validate_domain('example.com');
die $error unless $valid;

# Validate IP address
($valid, $error) = validate_ip('8.8.8.8');
die $error unless $valid;

# Validate query type
($valid, $error) = validate_query_type('MX');
die $error unless $valid;
```

### Using the Cache Module

```perl
use DNSQuery::Cache;

# Create cache
my $cache = DNSQuery::Cache->new(
    max_size => 100,
    persist => 1,
    cache_file => '/path/to/cache.dat',
);

# Store with TTL
$cache->set('key', $value, 300);  # 300 second TTL

# Retrieve
my $value = $cache->get('key');

# Statistics
my $stats = $cache->get_stats();
print "Hit rate: $stats->{hit_rate}%\n";

# Cleanup
$cache->cleanup_expired();
$cache->clear();
```

### Using Constants

```perl
use DNSQuery::Constants qw(:all);

# Check valid query types
if ($VALID_QUERY_TYPES{$type}) {
    # valid
}

# Use limits
die "Port out of range" if $port < $MIN_PORT || $port > $MAX_PORT;

# DNS limits
die "Domain too long" if length($domain) > $MAX_DOMAIN_LENGTH;
```

## Performance Tips

### Batch Processing
For large batch files, the tool automatically uses parallel processing when available:

```bash
# Install Parallel::ForkManager for parallel processing
$ cpanm Parallel::ForkManager

# Process large batch file
$ bin/dnsq --batch large_queries.txt
;; Using parallel processing with 10 workers
Progress: 1000/1000 (100%)...
;; Batch complete: 1000 queries, 0 failed, 15.23s (65.7 q/s)
```

### Cache Tuning
Adjust cache size based on your usage:

```perl
# For high-volume queries
my %config = (
    cache_size => 500,      # Larger cache
    cache_persist => 1,     # Persist across runs
);
```

### Interactive Mode Efficiency
Use interactive mode for multiple queries to benefit from caching:

```bash
$ bin/dnsq --interactive
dnsq> google.com
# ... result ...
dnsq> google.com MX
# ... result (domain cached) ...
dnsq> google.com AAAA
# ... result (domain cached) ...
```

## Error Handling

### Validation Errors
All validation errors are caught early with clear messages:

```perl
use DNSQuery::Validator qw(validate_domain);

my ($valid, $error) = validate_domain($user_input);
if (!$valid) {
    print "Invalid domain: $error\n";
    # Handle error appropriately
}
```

### Query Errors
Query errors are handled gracefully:

```bash
# JSON mode includes errors
$ bin/dnsq --json nonexistent.invalid
{"error":"Query failed: NXDOMAIN","domain":"nonexistent.invalid","type":"A"}

# Normal mode prints to stderr
$ bin/dnsq nonexistent.invalid
Query failed: NXDOMAIN
```

## Best Practices

### 1. Use Validation Early
Validate user input before passing to resolver:

```perl
my ($valid, $error) = validate_domain($domain);
die "Invalid domain: $error\n" unless $valid;
```

### 2. Enable Caching for Repeated Queries
For applications that query the same domains repeatedly:

```perl
my %config = (
    cache_size => 200,
    cache_persist => 1,
);
```

### 3. Use Batch Mode for Multiple Queries
Instead of running multiple commands:

```bash
# Create batch file
echo "google.com" > queries.txt
echo "example.com" >> queries.txt
echo "github.com" >> queries.txt

# Process in batch
bin/dnsq --batch queries.txt --json > results.json
```

### 4. Monitor Cache Performance
In long-running applications, check cache statistics:

```perl
my $stats = $resolver->get_stats();
if ($stats->{cache_hit_rate} < 20) {
    # Consider increasing cache size
}
```

### 5. Clean Up Expired Entries
For long-running processes with persistence:

```perl
# Periodically clean up
$resolver->{cache}->cleanup_expired();
```

## Migration from Old Version

### No Breaking Changes
All existing code continues to work:

```perl
# Old code still works
my $resolver = DNSQuery::Resolver->new(\%config);
my $result = $resolver->query('google.com');
```

### Optional Enhancements
Add new features incrementally:

```perl
# Add caching
$config{cache_size} = 200;
$config{cache_persist} = 1;

# Use validation
use DNSQuery::Validator qw(validate_domain);
my ($valid, $error) = validate_domain($domain);
```

## Troubleshooting

### Cache Not Persisting
Check file permissions:

```bash
$ ls -la /tmp/dnsq_cache_*.dat
```

### Validation Too Strict
The validator follows RFC 1035 strictly. If you need to query non-standard domains, you may need to bypass validation (not recommended).

### Performance Issues
- Increase cache size for better hit rates
- Enable parallel processing for batch mode
- Use shorter timeouts for faster failures

## Examples

### Example 1: High-Performance DNS Checker

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use DNSQuery::Resolver;
use DNSQuery::Validator qw(validate_domain);

my %config = (
    timeout => 2,
    retries => 1,
    cache_size => 500,
    cache_persist => 1,
);

my $resolver = DNSQuery::Resolver->new(\%config);

foreach my $domain (@ARGV) {
    my ($valid, $error) = validate_domain($domain);
    unless ($valid) {
        warn "Skipping invalid domain: $error\n";
        next;
    }
    
    my $result = $resolver->query($domain);
    if ($result->{error}) {
        print "$domain: FAILED\n";
    } else {
        print "$domain: OK\n";
    }
}

# Show statistics
my $stats = $resolver->get_stats();
printf "Cache hit rate: %.1f%%\n", $stats->{cache_hit_rate};
```

### Example 2: Domain Validator

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use DNSQuery::Validator qw(:all);

while (my $domain = <STDIN>) {
    chomp $domain;
    my ($valid, $error) = validate_domain($domain);
    
    if ($valid) {
        print "✓ $domain\n";
    } else {
        print "✗ $domain: $error\n";
    }
}
```

### Example 3: Cache Statistics Monitor

```perl
#!/usr/bin/env perl
use strict;
use warnings;
use DNSQuery::Cache;

my $cache = DNSQuery::Cache->new(
    persist => 1,
    cache_file => '/tmp/my_cache.dat',
);

# Load existing cache
my $stats = $cache->get_stats();

print "Cache Statistics:\n";
print "  Size: $stats->{size} / $stats->{max_size}\n";
print "  Hits: $stats->{hits}\n";
print "  Misses: $stats->{misses}\n";
print "  Hit Rate: $stats->{hit_rate}%\n";
print "  Evictions: $stats->{evictions}\n";

# Cleanup expired entries
my $removed = $cache->cleanup_expired();
print "\nRemoved $removed expired entries\n";
```
