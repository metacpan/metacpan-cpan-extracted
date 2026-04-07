#!/usr/bin/env perl
#
# Interactive Chandra::Log demo
#
# Run: perl examples/log_example.pl
#
# Demonstrates all logging features interactively — type commands
# at the prompt to exercise each capability.
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use File::Temp qw(tempdir);
use Chandra::Log;

my $dir = tempdir(CLEANUP => 1);
my $logfile = "$dir/demo.log";

print <<'BANNER';
╔═══════════════════════════════════════════════════╗
║          Chandra::Log Interactive Demo            ║
╚═══════════════════════════════════════════════════╝

Commands:
  debug <msg>     Log a debug message
  info <msg>      Log an info message
  warn <msg>      Log a warning message
  error <msg>     Log an error message
  fatal <msg>     Log a fatal message

  level <lvl>     Set log level (debug/info/warn/error/fatal)
  fmt <type>      Set formatter (text/json/minimal)

  data <msg>      Log info with sample structured data
  ctx             Create a contextual child logger and log through it
  multi           Demo multiple outputs (stderr + file + callback)
  rotate          Demo file rotation
  rapid           Log 100 messages rapidly

  file            Show contents of the log file
  help            Show this help
  quit            Exit

BANNER

my $log = Chandra::Log->new(
    level  => 'debug',
    output => [
        'stderr',
        { file => $logfile },
    ],
);

print "Log file: $logfile\n";
print "Current level: ", $log->level, "\n\n";

while (1) {
    print "log> ";
    my $input = <STDIN>;
    last unless defined $input;
    chomp $input;
    next unless length $input;

    my ($cmd, $rest) = split(/\s+/, $input, 2);
    $cmd = lc($cmd);
    $rest //= '';

    if ($cmd eq 'quit' || $cmd eq 'exit' || $cmd eq 'q') {
        print "Bye!\n";
        last;
    }
    elsif ($cmd eq 'help') {
        print <<'HELP';
  debug/info/warn/error/fatal <msg>  - Log at that level
  level <lvl>  - Change min level
  fmt <type>   - Change formatter (text/json/minimal)
  data <msg>   - Log with structured data
  ctx          - Demo contextual logger
  multi        - Demo multiple outputs
  rotate       - Demo file rotation
  rapid        - Log 100 messages rapidly
  file         - Show log file contents
  quit         - Exit
HELP
    }
    elsif ($cmd eq 'debug') {
        $log->debug($rest || 'Debug message');
    }
    elsif ($cmd eq 'info') {
        $log->info($rest || 'Info message');
    }
    elsif ($cmd eq 'warn') {
        $log->warn($rest || 'Warning message');
    }
    elsif ($cmd eq 'error') {
        $log->error($rest || 'Error message');
    }
    elsif ($cmd eq 'fatal') {
        $log->fatal($rest || 'Fatal message');
    }
    elsif ($cmd eq 'level') {
        if ($rest && $rest =~ /^(debug|info|warn|error|fatal)$/) {
            $log->set_level($rest);
            print "  Level set to: $rest\n";
        } else {
            print "  Current level: ", $log->level, "\n";
            print "  Usage: level debug|info|warn|error|fatal\n";
        }
    }
    elsif ($cmd eq 'fmt') {
        if ($rest && $rest =~ /^(text|json|minimal)$/) {
            $log->formatter($rest);
            print "  Formatter set to: $rest\n";
        } else {
            print "  Usage: fmt text|json|minimal\n";
        }
    }
    elsif ($cmd eq 'data') {
        my $msg = $rest || 'Request processed';
        $log->info($msg, {
            method   => 'GET',
            path     => '/api/users',
            status   => 200,
            duration => 0.045,
            headers  => { 'Content-Type' => 'application/json' },
        });
    }
    elsif ($cmd eq 'ctx') {
        print "  Creating contextual logger with request_id and user...\n";
        my $req_log = $log->with(
            request_id => 'req-' . int(rand(9999)),
            user       => 'alice',
        );
        $req_log->info('Processing request');
        $req_log->debug('Looking up user', { db => 'users', query => 'SELECT *' });
        $req_log->info('Request complete', { status => 200 });
        print "  (3 messages logged with context)\n";
    }
    elsif ($cmd eq 'multi') {
        print "  Creating logger with stderr + file + callback...\n";
        my @cb_entries;
        my $multi = Chandra::Log->new(
            level  => 'debug',
            output => [
                'stderr',
                { file => "$dir/multi.log" },
                { callback => sub { push @cb_entries, $_[0] }, level => 'warn' },
            ],
            formatter => 'minimal',
        );

        $multi->info('This goes to stderr + file only');
        $multi->warn('This goes to all three outputs');
        $multi->error('This also goes to all three');

        print "  Callback captured ", scalar(@cb_entries), " entries (warn+error only)\n";
        print "  File written to: $dir/multi.log\n";
    }
    elsif ($cmd eq 'rotate') {
        my $rot_file = "$dir/rotate.log";
        print "  Creating logger with rotation (max_size=50, keep=3)...\n";
        my $rot = Chandra::Log->new(
            output    => { file => $rot_file },
            formatter => 'minimal',
            rotate    => { max_size => 50, keep => 3 },
        );

        for my $i (1..15) {
            $rot->info("Rotation test message number $i");
        }

        my @files = grep { -f $_ }
                    map { $_ == 0 ? $rot_file : "$rot_file.$_" } 0..5;
        print "  Files created: ", scalar(@files), "\n";
        for my $f (@files) {
            my $size = -s $f;
            (my $name = $f) =~ s{.*/}{};
            print "    $name ($size bytes)\n";
        }
    }
    elsif ($cmd eq 'rapid') {
        print "  Logging 100 messages...\n";
        my $start = time();
        $log->info("rapid message $_") for 1..100;
        my $elapsed = time() - $start;
        print "  Done in ${elapsed}s\n";
    }
    elsif ($cmd eq 'file') {
        if (-f $logfile) {
            open my $fh, '<', $logfile or do {
                print "  Cannot read: $!\n"; next;
            };
            my @lines = <$fh>;
            close $fh;
            my $total = scalar @lines;
            print "  --- $logfile ($total lines) ---\n";
            # Show last 20 lines
            my $start = $total > 20 ? $total - 20 : 0;
            if ($start > 0) {
                print "  ... ($start earlier lines omitted)\n";
            }
            print "  $_" for @lines[$start .. $#lines];
            print "  --- end ---\n";
        } else {
            print "  (no log file yet)\n";
        }
    }
    else {
        print "  Unknown command: $cmd (type 'help' for commands)\n";
    }
}
