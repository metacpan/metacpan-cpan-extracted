# dnsq

[![Perl](https://img.shields.io/badge/Perl-5.10%2B-blue)](https://www.perl.org/)  
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)  
[![Version](https://img.shields.io/badge/Version-1.1.0-orange)](bin/dnsq)


A full-featured dig-like DNS query tool written in Perl with JSON output, TCP/UDP support, trace mode, and batch processing.

## Features

- **Multiple Output Formats**: Full dig-like, short (answers only), or JSON
- **Protocol Support**: TCP and UDP
- **Custom DNS Server**: Query any DNS server with custom port
- **Timeout & Retries**: Configurable timeout and retry settings with exponential backoff
- **Batch Mode**: Process multiple queries from a file with parallel processing
- **Trace Mode**: Follow DNS delegation path from root servers
- **Interactive Mode**: Interactive shell with ASCII art banner and statistics
- **DNSSEC Support**: Request and display DNSSEC records
- **Smart Caching**: TTL-aware cache with optional disk persistence
- **Statistics Tracking**: Monitor query performance and cache hit rates
- **Progress Indicators**: Real-time progress for batch operations
- **Input Validation**: Comprehensive validation for domains, IPs, and query types

## Installation

### From CPAN

```bash
# Install from CPAN (recommended)
cpan App::dnsq

# Or using cpanm
cpanm App::dnsq
```

### From Source

```bash
# Clone the repository
git clone https://github.com/bl4ckstack/dnsq.git
cd dnsq

# Install dependencies
cpanm --installdeps .

# Build and install
perl Makefile.PL
make
make test
make install
```

### Manual Installation

```bash
# Install dependencies manually
cpan Net::DNS JSON Term::ReadLine Storable File::Spec

# Optional: For parallel batch processing
cpan Parallel::ForkManager

# Make executable
chmod +x bin/dnsq
```

## Usage

```bash
# Basic query
bin/dnsq google.com

# Query specific record type
bin/dnsq google.com MX

# Use custom DNS server
bin/dnsq -s 8.8.8.8 example.com

# JSON output
bin/dnsq --json google.com

# Short output (answers only)
bin/dnsq --short google.com

# Use TCP
bin/dnsq --tcp google.com

# Trace DNS delegation
bin/dnsq --trace example.com

# Batch mode
bin/dnsq --batch examples/queries.txt

# Interactive mode
bin/dnsq --interactive
```

## Options

| Option | Description |
|--------|-------------|
| `-s, --server <ip>` | DNS server to query |
| `-p, --port <port>` | DNS server port (default: 53) |
| `-t, --timeout <sec>` | Query timeout (default: 5) |
| `-r, --retries <num>` | Number of retries (default: 3) |
| `-T, --tcp` | Use TCP protocol |
| `-j, --json` | JSON output |
| `-S, --short` | Short output (answers only) |
| `--trace` | Trace DNS delegation |
| `-b, --batch <file>` | Batch mode |
| `-i, --interactive` | Interactive mode |
| `-d, --dnssec` | Request DNSSEC |
| `-v, --verbose` | Verbose output |
| `-Q, --quiet` | Quiet mode (no banners) |
| `-h, --help` | Show help |

## Examples

```bash
# Get all A records as JSON
bin/dnsq --json --short google.com A

# Verify DNS propagation
bin/dnsq -s 8.8.8.8 example.com      # Google DNS
bin/dnsq -s 1.1.1.1 example.com      # Cloudflare DNS

# Batch processing
bin/dnsq --batch examples/queries.txt --json > results.json

# Interactive session with statistics
bin/dnsq --interactive
dnsq> google.com
dnsq> example.com MX
dnsq> set server 8.8.8.8
dnsq> stats
dnsq> quit
```

