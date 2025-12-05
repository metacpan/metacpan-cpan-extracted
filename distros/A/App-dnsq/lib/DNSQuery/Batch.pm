package DNSQuery::Batch;
use strict;
use warnings;
use JSON;
use Time::HiRes qw(time);
use POSIX qw(:sys_wait_h);
use DNSQuery::Validator qw(:all);
use DNSQuery::Constants qw(:all);

our $VERSION = '1.1.0';

# Enable parallel processing if available
our $PARALLEL_ENABLED = eval { require Parallel::ForkManager; 1; };

sub new {
    my ($class, $config, $resolver, $output) = @_;
    return bless {
        config   => $config,
        resolver => $resolver,
        output   => $output,
    }, $class;
}

sub process_file {
    my ($self, $filename) = @_;
    
    # Validate file using Validator module
    my ($valid, $error) = validate_file_path($filename, 1);
    die "Error: $error\n" unless $valid;
    
    # Warn about large files
    my $file_size = -s $filename;
    if ($file_size > 5_000_000) {  # 5MB warning threshold
        warn "Warning: Large batch file ($file_size bytes), processing may be slow\n";
    }
    
    open my $fh, '<', $filename or die "Error: Cannot open batch file '$filename': $!\n";
    
    my @queries = $self->_parse_batch_file($fh);
    
    my $skipped = $self->{_parse_stats}{skipped} || 0;
    
    close $fh;
    
    # Check if we have any valid queries
    my $total = scalar @queries;
    if ($total == 0) {
        die "Error: No valid queries found in batch file\n";
    }
    
    if ($skipped > 0) {
        warn "Warning: Skipped $skipped invalid entries\n";
    }
    
    # Process queries with optional parallelization
    my $start_time = time();
    
    if ($PARALLEL_ENABLED && $total > 10 && !$self->{config}{json}) {
        $self->_process_parallel(\@queries, $total, $start_time);
    } else {
        $self->_process_sequential(\@queries, $total, $start_time);
    }
}

sub _parse_batch_file {
    my ($self, $fh) = @_;
    
    my @queries;
    my $line_num = 0;
    my $skipped = 0;
    
    while (my $line = <$fh>) {
        $line_num++;
        chomp $line;
        
        # Remove comments and trim whitespace
        $line =~ s/#.*$//;
        $line =~ s/^\s+|\s+$//g;
        next if $line eq '';
        
        my ($domain, $type) = split(/\s+/, $line, 2);
        
        # Validate domain using Validator module
        my ($valid, $error) = validate_domain($domain);
        unless ($valid) {
            warn "Warning: Line $line_num: $error, skipping\n";
            $skipped++;
            next;
        }
        
        # Validate query type
        $type ||= $self->{config}{qtype};
        $type = uc($type);
        
        ($valid, $error) = validate_query_type($type);
        unless ($valid) {
            warn "Warning: Line $line_num: $error, skipping\n";
            $skipped++;
            next;
        }
        
        push @queries, {
            domain => $domain,
            type => $type,
            line => $line_num,
        };
    }
    
    # Store parse statistics
    $self->{_parse_stats} = {
        skipped => $skipped,
        total => scalar @queries,
    };
    
    return @queries;
}

sub _process_query {
    my ($self, $query, $processed, $total, $failed_ref) = @_;
    
    my $result = $self->{resolver}->query($query->{domain}, $query->{type});
    
    if ($result->{error}) {
        $$failed_ref++;
        if ($self->{config}{json}) {
            print encode_json({
                error => $result->{error},
                domain => $query->{domain},
                type => $query->{type},
                line => $query->{line},
            }) . "\n";
        } else {
            print STDERR "\nQuery failed for $query->{domain} (line $query->{line}): $result->{error}\n";
        }
        return;
    }
    
    $self->{output}->print_result($result, $query->{domain});
    print "\n" unless $self->{config}{json} || $self->{config}{short};
}

sub _print_progress {
    my ($self, $processed, $total) = @_;
    
    return if $self->{config}{json} || $self->{config}{short};
    return if $total <= 5;
    return unless $processed % 10 == 0;
    
    my $pct = int(($processed / $total) * 100);
    print STDERR "\rProgress: $processed/$total ($pct%)...";
}

sub _print_summary {
    my ($self, $processed, $failed, $elapsed, $total) = @_;
    
    return if $self->{config}{json};
    
    my $qps = $total / $elapsed;
    printf STDERR ";; Batch complete: %d queries, %d failed, %.2fs (%.1f q/s)\n",
        $processed, $failed, $elapsed, $qps;
}

sub _process_sequential {
    my ($self, $queries, $total, $start_time) = @_;
    
    my $processed = 0;
    my $failed = 0;
    
    foreach my $query (@$queries) {
        $processed++;
        $self->_print_progress($processed, $total);
        $self->_process_query($query, $processed, $total, \$failed);
    }
    
    my $elapsed = time() - $start_time;
    
    # Clear progress line
    unless ($self->{config}{json} || $self->{config}{short} || $total <= 5) {
        print STDERR "\r" . " " x 60 . "\r";
    }
    
    $self->_print_summary($processed, $failed, $elapsed, $total);
}

sub _process_parallel {
    my ($self, $queries, $total, $start_time) = @_;
    
    my $max_workers = 10;  # Limit concurrent processes
    my $pm = Parallel::ForkManager->new($max_workers);
    
    my $processed = 0;
    my $failed = 0;
    
    print STDERR ";; Using parallel processing with $max_workers workers\n"
        unless $self->{config}{json};
    
    # Data structure for collecting results
    my %results;
    
    $pm->run_on_finish(sub {
        my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
        $processed++;
        
        if ($data && $data->{result}) {
            $results{$data->{order}} = $data;
        } else {
            $failed++;
        }
        
        $self->_print_progress($processed, $total);
    });
    
    # Fork workers
    my $order = 0;
    foreach my $query (@$queries) {
        $order++;
        my $pid = $pm->start and next;
        
        # Child process
        my $result = $self->{resolver}->query($query->{domain}, $query->{type});
        
        $pm->finish(0, {
            order => $order,
            query => $query,
            result => $result,
        });
    }
    
    $pm->wait_all_children;
    
    # Clear progress line
    print STDERR "\r" . " " x 60 . "\r" unless $self->{config}{json};
    
    # Print results in order
    foreach my $i (sort { $a <=> $b } keys %results) {
        my $data = $results{$i};
        my $result = $data->{result};
        my $query = $data->{query};
        
        if ($result->{error}) {
            $failed++;
            unless ($self->{config}{json}) {
                print STDERR "Query failed for $query->{domain}: $result->{error}\n";
            }
            next;
        }
        
        $self->{output}->print_result($result, $query->{domain});
        print "\n" unless $self->{config}{json} || $self->{config}{short};
    }
    
    my $elapsed = time() - $start_time;
    $self->_print_summary($processed, $failed, $elapsed, $total);
}

1;
