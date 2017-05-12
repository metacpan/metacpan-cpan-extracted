package App::RunCron;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.08";

use Fcntl       qw(SEEK_SET);
use File::Temp  qw(tempfile);
use Time::HiRes qw/gettimeofday/;
use Sys::Hostname;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/timestamp command reporter error_reporter common_reporter tag print announcer/],
    rw  => [qw/logfile logpos exit_code _finished _started pid child_pid/],
);

sub _logfh {
    my $self = shift;
    return if $self->child_pid;

    $self->{_logfh} ||= do {
        my $logfh;
        my $logfile = $self->{logfile};
        if ($logfile) {
            open $logfh, '>>', $logfile or die "failed to open file:$logfile:$!";
        } else {
            ($logfh, $logfile) = tempfile(UNLINK => 1);
            $self->logfile($logfile);
        }
        autoflush $logfh 1;
        print $logfh '-'x78, "\n";
        $self->logpos(tell $logfh);
        die "failed to obtain position of logfile:$!" if $self->logpos == -1;
        seek $logfh, $self->logpos, SEEK_SET or die "cannot seek within logfile:$!";
        $logfh;
    };
}

sub run {
    my $self = shift;
    if (!$self->_started) {
        $self->_run;
        exit $self->child_exit_code;
    }
    else {
        warn "already run. can't rerun.\n";
    }
}

sub command_str {
    my $self = shift;
    $self->{command_str} ||= join ' ', @{ $self->command };
}

sub _run {
    my $self = shift;
    die "no command specified" unless @{ $self->command };

    my $logfh = $self->_logfh;
    pipe my $logrh, my $logwh or die "failed to create pipe:$!";

    $self->pid($$);
    $self->_started(1);
    $self->_log(sprintf("%s tag:[%s] starting: %s\n", hostname, $self->tag || '', $self->command_str));
    $self->exit_code(-1);
    unless (my $pid = fork) {
        if (defined $pid) {
            # child process
            close $logrh;
            close $logfh;

            $self->child_pid($$);
            if ($self->announcer) {
                $self->_announce;
            }
            open STDERR, '>&', $logwh or die "failed to redirect STDERR to logfile";
            open STDOUT, '>&', $logwh or die "failed to redirect STDOUT to logfile";
            close $logwh;
            exec @{ $self->command };
            die "exec(2) failed:$!:@{ $self->command }";
        }
        else {
            close $logrh;
            close $logwh;
            print $logfh, "fork(2) failed:$!\n" unless defined $pid;
        }
    }
    else {
        close $logwh;
        if ($self->print) {
            require PerlIO::Util;
            $self->_logfh->push_layer(tee => *STDOUT);
        }
        $self->_log($_) while <$logrh>;
        close $logrh;
        $self->_logfh->pop_layer if $self->print;
        while (wait == -1) {}
        $self->exit_code($?);
    }

    # end
    $self->_finished(1);
    $self->_log($self->result_line. "\n");

    if ($self->is_success) {
        $self->_send_report;
    }
    else {
        $self->_send_error_report;
    }
}

sub child_exit_code {
    my $self = shift;
    my $exit_code = $self->exit_code;
    return $exit_code if !$exit_code || $exit_code < 0;

    $self->exit_code >> 8;
}

sub child_signal {
    my $self = shift;
    my $exit_code = $self->exit_code;
    return $exit_code if !$exit_code || $exit_code < 0;

    $self->exit_code & 127;
}

sub is_success { shift->exit_code == 0 }

sub result_line {
    my $self = shift;
    $self->{result_line} ||= do {
        my $exit_code = $self->exit_code;
        if ($exit_code == -1) {
            "failed to execute command:$!";
        }
        elsif ($self->child_signal) {
            "command died with signal:" . $self->child_signal;
        }
        else {
            "command exited with code:" . $self->child_exit_code;
        }
    };
}

sub report {
    my $self = shift;

    $self->{report} ||= do {
        open my $fh, '<', $self->logfile  or die "failed to open @{[$self->logfile]}:$!";
        seek $fh, $self->logpos, SEEK_SET or die "failed to seek to the appropriate position in logfile:$!";
        my $report = '';
        $report .= $_ while <$fh>;
        $report;
    }
}

sub report_data {
    my $self = shift;
    +{
        report          => $self->report,
        command         => $self->command_str,
        result_line     => $self->result_line,
        is_success      => $self->is_success,
        child_exit_code => $self->child_exit_code,
        exit_code       => $self->exit_code,
        child_signal    => $self->child_signal,
        pid             => $self->pid,
        (defined $self->tag ? (tag => $self->tag) : ()),
    };
}

sub announce_data {
    my $self = shift;
    +{
        command   => $self->command_str,
        pid       => $self->pid,
        child_pid => $self->child_pid,
        logfile   => $self->logfile,
    };
}

sub _send_report {
    my $self = shift;

    my $reporter = $self->reporter || 'None';
    $self->_do_send_report($reporter, $self->common_reporter || ());
}

sub _send_error_report {
    my $self = shift;

    my $reporter = $self->error_reporter || 'Stdout';
    $self->_do_send_report($reporter, $self->common_reporter || ());
}

sub _invoke_plugins {
    my ($self, $type, @plugins) = @_;

    my $has_error;
    my $prefix = 'App::RunCron::' . ucfirst($type);
    for my $plugin (@plugins) {
        if (ref($plugin) && ref($plugin) eq 'CODE') {
            $plugin = [Code => $plugin];
        }
        my @plugins = _retrieve_plugins($plugin);
        for my $r (@plugins) {
            my ($class, $arg) = @$r;
            eval {
                _load_class_with_prefix($class, $prefix)->new($arg || ())->run($self);
            };
            if (my $err = $@) {
                $has_error = 1;
                warn "$type error occured! $err";
            }
        }
    }
    $has_error;
}

sub _announce {
    my $self = shift;

    $self->_invoke_plugins(announcer => $self->announcer);
}

sub _do_send_report {
    my ($self, @reporters) = @_;

    my $err = $self->_invoke_plugins(reporter => @reporters);
    if ($err) {
        warn $self->report;
    }
}

sub _retrieve_plugins {
    my $plugin = shift;
    my @plugins;
    if (ref $plugin && ref($plugin) eq 'ARRAY') {
        my @stuffs = @$plugin;

        while (@stuffs) {
            my $plugin_class = shift @stuffs;
            my $arg;
            if ($stuffs[0] && (ref($stuffs[0]) || $plugin_class eq 'Command')) {
                $arg = shift @stuffs;
            }
            push @plugins, [$plugin_class, $arg || ()];
        }
    }
    else {
        push @plugins, [$plugin];
    }
    @plugins;
}

sub _load_class_with_prefix {
    my ($class, $prefix) = @_;

    unless ($class =~ s/^\+// || $class =~ /^$prefix/) {
        $class = "$prefix\::$class";
    }

    my $file = $class;
    $file =~ s!::!/!g;
    require "$file.pm"; ## no citic

    $class;
}

sub _log {
    my ($self, $line) = @_;
    return if $self->child_pid;

    my $logfh = $self->_logfh;
    print $logfh (
        ($self->timestamp ? _timestamp() : ''),
        $line,
    );
}

sub _timestamp {
    my @tm = gettimeofday;
    my @dt = localtime $tm[0];
    sprintf('[%04d-%02d-%02d %02d:%02d:%02d.%06.0f] ',
        $dt[5] + 1900,
        $dt[4] + 1,
        $dt[3],
        $dt[2],
        $dt[1],
        $dt[0],
        $tm[1],
    );
}

__END__

=for stopwords cron crontab logfile eg

=encoding utf-8

=head1 NAME

App::RunCron - making wrapper script for crontab

=head1 SYNOPSIS

    use App::RunCron;
    my $runner = App::RunCron->new(
        timestamp => 1,
        command   => [@ARGV],
        logfile   => 'tmp/log%Y-%m-%d.log',
        reporter  => 'Stdout',
        error_reporter => [
            'Stdout',
            'File', {
                file => 'tmp/error%Y-%m-%d.log'
            },
        ],
    );
    $runner->run;

=head1 DESCRIPTION

App::RunCron is a software for making wrapper script for running cron tasks.

App::RunCron can separate reporting way if the command execution success or failed
(i.e. fails to start, or returns a non-zero exit code, or killed by a signal).
It is handled by `reporter` and `error_reporter` option.

By default, `reporter` is 'None' and `error_reporter` is 'Stdout'.
It prints the outputs the command if and only if the command execution failed.
In other words, this behaviour causes L<cron(8)> to send mail when and only when an error occurs.

Default behaviour is same like L<cronlog|https://github.com/kazuho/kaztools/blob/master/cronlog>.

=head1 OPTIONS

=head2 timestamp

Add timestamp or not. (Default: undef)

=head2 tag

Identifier of the job name. (Optional)

=head2 command

command to be executed. (Required)

=head2 logfile

If logfile is specified, stdout and stderr of the command will be logged to the file so that it could be used for later inspection. 
If not specified, the outputs will not be logged.
The logfile can be a C<strftime> format. eg. '%Y-%m-%d.log'. (NOTICE: '%' must be escaped in crontab.)

=head2 reporter|error_reporter|common_reporter

C<common_reporter> is optional, processing after C<(error_)?reporter> is handled.

The C<reporter>, C<error_reporter> and C<common_reporter> can be like following.

=over

=item C<< $module_name >>

=item C<< [$module_name[, \%opt], ...] >>

=item C<< $coderef >>

=back

I<$module_name> package name of the plugin. You can write it as two form like L<Plack::Middleware>:

    reporter => 'Stdout',    # => loads App::RunCron::Reporter::Stdout

If you want to load a plugin in your own name space, use the '+' character before a package name, like following:

    reporter => '+MyApp::Reporter::Foo', # => loads MyApp::Reporter::Foo

=head2 announcer

Package name of an "Announcer" which announce job information before running the job. (Optional)

=head2 METHODS AND ACCESORS

=head3 C<< $self->run >>

Running the job.

=head3 C<< my $str = $self->result_line >>

One line result string of the command.

=head3 C<< my $str = $self->report >>

Retrieve the output of the command.

=head3 C<< my $bool = $self->is_success >>

command is success or not.

=head3 C<< my $int = $self->exit_code >>

same as C<$?>

=head3 C<< my $int = $self->child_exit_code >>

exit code of child process.

=head3 C<< my $int = $self->child_signal >>

signal number if chile process accepted a signal.

=head1 SEE ALSO

L<runcron>, L<cronlog|https://github.com/kazuho/kaztools/blob/master/cronlog>

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut
