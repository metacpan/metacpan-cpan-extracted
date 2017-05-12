package App::MultiModule::Tasks::NagiosCmd;
$App::MultiModule::Tasks::NagiosCmd::VERSION = '1.161330';
use 5.010;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Nagios::Passive;

use parent 'App::MultiModule::Task';


=head1 NAME

App::MultiModule::Tasks::NagiosCmd - Submit passive checks to Nagios

=cut

=head2 message

=cut

sub message {
    my $self = shift;
    my $message = shift;
    foreach my $field_name ('nagios_check_name', 'nagios_host_name', 'nagios_service_description', 'nagios_return_code', 'nagios_output') {
        if(not defined $message->{$field_name}) {
            $self->error("App::MultiModule::Tasks::NagiosCmd::message: required field '$field_name' not found", message => $message);
            return;
        }
    }
    if(     $message->{nagios_return_code} != 0 and
            $message->{nagios_return_code} != 1 and
            $message->{nagios_return_code} != 2 and
            $message->{nagios_return_code} != 3) {
        $self->error("App::MultiModule::Tasks::NagiosCmd::message: required field 'nagios_output' must be one of 0, 1, 2 or 3", message => $message);
        return;
    }
    my $nagios_commands = $self->{state}->{nagios_commands};
    $message->{NagiosCmd_receive_ts} = time;
    push @{$nagios_commands}, $message;

    my $max_messages = $self->{config}->{max_messages} || 10000;
    if(scalar @{$nagios_commands} > $max_messages) {
        $self->error('App::MultiModule::Tasks::NagiosCmd::message: max cached nagios command count exceeded, dropping oldest command',
            max_messages => $max_messages,
            dropped_message => $nagios_commands->[0]
        );
        shift @{$nagios_commands};
    }
}

sub _write_tick {
    my $self = shift;
    my $nagios_commands = $self->{state}->{nagios_commands};
    return unless scalar @$nagios_commands; #no work
    if(my $command_file_err = _validate_command_file($self->{state}->{command_file})) {
        $self->error("App::MultiModule::Tasks::NagiosCmd::_write_tick: $command_file_err");
        return;
    }
    WHILE:
    while($nagios_commands->[0]) {
        my $cmd = $nagios_commands->[0];
        eval {
            local $SIG{ALRM} = sub { die "timed out\n"; };
            alarm 5;
            my $np = Nagios::Passive->create(
                command_file        => $self->{state}->{command_file},
                service_description => $cmd->{nagios_service_description},
                host_name           => $cmd->{nagios_host_name},
                check_name          => $cmd->{nagios_check_name},
            ) or die 'Nagios::Passive->create() returned false';
            my $ret = $np->return_code($cmd->{nagios_return_code});
            die 'Nagios::Passive->return_code() returned undefined'
                if not defined $ret;
            $ret = $np->output($cmd->{nagios_output});
            die 'Nagios::Passive->output() returned undefined'
                if not defined $ret;
            $np->submit
                or die 'Nagios::Passive->submit() returned false';
        };
        alarm 0;
        if($@) {
            $self->error("App::MultiModule::Tasks::NagiosCmd::_write_tick: failed: $@", cmd => $cmd);
            print STDERR "NagiosCmd: _write_tick: \$err=$@\n";
            last WHILE;
        }
        $self->_cmd_log($cmd);
        shift @$nagios_commands;
    }
}

sub _validate_command_file {    #return false means good
                                #true return is the text of the problem
    my $command_file = shift;

    my $ret = eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 2;
        return "command_file $command_file does not exist"
            unless -e $command_file;
        return "command_file $command_file is not writable"
            unless -w $command_file;
        return "command_file $command_file is not of file type pipe"
            unless -p $command_file;
        return 0;
    };
    alarm 0;
    return "command_file $command_file _validate_command_file exception: $@"
        if $@;
    return $ret;
}

sub _cmd_log {
    my $self = shift;
    my $config = $self->{config};
    my $cmd = shift;
    my $logfile = $config->{cmd_log} || 'nagios_cmd.log';
    eval {
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 2;
        my $now = scalar localtime;
        open my $fh, '>>', $logfile
            or die "failed to open $logfile for writing: $!";
        print $fh "$now: \"$cmd->{nagios_service_description}\" \"$cmd->{nagios_host_name}\" $cmd->{nagios_return_code} \"$cmd->{nagios_check_name}\" \"$cmd->{nagios_output}\"\n"
            or die "failed to write to $logfile: $!";
        close $fh or die "failed to close $logfile: $!";
    };
    alarm 0;
    if($@) {
        $self->error("App::MultiModule::Tasks::NagiosCmd::_cmd_log failed: $@", cmd => $cmd);
    }
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    $self->{state} = {} unless $self->{state};
    $self->{state}->{nagios_commands} = []
        unless $self->{state}->{nagios_commands};
    if(not $self->{config}->{command_file}) {
        $self->error("App::MultiModule::Tasks::NagiosCmd::set_config: required config 'command_file' not found");
        return;
    }
    if(my $command_file_err = _validate_command_file($self->{config}->{command_file})) {
        $self->error("App::MultiModule::Tasks::NagiosCmd::set_config: $command_file_err");
        return;
    }
    $self->{state}->{command_file} = $self->{config}->{command_file};
    $self->named_recur(
        recur_name => 'NagiosCmd_write_tick',
        repeat_interval => 1,
        work => sub {
            $self->_write_tick();
        },
    );
}

=head2 is_stateful

=cut
sub is_stateful {
    return 'definitely, because we need to queue up failed writes';
}

=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/perl-App-MultiModule-Tasks-NagiosCmd/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::NagiosCmd


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/perl-App-MultiModule-Tasks-NagiosCmd/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-NagiosCmd>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-NagiosCmd>

=item * Search CPAN

L<https://metacpan.org/module/App::MultiModule::Tasks::NagiosCmd>

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

1; # End of App::MultiModule::Tasks::NagiosCmd
