package App::MultiModule::Tasks::Runner;
$App::MultiModule::Tasks::Runner::VERSION = '1.161390';
use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Storable;
use POE qw( Wheel::Run );
use JSON;

use parent 'App::MultiModule::Task';

=head1 NAME

App::MultiModule::Tasks::Runner - Run external programs under App::MultiModule

=cut

{
my $ps_cache;
my $cache_ts;
sub _is_running {
    my $regex = shift or die 'is_running: regex required';
    $cache_ts = 0 unless defined $cache_ts;
    my $time = time;
    if($time - 5 > $cache_ts) {
        $cache_ts = $time;
        undef $ps_cache;
    }
    if(not $ps_cache) {
        $ps_cache = `ps -eo cmd`;
    }
    return $ps_cache =~ /$regex/;
}

=head2 message

=cut

sub message {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    $self->debug('message', message => $message)
        if $self->{debug} > 5;
    my $state = $self->{state};
    $state->{running_progs} = {} unless $state->{running_progs};
    my $prog = $message->{runner_program_prog}
        or die 'run_program: runner_program_prog required';
    my $prog_args = Storable::dclone($message->{runner_program_args});
    $prog_args = [] unless $prog_args;
    die 'run_program: runner_program_args must be an ARRAY or HASH reference'
        if      not ref $prog_args or
                (   ref $prog_args ne 'ARRAY' and
                    ref $prog_args ne 'HASH');
    if(ref $prog_args eq 'HASH') {
        my @args = ();
        my @sorted_arg_numbers = sort { $a <=> $b } keys %$prog_args;
        foreach my $arg_number (@sorted_arg_numbers) {
            push @args, $prog_args->{$arg_number};
        }
        $prog_args = \@args;
    }
    my $prog_run_key = "$prog," . join ',',@$prog_args;
    my $prog_regex = $message->{runner_process_regex}
        or die 'run_program: runner_process_regex required';
    $message->{runner_return_type} = 'gather'
        unless $message->{runner_return_type};
    my $return_type = $message->{runner_return_type};
    die 'run_program: runner_return_type must be one of "json", "gather"'
        if $return_type ne 'json' and $return_type ne 'gather';
    if($return_type eq 'gather') {
        $message->{runner_stdout} = '';
        $message->{runner_stderr} = '';
    }

    if($state->{running_progs}->{prog_run_key} or _is_running($prog_regex)) {
        $message->{runner_message_type} = 'already running';
        $self->emit($message);
        return;
    }
    undef $ps_cache;
    my $on_start = sub {
        my $child = POE::Wheel::Run->new(
            Program => [ $prog, @$prog_args],
            StdoutEvent  => 'got_child_stdout',
            StderrEvent  => 'got_child_stderr',
            CloseEvent   => 'got_child_close',
        );

        $_[KERNEL]->sig_child($child->PID, 'got_child_signal');
        $_[HEAP]{children_by_wid}{$child->ID} = $child;
        $_[HEAP]{children_by_pid}{$child->PID} = $child;
        $message->{runner_start_time} = time;
        $message->{runner_pid} = $child->PID;
        $message->{runner_message_type} = 'start';
        $message->{runner_prog_run_key} = $prog_run_key;
        my $send_message = Storable::dclone($message);
        $self->emit($send_message);
        delete $message->{runner_message_type};
        $state->{running_progs}->{$prog_run_key} = $message;
    };
    # Wheel event, including the wheel's ID.
    my $on_child_stdout = sub {
        my ($stdout_line, $wheel_id) = @_[ARG0, ARG1];
        my $child = $_[HEAP]{children_by_wid}{$wheel_id};
        if($return_type eq 'gather') {  #simply gather all of
            $message->{runner_stdout} .= "$stdout_line\n";
        } elsif($return_type eq 'json') {
            $message->{runner_stdout} .= "$stdout_line\n";
            my $emit = eval {
                return decode_json $message->{runner_stdout};
            };
            if($emit) {
                $message->{runner_stdout} = '';
                $self->emit($emit);
            }
        }
    };

    # Wheel event, including the wheel's ID.
    my $on_child_stderr = sub {
        my ($stderr_line, $wheel_id) = @_[ARG0, ARG1];
        my $child = $_[HEAP]{children_by_wid}{$wheel_id};
        if($return_type eq 'gather') {  #simply gather all of
            $message->{runner_stderr} .= "$stderr_line\n";
        }
    };

    # Wheel event, including the wheel's ID.
    my $on_child_close = sub {
        my $wheel_id = $_[ARG0];
        my $child = delete $_[HEAP]{children_by_wid}{$wheel_id};

        undef $ps_cache;
        unless (defined $child) {
            return;
        }

        delete $_[HEAP]{children_by_pid}{$child->PID};
    };

    #This is where we're claiming the child is gone
    my $on_child_signal = sub {
        my $child = delete $_[HEAP]{children_by_pid}{$_[ARG1]};
        $message->{runner_message_type} = 'finish';
        $message->{runner_exit_code} = $_[ARG2] >> 8;
        $message->{runner_run_time} = time - $message->{runner_start_time};

        if($return_type eq 'gather') {
            #noop, because we've already gathered the STDOUT/ERR
        } elsif($return_type eq 'json') {
            #noop, because we've already sent any and all messages
        }
        if($message->{runner_stderr_to_stdout}) {
            $message->{runner_stdout} .= $message->{runner_stderr};
            $message->{runner_stderr} = '';
        }
        $self->emit($message);
        # May have been reaped by on_child_close().
        return unless defined $child;

        delete $_[HEAP]{children_by_wid}{$child->ID};
    };
    POE::Session->create(
        inline_states => {
            _start           => $on_start,
            got_child_stdout => $on_child_stdout,
            got_child_stderr => $on_child_stderr,
            got_child_close  => $on_child_close,
            got_child_signal => $on_child_signal,
        }
    );
}
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    my $state = $self->{state};
}


=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/perl-App-MultiModule-Tasks-Runner/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::Runner


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/perl-App-MultiModule-Tasks-Runner/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-Runner>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-Runner>

=item * Search CPAN

L<https://metacpan.org/module/App::MultiModule::Tasks::Runner>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Dana M. Diederich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::MultiModule::Tasks::Runner
