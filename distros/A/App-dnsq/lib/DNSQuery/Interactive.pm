package DNSQuery::Interactive;
use strict;
use warnings;
use Term::ReadLine;
use DNSQuery::Resolver;
use DNSQuery::Validator qw(:all);
use DNSQuery::Constants qw(:all);

our $VERSION = '1.1.0';

sub new {
    my ($class, $config, $resolver, $output) = @_;
    return bless {
        config   => $config,
        resolver => $resolver,
        output   => $output,
        term     => Term::ReadLine->new('dnsq'),
    }, $class;
}

sub run {
    my ($self) = @_;
    
    print "Interactive Mode - Type 'help' for commands, 'quit' to exit\n\n";
    
    my $prompt = "dnsq> ";
    
    while (defined(my $input = $self->{term}->readline($prompt))) {
        chomp $input;
        $input =~ s/^\s+|\s+$//g;
        next if $input eq '';
        
        $self->{term}->addhistory($input) if $input =~ /\S/;
        
        if ($input eq 'quit' || $input eq 'exit') {
            last;
        } elsif ($input eq 'help') {
            $self->print_help();
        } elsif ($input =~ /^set\s+(\w+)\s+(.+)$/) {
            $self->set_config($1, $2);
        } elsif ($input eq 'show' || $input eq 'stats') {
            $self->show_config();
        } elsif ($input eq 'clear cache') {
            $self->{resolver}->clear_cache();
            print "Cache cleared\n";
        } else {
            $self->process_query($input);
        }
    }
    
    print "\nGoodbye!\n";
}

sub set_config {
    my ($self, $key, $value) = @_;
    
    unless (exists $self->{config}{$key}) {
        print "Unknown setting: $key\n";
        return;
    }
    
    # Validate specific settings using Validator module
    my ($valid, $error);
    
    if ($key eq 'port') {
        ($valid, $error) = validate_port($value);
        unless ($valid) {
            print "Error: $error\n";
            return;
        }
    } elsif ($key eq 'timeout') {
        ($valid, $error) = validate_timeout($value);
        unless ($valid) {
            print "Error: $error\n";
            return;
        }
    } elsif ($key eq 'retries') {
        ($valid, $error) = validate_retries($value);
        unless ($valid) {
            print "Error: $error\n";
            return;
        }
    } elsif ($key eq 'protocol') {
        unless ($value =~ /^(tcp|udp)$/i) {
            print "Error: Protocol must be 'tcp' or 'udp'\n";
            return;
        }
        $value = lc($value);
    } elsif ($key eq 'server') {
        ($valid, $error) = validate_ip($value);
        my ($valid_domain, $error_domain) = validate_domain($value);
        unless ($valid || $valid_domain) {
            print "Error: Invalid server address\n";
            return;
        }
    }
    
    my $old_value = $self->{config}{$key};
    $self->{config}{$key} = $value;
    
    # Recreate resolver if network settings changed
    if ($key =~ /^(server|port|timeout|retries|protocol)$/) {
        eval {
            $self->{resolver} = DNSQuery::Resolver->new($self->{config});
        };
        if ($@) {
            print "Error updating resolver: $@\n";
            $self->{config}{$key} = $old_value;  # Rollback
            return;
        }
    }
    
    print "Set $key = $value\n";
}

sub show_config {
    my ($self) = @_;
    
    print "Current settings:\n";
    foreach my $key (sort keys %{$self->{config}}) {
        next if ref $self->{config}{$key};
        my $val = defined $self->{config}{$key} ? $self->{config}{$key} : 'undef';
        print "  $key = $val\n";
    }
    
    # Show statistics
    my $stats = $self->{resolver}->get_stats();
    if ($stats->{total_queries} > 0) {
        print "\nQuery Statistics:\n";
        printf "  Total queries: %d\n", $stats->{total_queries};
        printf "  Cache hits: %d (%.1f%%)\n", 
            $stats->{cache_hits}, 
            ($stats->{cache_hits} / $stats->{total_queries}) * 100;
        printf "  Failed queries: %d\n", $stats->{failed_queries};
        my $successful = $stats->{total_queries} - $stats->{failed_queries} - $stats->{cache_hits};
        if ($successful > 0) {
            printf "  Avg query time: %.1f ms\n", 
                $stats->{total_time_ms} / $successful;
        }
    }
}

sub process_query {
    my ($self, $input) = @_;
    
    # Validate input
    unless (defined $input && length($input) > 0) {
        print "Error: Query cannot be empty\n";
        return;
    }
    
    my ($domain, $type) = split(/\s+/, $input, 2);
    
    # Trim whitespace
    $domain =~ s/^\s+|\s+$//g if defined $domain;
    
    # Validate domain using Validator module
    my ($valid, $error) = validate_domain($domain);
    unless ($valid) {
        print "Error: $error\n";
        return;
    }
    
    # Validate query type if provided
    if ($type) {
        $type = uc($type);
        ($valid, $error) = validate_query_type($type);
        unless ($valid) {
            print "Error: $error\n";
            print "Valid types: " . join(', ', sort keys %VALID_QUERY_TYPES) . "\n";
            return;
        }
    }
    
    my $result = eval { $self->{resolver}->query($domain, $type) };
    
    if ($@) {
        my $error = $@;
        chomp $error;
        print STDERR "Query error: $error\n";
        return;
    }
    
    unless (defined $result && ref($result) eq 'HASH') {
        print STDERR "Error: Invalid query result\n";
        return;
    }
    
    if ($result->{error}) {
        print STDERR "Query failed: $result->{error}\n";
        return;
    }
    
    $self->{output}->print_result($result, $domain);
}

sub print_help {
    print <<'HELP';
Interactive mode commands:
  <domain> [type]     - Query domain for specified type (default: A)
  set <key> <value>   - Set configuration option
  show / stats        - Show current settings and statistics
  clear cache         - Clear query cache
  help                - Show this help
  quit/exit           - Exit interactive mode

Examples:
  google.com
  example.com MX
  set server 8.8.8.8
  set timeout 10
  stats
HELP
}

1;
