package Build::PPK::Exec;

# Copyright (c) 2013, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use POSIX ();
use Fcntl ();

sub run {
    my ( $class, $argv, %opts ) = @_;

    my ( $out, $out_i );    # Standard output pipe pair
    my ( $err, $err_i );    # Standard error pipe pair

    #
    # Create pipes for standard output or standard error, if either are indicated
    # by the current options.
    #
    if ( $opts{'capture_stdout'} ) {
        pipe( $out, $out_i ) or die("Unable to pipe() for stdout: $!");
    }

    if ( $opts{'capture_stderr'} ) {
        pipe( $err, $err_i ) or die("Unable to pipe() for stderr: $!");
    }

    if ( $opts{'die_on_stderr'} ) {
        die("Option 'die_on_stderr' requires 'capture_stderr'") unless $opts{'capture_stderr'};
    }

    my $pid = fork();

    if ( !defined $pid ) {
        die("Unable to fork(): $!");
    }
    elsif ( $pid == 0 ) {
        if ( $opts{'close_stdin'} ) {
            close STDIN;
        }
        else {
            open( STDIN, '<', '/dev/null' ) or die("Unable to redirect stdin to /dev/null: $!");
        }

        #
        # If standard output or error are to be captured by the parent process,
        # then redirect them to their respective pipe inputs.  If they are to be
        # suppressed, then simply close them.  Otherwise, let standard output and
        # error leak out.
        #

        if ( $opts{'capture_stdout'} ) {
            close $out;
            POSIX::dup2( fileno($out_i), fileno(STDOUT) ) or die("Unable to redirect standard output to pipe: $!");
        }
        elsif ( $opts{'suppress_stdout'} ) {
            open( STDOUT, '>', '/dev/null' ) or die("Unable to redirect stdout to /dev/null: $!");
        }

        if ( $opts{'capture_stderr'} ) {
            close $err;
            POSIX::dup2( fileno($err_i), fileno(STDERR) ) or die("Unable to redirect standard error to pipe: $!");
        }
        elsif ( $opts{'suppress_stderr'} ) {
            open( STDERR, '>', '/dev/null' ) or die("Unable to redirect stderr to /dev/null: $!");
        }

        exec( @{$argv} ) or die("Unable to exec() $argv->[0]: $!");
    }

    my $stdout;
    my $stderr;

    my $set = '';

    #
    # If we are to capture standard output or error, then close the input ends
    # of each requisite pipe and prepare to select() for data ready to be read().
    #
    if ( $opts{'capture_stdout'} ) {
        close $out_i;
        vec( $set, fileno($out), 1 ) = 1;
    }

    if ( $opts{'capture_stderr'} ) {
        close $err_i;
        vec( $set, fileno($err), 1 ) = 1;
    }

    while ( $set && select( my $ready = $set, undef, undef, undef ) ) {
        my $found = 0;

        if ( $opts{'capture_stdout'} && vec( $ready, fileno($out), 1 ) ) {
            if ( sysread( $out, my $buf, 512 ) ) {
                print $buf if $opts{'print_stdout'};

                $stdout .= $buf;
                $found++;
            }
            else {
                vec( $set, fileno($out), 1 ) = 0;
            }
        }

        if ( $opts{'capture_stderr'} && vec( $ready, fileno($err), 1 ) ) {
            if ( sysread( $err, my $buf, 512 ) ) {
                print STDERR $buf if $opts{'print_stderr'};

                $stderr .= $buf;
                $found++;
            }
            else {
                vec( $set, fileno($err), 1 ) = 0;
            }
        }

        last unless $found;
    }

    waitpid( $pid, 0 ) or die("Unable to waitpid(): $!");

    my $status = $? >> 8;

    #
    # If we are to die on a nonzero exit status, and a nonzero exit status was
    # returned by the child, then either die with messages written to standard
    # error by the child, or a more generic message if standard error was not
    # chosen to be captured by the caller.
    #
    if ( $opts{'die_on_nonzero'} && $status != 0 ) {
        if ( $opts{'capture_stderr'} && defined $stderr ) {
            chomp $stderr;
            die("Nonzero exit status $status from $argv->[0]: $stderr");
        }
        else {
            die("Program $argv->[0] exited with nonzero status $status");
        }
    }

    #
    # Even if the program exited with a zero exit status, die if any errors were
    # captured, if this behavior is indicated by the current options.
    #
    if ( $opts{'die_on_stderr'} && defined $stderr ) {
        die($stderr);
    }

    #
    # If standard output was captured, then return it to the caller.  Otherwise,
    # return the child process exit status.
    #
    if ( $opts{'capture_stdout'} ) {
        chomp $stdout if $stdout;
        return $stdout;
    }

    #
    # If standard error was indicated for capture by the caller, then set $@ to
    # the data captured, if any.
    #
    if ( $opts{'capture_stderr'} ) {
        chomp $stderr if $stderr;
        $@ = $stderr;
    }

    return $status;
}

sub lazyrun {
    my ( $class, @args ) = @_;

    return $class->run(
        \@args,
        'capture_stdout'  => 1,
        'suppress_stderr' => 1
    );
}

sub call {
    my ( $class, $verbosity, $command, @args ) = @_;

    my %opts = ( 'capture_stderr' => 1 );

    if ( $verbosity > 0 ) {
        $opts{'print_stderr'} = 1;
    }

    if ( $verbosity < 2 ) {
        $opts{'suppress_stdout'} = 1;
    }

    return $class->run( [ $command, @args ], %opts );
}

sub silent {
    my ( $class, $command, @args ) = @_;
    return $class->call( 0, $command, @args );
}

sub quiet {
    my ( $class, $command, @args ) = @_;
    return $class->call( 1, $command, @args );
}

sub verbose {
    my ( $class, $command, @args ) = @_;
    return $class->call( 2, $command, @args );
}

1;
