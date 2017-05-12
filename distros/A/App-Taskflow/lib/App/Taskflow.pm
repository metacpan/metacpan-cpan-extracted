package App::Taskflow;
use v5.10;
use POSIX qw(setsid);
our @EXPORT = qw/usage version taskflow daemonize/;# Symbols to autoexport (:DEFAULT tag)
use base qw/Exporter/;
use Log::Handler;
use DBM::Deep;
$|++; # disable buffering on STDOUT - autoflush

our $VERSION = '1.0';
our $re_line = qr/(?<n>\w+):\s*(?<p>.+?)\s*(\[(?<dt>\w+)\]\s*)?:\s*(?<c>.*)\s*(?<a>\&)?/;

sub daemonize {
    defined(my $pid = fork) or die "Can't fork: $!";
    exit if $pid;
    setsid or die "Can't start a new session: $!";
    umask 0;
}

sub load_config {
    my $config_filename = shift;
    my $data            = shift;
    return if (! -e $config_filename);
    my $config_mt = (stat $config_filename )[9];

    my @config = ();
    print '-'x10,' loading rules ','-'x10, "\n";
    my $lines = do {   # narrow scope
        local $/;      # Enter file slurp mode localized
        open my $in_fh, '<', $config_filename or "Cannot read '$config_filename': $!\n";
        <$in_fh>;      # slurp whole input file in a run
    };
    for my $line ( split(/\n/, $lines) ) {
        if ($line !~ /^#/ and $line =~ /:/) { # not starts with '#' and has ':'
            if ($line =~ /$re_line/) {
                print $line, "\n";
                my $name    = $+{n};
                my $pattern = $+{p};
                my $dt_str  = $+{dt} // '1';
                for (qw/1 s m h d/) {
                    $dt_str =~ s/s/*1/;
                    $dt_str =~ s/m/*60/;
                    $dt_str =~ s/h/*3600/;
                    $dt_str =~ s/d/*24*3600/;
                    $dt_str =~ s/w/*7*24*3600/;
                }
                my $dt = eval $dt_str;
                my $command   = $+{c};
                my $ampersand = $+{a};
                push @config, [$name,$pattern,$dt,$command,$ampersand];
                $data->{$name} = () if ( !$data->{$name} );
            }
        }
    }
    print '-'x35, "\n";
    return \@config, $config_mt;
}

sub taskflow {
    my ($folder, $logfile, $config_filename, $cache_filename, $target_name, $sleep) = @_;
    my $log = Log::Handler->new(file => {
        filename        => $logfile,
        maxlevel        => "debug",
        minlevel        => "emerg",
        message_layout  => "%T [%L] %S: %m" });
    my $data = DBM::Deep->new($cache_filename);
    my ($config, $config_mt) = load_config($config_filename, $data);
    my %processes = ();
    while (@$config){
        my $pause = 1;
        ($config, $config_mt) = load_config($config_filename, $data) if ($config_mt < (stat $config_filename )[9]);
        return if (!@$config);
        for my $clear (<.taskflow.*.clear>) {
            my $rule = substr($clear, 10, -6);
            $log->info('clearing rule '.$rule);
            delete $data->{$rule};
            unlink($clear);
        }
        for my $cfg (@$config) {
            next if (!defined $cfg);
            my ($name, $pattern, $dt, $action, $ampersand) = @$cfg;
            for my $filename (glob($pattern)) {
                next if (!$filename);
                my $mt =  (stat $filename)[9];
                next if ($mt > time - $dt);
                my $pid_file = $filename.".$name.pid";
                my $log_file = $filename.".$name.out";
                my $err_file = $filename.".$name.err";
                (my $key = $pattern.'='.$filename.':'.$action) =~ s/\s+/ /g;
                unless (-e $pid_file or -e $err_file) {
                    if (!exists $data->{$key} or $data->{$key} != $mt){
                        (my $command = $action) =~ s/\Q$target_name\E/$filename/g;
                        $log->info($filename.' -> '.$command); my $buffer;
                        my $return;
                        if (my $pid = fork) {
                            # parent - child process pid is available in $pid
                            open my $fh, '>', $pid_file or die $!;
                            print $fh $pid; # write pid
                            close $fh;
                            waitpid($pid, 0) unless ($ampersand);
                        } else { # $pid is zero here if defined
                            die "cannot fork: $!" unless defined $pid;
                            # parent process pid is available with getppid
                            open STDOUT, '>', $log_file;
                            open STDERR, '>', $log_file;
                            $return = system $command;
                            close STDOUT;
                            close STDERR;
                        }
                        $processes{$pid_file} = [$filename, $command, $return];
                    }
                }
                my @pids = keys %processes;
                if ($pid_file ~~ @pids and exists $processes{$pid_file}[2] and $processes{$pid_file}[2] == 0) {
                    my ($filename, $command, $return) = @{$processes{$pid_file}};
                    if ($return){
                        open my $fh, '>', $err_file or die $!;
                        print $fh $return;
                        close $fh;
                    }else{
                        $data->{$key}  = $mt;
                        $data->{$name}  = (defined $data->{$name}) ? $data->{$name}.' '.$key : $key;
                    }
                    delete $processes{$pid_file};
                    unlink $pid_file;
                    $pause = 0;
                } elsif (-e $pid_file and $pid_file !~ @pids ) {
                    unlink $pid_file;
                    $pause = 0;
                }
            }
           sleep $sleep if ($pause);
        }
    }
}

sub version { my $ver = shift // $VERSION; print "Version: $ver\n"; exit 0; }
sub usage   { system("perldoc $0"); exit 0; }
1; # End of App::Taskflow
__END__
=head1 NAME

App::Taskflow - a light weight file-based taskflow system

This module is the helper library for I<taskflow>. No user-serviceable
parts inside. Use I<taskflow> only.

For a complete documentation of I<taskflow>,  see its POD.

=head1 VERSION

Version 1.0

=cut

=head1 SYNOPSIS

    use App::Taskflow;
    workflow ($folder, $log, $config, $cache, $name, $sleep);
    ...

=head1 EXPORT

usage version taskflow daemonize

=head1 SUBROUTINES/METHODS

=head2 usage  

description and examples of usage

=head2 version 

Print-out of current version of script

=head2 taskflow 

Main function, a file-based taskflow system based on configuration file

=head2 load_config

Read configuration file and returns its content as a reference to an
array, and the modification time of configuration file

=head2 daemonize

Fork and detach from the parent process

=cut

=head1 AUTHOR

Farhad Fouladi, C<< <farhad at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-taskflow at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Taskflow>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Taskflow

    or 

    perldoc taskflow

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Taskflow>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Taskflow>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Taskflow>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Taskflow/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Farhad Fouladi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
