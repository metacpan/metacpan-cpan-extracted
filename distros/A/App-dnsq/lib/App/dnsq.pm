package App::dnsq;

use strict;
use warnings;

our $VERSION = '1.1.0';

=head1 NAME

App::dnsq - A full-featured dig-like DNS query tool

=head1 VERSION

Version 1.1.0

=head1 SYNOPSIS

    # Command line usage
    dnsq google.com
    dnsq --json --short example.com
    dnsq --batch queries.txt
    dnsq --interactive

    # Programmatic usage
    use DNSQuery::Resolver;
    use DNSQuery::Output;
    
    my %config = (
        server   => '8.8.8.8',
        timeout  => 5,
        retries  => 3,
        protocol => 'udp',
    );
    
    my $resolver = DNSQuery::Resolver->new(\%config);
    my $result = $resolver->query('google.com', 'A');

=head1 DESCRIPTION

App::dnsq is a full-featured DNS query tool written in Perl, providing a modern
alternative to dig with additional features like JSON output, smart caching,
batch processing, and interactive mode.

=head1 FEATURES

=over 4

=item * Multiple output formats (full dig-like, short, JSON)

=item * TCP and UDP protocol support

=item * Custom DNS server with configurable port

=item * Configurable timeout and retry settings with exponential backoff

=item * Batch mode with parallel processing support

=item * Trace mode to follow DNS delegation path

=item * Interactive shell with statistics

=item * DNSSEC support

=item * Smart caching with TTL awareness and optional disk persistence

=item * Comprehensive input validation

=item * Progress indicators for batch operations

=back

=head1 INSTALLATION

    cpan App::dnsq

Or manually:

    perl Makefile.PL
    make
    make test
    make install

=head1 COMMAND LINE OPTIONS

=over 4

=item B<-s, --server E<lt>ipE<gt>>

DNS server to query

=item B<-p, --port E<lt>portE<gt>>

DNS server port (default: 53)

=item B<-t, --timeout E<lt>secE<gt>>

Query timeout in seconds (default: 5)

=item B<-r, --retries E<lt>numE<gt>>

Number of retries (default: 3)

=item B<-T, --tcp>

Use TCP protocol

=item B<-U, --udp>

Use UDP protocol (default)

=item B<-j, --json>

Output in JSON format

=item B<-S, --short>

Short output (answers only)

=item B<--trace>

Trace DNS delegation path

=item B<-b, --batch E<lt>fileE<gt>>

Batch mode - process queries from file

=item B<-i, --interactive>

Interactive mode

=item B<-d, --dnssec>

Request DNSSEC records

=item B<-v, --verbose>

Verbose output

=item B<-Q, --quiet>

Quiet mode (no banners)

=item B<-h, --help>

Show help message

=item B<-V, --version>

Show version

=back

=head1 EXAMPLES

    # Basic query
    dnsq google.com
    
    # Query specific record type
    dnsq google.com MX
    
    # Use custom DNS server
    dnsq -s 8.8.8.8 example.com
    
    # JSON output
    dnsq --json google.com
    
    # Short output (answers only)
    dnsq --short google.com
    
    # Use TCP
    dnsq --tcp google.com
    
    # Trace DNS delegation
    dnsq --trace example.com
    
    # Batch mode
    dnsq --batch queries.txt
    
    # Interactive mode
    dnsq --interactive

=head1 MODULES

=head2 DNSQuery::Resolver

Core DNS resolution with caching and statistics.

=head2 DNSQuery::Validator

Input validation for domains, IPs, and query parameters.

=head2 DNSQuery::Cache

Smart caching with TTL support and optional persistence.

=head2 DNSQuery::Constants

Shared constants for query types and limits.

=head2 DNSQuery::Output

Output formatting (full, short, JSON).

=head2 DNSQuery::Batch

Batch processing with parallel support.

=head2 DNSQuery::Interactive

Interactive shell mode.

=head1 DEPENDENCIES

=over 4

=item * Net::DNS >= 1.0

=item * JSON >= 2.0

=item * Time::HiRes

=item * Term::ReadLine

=item * Storable

=item * File::Spec

=back

=head2 Optional Dependencies

=over 4

=item * Parallel::ForkManager >= 2.0 (for parallel batch processing)

=back

=head1 REPOSITORY

L<https://github.com/bl4ckstack/dnsq>

=head1 BUGS

Please report bugs at L<https://github.com/bl4ckstack/dnsq/issues>

=head1 AUTHOR

Isaac Caldwell

=head1 LICENSE

MIT License

Copyright (c) 2025 Isaac Caldwell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 SEE ALSO

L<dig(1)>, L<host(1)>, L<nslookup(1)>, L<Net::DNS>

=cut

1;
