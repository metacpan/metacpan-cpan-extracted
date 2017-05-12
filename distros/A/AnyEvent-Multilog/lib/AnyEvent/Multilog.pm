package AnyEvent::Multilog;
# ABSTRACT: event-driven interface to a multilog process
use Moose;
use MooseX::Types::Path::Class qw(File);

use AnyEvent::Subprocess;
use AnyEvent::Subprocess::Job::Delegate::Handle;

our $VERSION = '0.01';

use namespace::autoclean;

has 'multilog' => (
    is            => 'ro',
    isa           => File,
    predicate     => 'has_multilog_path',
    coerce        => 1,
    documentation => q{path to multilog, if you don't want to use $PATH},
);

has 'script' => (
    is            => 'ro',
    isa           => 'ArrayRef[Str]',
    required      => 1,
    documentation => 'multilog "script", not escaped for the shell',
);

has '_job' => (
    init_arg => undef,
    reader   => '_job',
    lazy     => 1,
    builder  => '_build_job',
);

has 'job_args' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

has 'run' => (
    init_arg   => undef,
    reader     => 'run',
    lazy_build => 1,
);

has 'on_exit' => (
    is            => 'ro',
    isa           => 'CodeRef',
    predicate     => 'has_exit_handler',
    documentation => 'optional callback called when multilog exists successfully',
);

has 'on_error' => (
    is            => 'ro',
    isa           => 'CodeRef',
    predicate     => 'has_error_handler',
    documentation => 'optional callback called when multilog emits an error',
);

has 'errors' => (
    is       => 'bare', # uh, no it's not, but mooose bug
    init_arg => undef,
    traits   => ['Array'],
    default  => sub { [] },
    lazy     => 1,
    handles  => {
        push_error => 'push',
        has_errors => 'count',
        errors     => 'elements',
    },
);

has 'is_shutdown' => (
    init_arg  => undef,
    accessor => 'is_shutdown',
    isa      => 'Bool',
);

has 'leftover_data' => (
    init_arg  => undef,
    reader    => 'leftover_data',
    writer    => 'set_leftover_data',
    predicate => 'has_leftover_data',
);


sub ensure_validity {
    my $self = shift;
    confess 'already shutdown, cannot perform further operations' if $self->is_shutdown;
    confess(join ', ', $self->errors) if $self->has_errors;
}

sub _build_job {
    my $self = shift;

    my $input = AnyEvent::Subprocess::Job::Delegate::Handle->new(
        name           => 'input_handle',
        direction      => 'w',
        replace        => 0,
        want_leftovers => 1,
    );

    my $errors = AnyEvent::Subprocess::Job::Delegate::Handle->new(
        name      => 'error_handle',
        direction => 'r',
        replace   => 2,
    );

    my $extra_delegates = delete $self->job_args->{delegates} || [];

    my $multilog = $self->has_multilog_path ? $self->multilog->stringify : 'multilog';

    return AnyEvent::Subprocess->new(
        %{ $self->job_args },
        delegates     => [ @{$extra_delegates}, $input, $errors ],
        on_completion => sub { $self->handle_completion($_[0]) },
        code          => [ $multilog, @{$self->script} ],
    );
}

sub _build_run {
    my $self = shift;
    my $run = $self->_job->run;

    my $errors = $run->delegate('error_handle');

    my $error_cb; $error_cb = sub {
        my ($h, $line, $eol) = @_;
        $self->handle_error($line);
        $h->push_read( line => $error_cb );
    };
    $errors->handle->push_read( line => $error_cb );

    $run->delegate('input_handle')->handle->{linger} = 0;

    return $run;
}

sub handle_error {
    my ($self, $msg) = @_;
    $self->on_error->($msg) if $self->has_error_handler;
    $self->push_error($msg);
    return;
}

sub handle_completion {
    my ($self, $done) = @_;
    my ($success, $msg);

    $self->set_leftover_data( $done->delegate('input_handle')->wbuf )
        if $done->delegate('input_handle')->has_wbuf;

    if($done->exit_value == 111){
        $success = 0;
        $msg = 'out of memory, or another multilog '.
            'process is touching your files';
    }

    elsif($done->exit_value == 0 && $self->has_leftover_data ){
        $success = 1;
        $msg = 'normal exit, with leftover data';
    }

    elsif($done->is_success){
        $success = 1;
        $msg = 'normal exit';
    }

    else {
        $success = 0;
        $msg = 'abnormal exit with signal '. $done->exit_signal;
    }

    $self->on_exit->($success, $msg, $done) if $self->has_exit_handler;
    return;
}

sub start {
    my $self = shift;
    confess 'already started' if $self->has_run;
    return $self->run;
}

sub push_write {
    my ($self, $line) = @_;
    $self->ensure_validity;
    $line .= "\n" if $line !~ /(?:\r\n|\r|\n)$/;
    $self->run->delegate('input_handle')->handle->push_write($line);
}

sub push_shutdown {
    my $self = shift;
    $self->run->kill('TERM');
}

sub rotate {
    my $self = shift;
    $self->run->kill('ALRM');
}

sub shutdown {
    my $self = shift;
    my $input = $self->run->delegate('input_handle');
    confess 'already shutdown, cannot perform further operations' if $self->is_shutdown;
    $input->handle->do_not_want;
}

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

AnyEvent::Multilog - event-driven interface to a multilog process

=head1 VERSION

version 1.102861

=head1 SYNOPSIS

    my $log = AnyEvent::Multilog->new(
        script => [qw{t +* ./log}],
    );

    $log->start;
    $log->push_write('log message');
    $log->push_write('another log message');
    $log->rotate;
    $log->push_write('another log message in a new log file');
    $log->shutdown;

=head1 DESCRIPTION

This module makes it easy to log via a multilog process.  It handles
spawning the multilog process and handling its errors.

=head1 ATTRIBUTES

=head2 script

Required.

This is an ArrayRef representing the multilog script that describes
how to log.  See the L<multilog|multilog man page> for more
information on what this script is and how to write one.

Note that the shell is never invoked, so you don't need to escape
anything from the shell.

To select all lines, add a tai64n timestamp, and log to a directory
called "log", your script should be C<['t', '+*', './log']>.

=head2 multilog

Optional.

The path to the multilog binary.  By default, checks C<$PATH> and uses
the one in there.

=head2 on_exit

Optional.

Coderef that is called when the multilog process exists, successfully
or otherwise.

Your coderef is passed three arguments, a boolean indicating
successful exit, a message indicating why multilog exited, and the
L<AnyEvent::Subprocess::Done> object representing the exited
subprocess.

=head2 on_error

Optional.

Coderef to be called when multilog writes something to stderr.  It's
assumed that logging can't proceed after something is read from
stderr, so all methods will die regardless of whether or not you
handle this callback.  Handling this event lets you proactively spawn
a new logger and kill this one without losing any messages.

Patch welcome to make this automatic.  I can't get multilog to die on
my machine.

=head1 METHODS

=head2 start

Call this when you are ready to fork off the multilog and start
logging.  If you call another method before calling this, the results
are undefined.

=head2 push_write

Send a line to multilog.  If you don't provide a newline, one will be
provided for you.

=head2 rotate

Ask multilog to rotate the log right now.

=head2 push_shutdown

Ask multilog to shut down after writing the current line to disk.  Any
pending data is made available via C<< $self->leftover_data >>, which
can be checked for with C<< $self->has_leftover_data >>.

When multilog is done writing, your C<on_exit> callback will be
called.

=head2 shutdown

Shutdown immediately by closing the file descriptor that multilog is
reading from.

When multilog is done writing, your C<on_exit> callback will be
called.

=head2 is_shutdown

Returns true if multilog is done.

=head2 has_leftover_data

Returns true if multilog exited without reading some data we asked it
to log.

=head2 leftover_data

Returns any data that multilog did not write before exiting.

=head2 has_errors

Returns true if errors were encourntered.

=head2 errors

Returns a list of errors that were encountered.

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

