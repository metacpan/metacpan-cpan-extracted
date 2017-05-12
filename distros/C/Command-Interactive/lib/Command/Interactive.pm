package Command::Interactive;
# ABSTRACT: handles interactive (and non-interactive) process invocation

use strict;
use warnings;

our $VERSION = 1.4;

use Moose;


=head1 NAME

Command::Interactive- handles interactive (and non-interactive) process invocation through a reliable and easily configured interface.

=head1 SYNOPSIS

This module can be used to invoke both interactive and non-interactive commands with predicatable results.

    use Command::Interactive;
    use Carp;

    # Simple, non-interactive usage
    my $result1 = Command::Interactive->new->run("cp foo /tmp/");
    croak "Could not copy foo to /tmp/: $result!" if($result);

    # Interactive usage supports output parsing
    # and automated responses to discovered strings
    my $password_prompt = Command::Interactive::Interaction->new({
        expected_string => 'Please enter your password:',
        response        => 'secret',
    });

    my $command = Command::Interactive->new({
        echo_output    => 1,
        output_stream  => $my_logging_fh,
        interactions   => [ $password_prompt ],
    });
    my $restart_result = $command->run("ssh user@somehost 'service apachectl restart'");
    if($restart_result)
    {
        warn "Couldn't restart server!";
    }

=cut

use Command::Interactive::Interaction;
use IO::File;
use Carp;
use Expect;

=head1 FIELDS

=head2 always_use_expect (DEFAULT: FALSE)

Whether to use the C<Expect> module to execute system commands. By default, Expect is only used if one or more interactions() are specified.

=cut

has always_use_expect => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 debug_logfile (DEFAULT: undef)

The name of a file to which lots of debugging information should be written. Typically useful only for maintainers. If you want to see what your command is doing, use echo_output() and a debugging filehandle (or just STDOUT).

=cut

has debug_logfile => (
    is  => 'rw',
    isa => 'Str',
);

=head2 echo_output (DEFAULT: FALSE)

Whether to echo output to the specified output_stream(). This allows users of
Command::Interactive to see what is going on, but it also can clutter an interface with lots of superfluous command output. Use it wisely.

See web_format() for a discussion about how to format command output for web interfaces.

=cut

has echo_output => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head2 interactions (DEFAULT: [], the empty arrayref)

An array reference of Command::Interactive::Interaction objects that specify the
interactions that may (or must) occur during the execution of the command. See
C<Command::Interactive::Interaction> for more information on specifying rules about command interactions.

=cut

has interactions => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },    # References are not allowed as defaults
);

=head2 output_stream (DEFAULT: STDOUT)

The stream object to which output should be sent when echo_output() is enabled. This is any object with a print() method; it needn't have a full C<IO>-compliant interface.

=cut

has output_stream => (
    is      => 'rw',
    default => *STDOUT,
);

=head2 timeout (DEFAULT: undef)

If defined, represents the timeout (in seconds) that Command::Interactive will wait for output when run() is called.

=cut

has timeout => (
    is  => 'rw',
    isa => 'Int',
);

=head2 web_format (DEFAULT: FALSE)

Whether to format strings for web output when print command output as a result of echo_output(). If this is true, \r, \n, and \r\n will be replaced with "<br/>\n".

=cut

has web_format => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

=head1 METHODS

=head2 run($command)

This method does the heavy lifting of Command::Interactive. If one or more interactions() are specified (or if always_use_expect() is true), then the heavy lifting is dispatched to _run_via_expect(); otherwise this method uses traditional perl C<open("$command |")> approach.

$command is expected to be a scalar (string), properly escaped, that could be
executed (e.g.) via system() or ``. No matter what command you provide, the bash
file descriptors for stdout and stderr are tied together using '2>&1' unless you
have done so already. This allows Command::Interactive to capture and react to both regular output and errors using the same mechanism.

run() returns undef if the command is successful, otherwise it returns a string describing why the command failed (or was thought to have failed).

The command you pass in via $command is expected to exit with status code 0 on
success. If it returns something different, Command::Interactive will incorrectly conclude that the command failed and will return a message to that effect.

=cut

sub run {
    my $self    = shift;
    my $command = shift;

    confess "No command provided" unless ($command);

    my $result;
    if ($self->always_use_expect or @{$self->interactions}) {
        # We'll to use Expect to handle this,
        # which means that we will be able to
        # respond to input requests
        $result = $self->_run_via_expect($command);
    } else {
        my $use_command = $self->_fixup_command_to_catch_stderr($command);
        $self->_log("Executing $use_command");
        my $cfh = IO::File->new("$use_command|");
        if ($cfh) {
            while (my $output = <$cfh>) {
                $self->_log("open() returned output: $output");
                $self->_show_output($output);
            }
            $cfh->close;
            $result = ($? >> 8) ? "Error executing $command: $!" : undef;
        } else {
            $result = "Could not execute $command: $!";
        }
    }

    $self->_log($result ? "Returning result: $result for command $command" : "Returning undef result, signifying success");
    return $result;
}

=head2 _show_output($chunk_of_output)

If echo_output() is true, this command prints any output from $command to the chosen output_stream(). If web_format() is true, the output is first formatted for HTML by replacing end-of-line characters with "<br/>\n".

=cut

sub _show_output {
    my $self   = shift;
    my $output = shift;

    return unless ($self->echo_output);

    $output =~ s/[\r\n]+/<br\/>\n/g if ($self->web_format);
    $self->_log("Stream output: $output");
    return $self->output_stream->print($output);
}

=head2 _run_via_expect($command)

This method handles running commands with one or more interactions() (or for which always_use_expect() is true) via the Perl module C<Expect>.

The return semantics of _run_via_expect() are identical to those of run().

=cut

sub _run_via_expect {
    my $self    = shift;
    my $command = shift;

    my $use_command = $self->_fixup_command_to_catch_stderr($command);

    $self->_log("Using Expect to spawn command: $use_command");

    my $exp = Expect->new;
    $exp->raw_pty(1);
    $exp->log_stdout(0);

    my $e = $exp->spawn($use_command);
    return "Could not start $command: $!" unless ($e);

    my ($expect_array, $indexed_interactions) = $self->_generate_interaction_list;

    my $result;

    my ($match_position, $error, $matched_string, $before, $after);

    my $occurrences = [];

    my $already_closed = 0;

    EXPECT_READ:
    while (!$error) {
        ($match_position, $error, $matched_string, $before, $after) = $e->expect($self->timeout, @$expect_array);
        if ($match_position) {
            # Collapse this all into string just in case
            # you have a f-ing retarded value of $/ or an
            # overridden version of CORE::print() that puts
            # newlines at the end of each print call
            my $show;
            $show .= $before if (length($before));
            $show .= $matched_string;
            $show .= $after  if (length($after));
            $self->_show_output($show);

            # Determine whether this was an interactive
            # request for a response, or an error
            $match_position -= 1;
            my $i    = $indexed_interactions->[$match_position];
            my $type = $i->type;
            $occurrences->[$match_position] = 0 unless ($occurrences->[$match_position]);
            $occurrences->[$match_position]++;
            if ($i->is_error) {
                $result = "Got error string '$matched_string', which matched error detection $type '" . $i->expected_string . "'";
                last EXPECT_READ;
            }

            if ($occurrences->[$match_position] > $i->max_allowed_occurrences) {
                $result =
                    "Got string '$matched_string', which matched expected $type '"
                  . $i->expected_string
                  . "'. This was occurrence #"
                  . $occurrences->[$match_position]
                  . ", which exceeds the specified limit of "
                  . $i->max_allowed_occurrences
                  . " occurrence(s) set for this $type";
                last EXPECT_READ;
            }
            if ($i->response) {
                $self->_log("Stream send: " . $i->response);
                $e->send($i->actual_response_to_send);
            }
        } elsif ($error) {
            if (($error eq '2:EOF') or $error =~ /3:Child PID (\d+) exited with/) {
                # Let's see if there were any required
                # interactions that failed to occur
                for (my $count = 0; $count < scalar(@$indexed_interactions); $count++) {
                    my $i = $indexed_interactions->[$count];
                    if ($i->is_required and not $occurrences->[$count]) {
                        $result = "Failed to encounter required " . $i->type . " '" . $i->expected_string . "' before exit";
                    }
                }
            } elsif ($error eq '1:TIMEOUT') {
                $result = "Got TIMEOUT from Expect (timeout=" . $self->timeout . " seconds)";
                $e->hard_close;
                $already_closed = 1;
            } elsif ($error =~ /^3: (.+)/)    # uncoverable
            {
                $result = "Failure on command: $1";
            } elsif ($error =~ /^4:(.+)/)     # uncoverable
            {
                $result = "Got error reading command filehandle: $1";
            }
            last EXPECT_READ;
        }
    }

    # Need to capture any remaining output
    $self->_show_output($e->exp_before) if ($e->exp_before);
    $e->expect(0) unless ($already_closed);
    # In case the call to expect(0) caught any remaining output
    $self->_show_output($e->exp_before) if ($e->exp_before);
    $e->soft_close unless ($already_closed);

    if ($e->exitstatus and not defined($result)) {
        $result = 'Got back return value ' . $e->exitstatus . " from $command";
    }

    return $result;
}

=head2 _generate_instruction_list()

This method returns information to be passed to C<Expect>'s expect() method, as well as a bookkeeping array using for tracking number of times a given interaction has occurred.

=cut

sub _generate_interaction_list {
    my $self = shift;

    my $expect_array         = [];
    my $indexed_interactions = [];

    my $counter;
    foreach my $i (@{$self->interactions}) {
        push @$expect_array, '-re' if ($i->expected_string_is_regex);
        push @$expect_array, $i->expected_string;
        push @$indexed_interactions, $i;
    }

    return ($expect_array, $indexed_interactions);

}

=head2 _fixup_command_to_catch_stderr($original_command)

This method appends '2>&1' to the end of any command submitted to run(), except when that filehandle-tying string is already present in the command.

Returns the modified version of $original_command.

=cut

sub _fixup_command_to_catch_stderr {
    my $self             = shift;
    my $original_command = shift;

    my $use_command = $original_command;
    $use_command .= " 2>&1" unless ($use_command =~ m#2>&1#);
    return $use_command;
}

=head2 _log($line_to_log)

Used for internal logging purposes when debug_logfile() is defined. See the
discussion of debug_logfile() for a better way to debug YOUR command's
execution; this method is intended for consumption by developers of
Command::Interactive.

=cut

sub _log {
    my $self    = shift;
    my $message = shift;

    my $result;

    if ($self->debug_logfile) {
        my $f = IO::File->new(">>" . $self->debug_logfile);
        croak("Could not open debugging log file " . $self->debug_logfile) unless ($f);
        my $result = $f->print(map { POSIX::strftime("[%Y-%m-%dT%H:%M:%SZ] $_\n", gmtime) } split(/[\r\n]/, $message));
        $f->close;
    }

    return $result;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Binary.com, <perl@binary.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

