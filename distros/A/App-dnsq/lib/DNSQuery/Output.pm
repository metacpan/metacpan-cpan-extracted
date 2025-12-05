package DNSQuery::Output;
use strict;
use warnings;
use JSON;

our $VERSION = '1.1.0';

sub new {
    my ($class, $config) = @_;
    return bless { config => $config }, $class;
}

sub print_result {
    my ($self, $result, $domain) = @_;
    
    unless ($result && ref($result) eq 'HASH') {
        warn "Invalid result object\n";
        return;
    }
    
    return unless $result->{packet};
    
    eval {
        if ($self->{config}{json}) {
            $self->print_json($result, $domain);
        } elsif ($self->{config}{short}) {
            $self->print_short($result->{packet});
        } else {
            $self->print_full($result, $domain);
        }
    };
    
    if ($@) {
        warn "Error printing result: $@\n";
    }
}

sub print_full {
    my ($self, $result, $domain) = @_;
    
    # Validate inputs
    return unless defined $result && ref($result) eq 'HASH';
    return unless defined $domain && length($domain) > 0;
    return unless $result->{packet};
    
    my $packet = $result->{packet};
    my $config = $self->{config};
    
    my $header = eval { $packet->header };
    return unless $header;
    
    # dig-style header
    print "\n; <<>> dnsq <<>> $domain";
    print " $config->{qtype}" if $config->{qtype} ne 'A';
    print "\n";
    print ";; global options: +cmd\n";
    
    # Status line - dig format
    my @flags;
    push @flags, 'qr' if $header->qr;
    push @flags, 'aa' if $header->aa;
    push @flags, 'tc' if $header->tc;
    push @flags, 'rd' if $header->rd;
    push @flags, 'ra' if $header->ra;
    push @flags, 'ad' if $header->ad;
    push @flags, 'cd' if $header->cd;
    
    printf ";; Got answer:\n";
    printf ";; ->>HEADER<<- opcode: QUERY, status: %s, id: %d\n", 
        $header->rcode, $header->id;
    printf ";; flags: %s; QUERY: %d, ANSWER: %d, AUTHORITY: %d, ADDITIONAL: %d\n",
        join(' ', @flags), $header->qdcount, $header->ancount, 
        $header->nscount, $header->arcount;
    
    # DNSSEC status (if applicable)
    if ($header->ad) {
        print ";; flags: ad; DNSSEC validation successful\n";
    }
    
    print "\n";
    
    # Question section (dig-style)
    print ";; QUESTION SECTION:\n";
    printf ";%-30s %-7s %s\n", $domain . ".", $config->{qclass}, $config->{qtype};
    print "\n";
    
    # Answer section (most important)
    if ($header->ancount > 0) {
        print ";; ANSWER SECTION:\n";
        my @answers = eval { $packet->answer };
        if ($@) {
            print ";; Error parsing answer section: $@\n\n";
        } else {
            foreach my $rr (@answers) {
                next unless defined $rr;
                
                my $rr_string = eval { $rr->string };
                if ($@) {
                    print ";; [Error displaying record: $@]\n";
                    next;
                }
                print "$rr_string\n";
                
                # Add technical info for records
                my $tech_info = $self->get_record_technical_info($rr);
                if ($tech_info) {
                    foreach my $info (@$tech_info) {
                        print ";; $info\n";
                    }
                }
            }
            print "\n";
        }
    }
    
    # Authority section (only if present and verbose)
    if ($header->nscount > 0 && $config->{verbose}) {
        print ";; AUTHORITY SECTION:\n";
        my @authority = eval { $packet->authority };
        if (!$@) {
            foreach my $rr (@authority) {
                next unless defined $rr;
                my $rr_string = eval { $rr->string };
                print "$rr_string\n" if $rr_string && !$@;
            }
        }
        print "\n";
    }
    
    # Additional section (only if verbose)
    if ($header->arcount > 0 && $config->{verbose}) {
        print ";; ADDITIONAL SECTION:\n";
        my @additional = eval { $packet->additional };
        if (!$@) {
            foreach my $rr (@additional) {
                next unless defined $rr;
                next if eval { $rr->type eq 'OPT' };  # Skip EDNS
                my $rr_string = eval { $rr->string };
                print "$rr_string\n" if $rr_string && !$@;
            }
        }
        print "\n";
    }
    
    # dig-style query statistics
    my $query_time = $result->{query_time} || 0;
    my $packet_size = eval { length($packet->data) } || 0;
    
    print ";; Query time: $query_time msec\n";
    
    # Server information
    my $server_addr = $config->{server} || '127.0.0.1';
    my $port = $config->{port} || 53;
    printf ";; SERVER: %s#%d(%s)\n", $server_addr, $port, $server_addr;
    
    # Timestamp
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $year += 1900;
    $mon += 1;
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    printf ";; WHEN: %s %02d %02d:%02d:%02d %d\n", 
        $months[$mon-1], $mday, $hour, $min, $sec, $year;
    
    # Message size
    printf ";; MSG SIZE  rcvd: %d\n", $packet_size;
    
    # Advanced technical information
    my @tech_info;
    
    # Cache status
    if ($result->{cached}) {
        push @tech_info, "Result from local cache";
    }
    
    # Retry information
    if ($result->{attempts} && $result->{attempts} > 1) {
        push @tech_info, sprintf("Query retried %d time(s)", $result->{attempts} - 1);
    }
    
    # EDNS information
    my @additional = eval { $packet->additional };
    if (!$@) {
        foreach my $rr (@additional) {
            if (eval { $rr->type eq 'OPT' }) {
                # Try different methods to get UDP size
                my $udp_size = 0;
                if ($rr->can('udpsize')) {
                    $udp_size = eval { $rr->udpsize } || 0;
                } elsif ($rr->can('size')) {
                    # Suppress warnings for deprecated method
                    local $SIG{__WARN__} = sub {};
                    $udp_size = eval { $rr->size } || 0;
                }
                
                my $version = eval { $rr->version } || 0;
                my $do_flag = eval { $rr->do } || 0;
                
                if ($udp_size > 0) {
                    my $edns_info = sprintf("EDNS: version %d, udp=%d", $version, $udp_size);
                    $edns_info .= ", flags: do" if $do_flag;
                    push @tech_info, $edns_info;
                }
                last;
            }
        }
    }
    
    # Response analysis
    my $response_analysis = $self->analyze_response($packet, $domain);
    push @tech_info, @$response_analysis if $response_analysis;
    
    # Print technical information
    if (@tech_info) {
        print ";;\n";
        foreach my $info (@tech_info) {
            print ";; $info\n";
        }
    }
    
    print "\n";
}

sub get_record_technical_info {
    my ($self, $rr) = @_;
    
    return undef unless defined $rr;
    
    my @info;
    my $type = eval { $rr->type };
    return undef unless $type && !$@;
    
    # A/AAAA record analysis
    if ($type eq 'A' || $type eq 'AAAA') {
        my $ip = eval { $rr->address };
        if ($ip && !$@) {
            my $classification = $self->classify_ip($ip);
            push @info, $classification if $classification;
            
            # TTL analysis
            my $ttl = eval { $rr->ttl };
            if (defined $ttl && !$@) {
                my $ttl_analysis = $self->analyze_ttl($ttl);
                push @info, $ttl_analysis if $ttl_analysis;
            }
        }
    }
    # MX record analysis
    elsif ($type eq 'MX') {
        my $preference = eval { $rr->preference };
        if (defined $preference && !$@) {
            if ($preference < 10) {
                push @info, "High priority mail server (preference: $preference)";
            } elsif ($preference >= 50) {
                push @info, "Backup mail server (preference: $preference)";
            }
        }
    }
    # CNAME analysis
    elsif ($type eq 'CNAME') {
        push @info, "CNAME chain detected - may add latency to resolution";
    }
    # TXT record analysis
    elsif ($type eq 'TXT') {
        my $txt = eval { $rr->txtdata };
        if ($txt && !$@) {
            if ($txt =~ /^v=spf1/i) {
                push @info, "SPF record detected - email sender authentication";
            } elsif ($txt =~ /^v=DKIM1/i) {
                push @info, "DKIM record detected - email signature verification";
            } elsif ($txt =~ /^v=DMARC1/i) {
                push @info, "DMARC record detected - email authentication policy";
            }
        }
    }
    # SOA record analysis
    elsif ($type eq 'SOA') {
        my $serial = eval { $rr->serial };
        my $refresh = eval { $rr->refresh };
        my $retry = eval { $rr->retry };
        my $expire = eval { $rr->expire };
        
        if (defined $serial && !$@) {
            push @info, "Zone serial: $serial";
        }
        if (defined $refresh && !$@) {
            push @info, sprintf("Refresh interval: %d seconds (%s)", $refresh, $self->format_time($refresh));
        }
    }
    
    return @info ? \@info : undef;
}

sub classify_ip {
    my ($self, $ip) = @_;
    
    return undef unless defined $ip && length($ip) > 0;
    
    # Handle IPv6
    if ($ip =~ /:/) {
        if ($ip =~ /^fe80:/i) {
            return "IPv6 link-local address (fe80::/10)";
        } elsif ($ip =~ /^fc00:/i || $ip =~ /^fd00:/i) {
            return "IPv6 unique local address (fc00::/7)";
        } elsif ($ip =~ /^::1$/) {
            return "IPv6 loopback address";
        } elsif ($ip =~ /^2001:4860:/i) {
            return "IPv6 address in Google's network (AS15169)";
        }
        return "IPv6 global unicast address";
    }
    
    # IPv4 classification
    my @octets = split(/\./, $ip);
    return undef unless @octets == 4;
    
    # RFC 1918 private addresses
    if ($octets[0] == 10) {
        return "RFC 1918 private address space (10.0.0.0/8)";
    } elsif ($octets[0] == 172 && $octets[1] >= 16 && $octets[1] <= 31) {
        return "RFC 1918 private address space (172.16.0.0/12)";
    } elsif ($octets[0] == 192 && $octets[1] == 168) {
        return "RFC 1918 private address space (192.168.0.0/16)";
    }
    
    # Special use addresses
    if ($octets[0] == 127) {
        return "Loopback address (127.0.0.0/8)";
    } elsif ($octets[0] == 169 && $octets[1] == 254) {
        return "Link-local address (169.254.0.0/16) - APIPA";
    } elsif ($octets[0] == 0) {
        return "Reserved address space (0.0.0.0/8)";
    } elsif ($octets[0] >= 224 && $octets[0] <= 239) {
        return "Multicast address (224.0.0.0/4)";
    } elsif ($octets[0] >= 240) {
        return "Reserved address space (240.0.0.0/4)";
    }
    
    # Well-known public ranges
    if ($ip =~ /^8\.8\.[48]\.\d+$/) {
        return "Google Public DNS (AS15169)";
    } elsif ($ip =~ /^1\.1\.1\.\d+$/) {
        return "Cloudflare DNS (AS13335)";
    } elsif ($ip =~ /^(142\.250\.|172\.217\.|216\.58\.)/) {
        return "Google infrastructure (AS15169)";
    } elsif ($ip =~ /^(13\.|52\.|54\.)/) {
        return "Amazon Web Services address space";
    } elsif ($ip =~ /^(20\.|40\.|52\.)/) {
        return "Microsoft Azure address space";
    }
    
    return "Public routable IPv4 address";
}

sub analyze_ttl {
    my ($self, $ttl) = @_;
    
    return undef unless defined $ttl;
    
    if ($ttl < 60) {
        return "Very short TTL ($ttl sec) - likely dynamic DNS or active load balancing";
    } elsif ($ttl < 300) {
        return "Short TTL ($ttl sec) - frequent updates expected";
    } elsif ($ttl >= 86400) {
        my $days = int($ttl / 86400);
        return "Long TTL ($days day(s)) - static record, high cache efficiency";
    }
    
    return undef;
}

sub format_time {
    my ($self, $seconds) = @_;
    
    return "0s" unless $seconds;
    
    my $days = int($seconds / 86400);
    my $hours = int(($seconds % 86400) / 3600);
    my $mins = int(($seconds % 3600) / 60);
    my $secs = $seconds % 60;
    
    my @parts;
    push @parts, "${days}d" if $days;
    push @parts, "${hours}h" if $hours;
    push @parts, "${mins}m" if $mins;
    push @parts, "${secs}s" if $secs || !@parts;
    
    return join(' ', @parts);
}

sub analyze_response {
    my ($self, $packet, $domain) = @_;
    
    return undef unless defined $packet && defined $domain;
    
    my @analysis;
    my $header = eval { $packet->header };
    return undef unless $header;
    
    # Analyze flags
    if ($header->aa) {
        push @analysis, "Authoritative answer from primary nameserver";
    }
    
    if ($header->tc) {
        push @analysis, "Response truncated - consider using TCP (+tcp)";
    }
    
    # Analyze answer section
    my @answers = eval { $packet->answer };
    if (!$@ && @answers) {
        my %types;
        my $cname_chain = 0;
        
        foreach my $rr (@answers) {
            next unless defined $rr;
            my $type = eval { $rr->type };
            $types{$type}++ if $type && !$@;
            $cname_chain++ if $type && $type eq 'CNAME';
        }
        
        if ($cname_chain > 1) {
            push @analysis, "CNAME chain length: $cname_chain (adds $cname_chain DNS lookups)";
        }
        
        if ($types{A} && $types{AAAA}) {
            push @analysis, "Dual-stack configuration (IPv4 and IPv6 available)";
        }
    }
    
    # Check for DNSSEC
    if ($header->ad) {
        push @analysis, "DNSSEC validation successful";
    }
    
    return @analysis ? \@analysis : undef;
}

sub print_short {
    my ($self, $packet) = @_;
    
    return unless $packet;
    
    my @answers = eval { $packet->answer };
    return if $@;
    
    foreach my $rr (@answers) {
        next unless $rr;
        
        my $output = eval {
            if ($rr->can('address')) {
                return $rr->address;
            } elsif ($rr->can('cname')) {
                return $rr->cname;
            } elsif ($rr->can('exchange')) {
                return $rr->exchange;
            } elsif ($rr->can('nsdname')) {
                return $rr->nsdname;
            } elsif ($rr->can('ptrdname')) {
                return $rr->ptrdname;
            } elsif ($rr->can('txtdata')) {
                return $rr->txtdata;
            } elsif ($rr->can('rdstring')) {
                return $rr->rdstring;
            }
            return undef;
        };
        
        print "$output\n" if defined $output && !$@;
    }
}

sub print_json {
    my ($self, $result, $domain) = @_;
    my $packet = $result->{packet};
    my $config = $self->{config};
    
    my $header = $packet->header;
    my %output = (
        domain => $domain,
        type => $config->{qtype},
        class => $config->{qclass},
        status => $header->rcode,
        query_time_ms => $result->{query_time},
        server => $config->{server} || 'system-default',
        port => $config->{port},
        protocol => $config->{protocol},
        flags => {
            qr => $header->qr ? JSON::true : JSON::false,
            aa => $header->aa ? JSON::true : JSON::false,
            tc => $header->tc ? JSON::true : JSON::false,
            rd => $header->rd ? JSON::true : JSON::false,
            ra => $header->ra ? JSON::true : JSON::false,
            ad => $header->ad ? JSON::true : JSON::false,
            cd => $header->cd ? JSON::true : JSON::false,
        },
        question => [],
        answer => [],
        authority => [],
        additional => [],
    );
    
    foreach my $q ($packet->question) {
        push @{$output{question}}, {
            name => $q->qname,
            type => $q->qtype,
            class => $q->qclass,
        };
    }
    
    foreach my $rr ($packet->answer) {
        push @{$output{answer}}, $self->parse_rr($rr);
    }
    
    foreach my $rr ($packet->authority) {
        push @{$output{authority}}, $self->parse_rr($rr);
    }
    
    foreach my $rr ($packet->additional) {
        next if $rr->type eq 'OPT';  # Skip EDNS pseudo-records
        push @{$output{additional}}, $self->parse_rr($rr);
    }
    
    print encode_json(\%output) . "\n";
}

sub parse_rr {
    my ($self, $rr) = @_;
    
    return {} unless $rr;
    
    my %record = eval {
        (
            name => $rr->name,
            type => $rr->type,
            class => $rr->class,
            ttl => $rr->ttl,
        )
    };
    
    return \%record if $@;
    
    # Safely extract record-specific data
    eval {
        if ($rr->can('address')) {
            $record{address} = $rr->address;
        } elsif ($rr->can('cname')) {
            $record{cname} = $rr->cname;
        } elsif ($rr->can('exchange')) {
            $record{exchange} = $rr->exchange;
            $record{preference} = $rr->preference if $rr->can('preference');
        } elsif ($rr->can('nsdname')) {
            $record{nsdname} = $rr->nsdname;
        } elsif ($rr->can('ptrdname')) {
            $record{ptrdname} = $rr->ptrdname;
        } elsif ($rr->can('mname')) {
            $record{mname} = $rr->mname;
            $record{rname} = $rr->rname if $rr->can('rname');
            $record{serial} = $rr->serial if $rr->can('serial');
            $record{refresh} = $rr->refresh if $rr->can('refresh');
            $record{retry} = $rr->retry if $rr->can('retry');
            $record{expire} = $rr->expire if $rr->can('expire');
            $record{minimum} = $rr->minimum if $rr->can('minimum');
        } elsif ($rr->can('txtdata')) {
            $record{txtdata} = $rr->txtdata;
        } elsif ($rr->can('target')) {
            $record{target} = $rr->target;
            $record{priority} = $rr->priority if $rr->can('priority');
            $record{weight} = $rr->weight if $rr->can('weight');
            $record{port} = $rr->port if $rr->can('port');
        } elsif ($rr->can('rdstring')) {
            $record{rdata} = $rr->rdstring;
        }
    };
    
    return \%record;
}

sub print_trace {
    my ($self, $trace_results, $domain) = @_;
    
    print "; <<>> dnsq trace <<>> $domain\n";
    print ";; global options: +cmd\n\n";
    
    foreach my $result (@$trace_results) {
        print ";; Querying server: $result->{server} for $result->{query}\n";
        
        if ($result->{error}) {
            print STDERR "Query failed: $result->{error}\n";
            next;
        }
        
        my $packet = $result->{packet};
        
        if ($packet->header->ancount > 0) {
            print ";; ANSWER SECTION:\n";
            foreach my $rr ($packet->answer) {
                print $rr->string . "\n";
            }
        }
        
        if ($packet->header->nscount > 0) {
            print "\n;; AUTHORITY SECTION:\n";
            foreach my $rr ($packet->authority) {
                print $rr->string . "\n";
            }
        }
        
        if ($packet->header->arcount > 0) {
            print "\n;; ADDITIONAL SECTION:\n";
            foreach my $rr ($packet->additional) {
                print $rr->string . "\n";
            }
        }
        
        print "\n";
    }
}

1;
