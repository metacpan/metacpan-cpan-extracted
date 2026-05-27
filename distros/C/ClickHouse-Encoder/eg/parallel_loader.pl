#!/usr/bin/env perl
# Fork N worker processes, each ingesting one slice of the input data.
# Workers share nothing; they each open their own HTTP connection to
# ClickHouse and insert in parallel. The main process partitions the
# input by file (one file per worker round-robin) and waits for all
# workers to finish.
#
# Why fork() instead of threads? On Perl, ithreads are heavy and copy
# everything; fork() with copy-on-write keeps the parsed schema (the
# Encoder object) shared until first modification. For network-bound
# ingestion (CH on a remote host) the workers spend most of their time
# waiting on HTTP, so even a 4x or 8x parallelism scales well.
#
# Usage:
#     CH_PORT=8123 WORKERS=4 \
#     perl eg/parallel_loader.pl events events_*.ndjson
#
# Each line of input is a JSON object; columns map by name (see
# eg/json_lines_ingest.pl for the per-row format).

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use HTTP::Tiny;
use JSON::PP;
use POSIX qw(:sys_wait_h);

my $table   = shift @ARGV or die "Usage: $0 <table> <file>...\n";
my @files   = @ARGV       or die "Usage: $0 <table> <file>...\n";
my $port    = $ENV{CH_PORT} // 8123;
my $workers = $ENV{WORKERS} // 4;
my $batch   = $ENV{BATCH}   // 5_000;

# Parse the schema once in the parent. After fork() the children share
# the parsed encoder by COW until any of them writes to it.
my $enc   = ClickHouse::Encoder->for_table($table, via=>'http', port=>$port);
my @cols  = @{ $enc->columns };
my @names = map { $_->[0] } @cols;
my %nullable = map { $_->[0] => ($_->[1] =~ /\ANullable\(/ ? 1 : 0) } @cols;
print STDERR "schema: ", scalar(@cols), " columns\n";

# Round-robin partition the files across workers.
my @partitions = map { [] } 1 .. $workers;
my $i = 0;
for my $f (@files) {
    push @{ $partitions[$i++ % $workers] }, $f;
}

# Spawn workers.
my @pids;
for my $w (0 .. $workers - 1) {
    my @my_files = @{ $partitions[$w] } or next;
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        # Child: ingest its files, then exit.
        run_worker($w, \@my_files);
        exit 0;
    }
    push @pids, $pid;
    print STDERR "  spawned worker $w (pid $pid) with ", scalar(@my_files),
        " file(s)\n";
}

# Reap.
my $failed = 0;
while (@pids) {
    my $pid = waitpid -1, 0;
    last if $pid <= 0;
    @pids = grep { $_ != $pid } @pids;
    if ($?) {
        warn "worker $pid exited with status $?\n";
        $failed++;
    }
}
exit($failed ? 1 : 0);

sub run_worker {
    my ($id, $files) = @_;
    my $json = JSON::PP->new->utf8;
    my $http = HTTP::Tiny->new(timeout => 60);
    my $url  = "http://localhost:$port/?query="
             . _esc("insert into $table format native");

    my $writer = sub {
        my $resp = $http->post($url, {
            content => $_[0],
            headers => { 'Content-Type' => 'application/octet-stream' },
        });
        die "[w$id] insert failed (status $resp->{status}): $resp->{content}"
            unless $resp->{success};
    };
    my $st  = $enc->streamer($writer, batch_size => $batch);
    my $rows = 0;
    for my $f (@$files) {
        open my $fh, '<', $f or die "[w$id] open $f: $!";
        while (defined(my $line = <$fh>)) {
            chomp $line;
            next if $line =~ /\A\s*\z/;
            my $rec = eval { $json->decode($line) };
            next if $@;
            my @row;
            for my $name (@names) {
                if (exists $rec->{$name}) { push @row, $rec->{$name} }
                elsif ($nullable{$name})  { push @row, undef }
                else { die "[w$id] $f line $.: missing column '$name'" }
            }
            $st->push_row(\@row);
            $rows++;
        }
        close $fh;
    }
    $st->finish;
    print STDERR "  worker $id: $rows rows ingested\n";
}

sub _esc {
    (my $s = $_[0]) =~ s/([^A-Za-z0-9\-_.~])/sprintf('%%%02X', ord($1))/ge;
    $s;
}
