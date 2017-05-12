package Continual::Process;
use strict;
use warnings;

our $VERSION = '0.2.0';

use POSIX qw(:sys_wait_h);
use Continual::Process::Instance;
use Class::Tiny qw(name code), { instances => 1, };

=head1 NAME

Continual::Process - (re)start dead process

=head1 SYNOPSIS

    use Continual::Process;
    use Continual::Process::Loop;

    my $loop = Continual::Process::Loop->new(
        instances => [
            Continual::Process->new(
                name => 'job1',
                code => sub {
                    my $pid = fork;
                    if ($pid) {
                        return $pid;
                    }

                    say "Hello world";
                    sleep 5;
                    say "Bye, bye world";

                    exit 1;
                },
                instances => 4,
            )->create_instance(),
            Continual::Process->new(
                name => 'job2',
                code => sub {
                    my $pid = fork;
                    if ($pid) {
                        return $pid;
                    }

                    exec 'perl -ne "sleep 1"';

                    exit 1;
                },
            )->create_instance(),
        ]
    );

    $loop->run();

=head1 DESCRIPTION

Continual::Process with Continual::Process::Loop is a way how to run a process forever.

Continual::Process creates Continual::Process::Instance which runs in a loop and if it dies, it starts again.

The code for starting a process is OS-agnostic. The only condition is that the code must return PID of the new process.

=head2 loop

Continual::Process supports more loops:

=over 1

=item L<Continual::Process::Loop::Simple> - simple while/sleep loop

=item L<Continual::Process::Loop::AnyEvent> - L<AnyEvent> support

=item L<Continual::Process::Loop::Mojo> - L<Mojo::IOLoop> support

=back

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 name

name of process (only for identification)

=head4 code

CodeRef which start new process and returned C<PID> of new process

I<code>-sub B<must> return C<PID> of the new process or die!

for example Linux and fork:

    code => sub {
        if (my $pid  = fork) {
            return $pid;
        }

        ...

        exit 1;
    }

or Windows and L<Win32::Process>

    code => sub {
        my ($instance) = @_;

        Win32::Process::Create(
            $ProcessObj,
            "C:\\winnt\\system32\\notepad.exe",
            "notepad temp.txt",
            0,
            NORMAL_PRIORITY_CLASS,
            "."
        ) || die "Process ".$instance->name." start fail: ".$^E;

        return $ProcessObj->GetProcessID();
    }

best way is use L<Continual::Process::Helper> C<prepare_fork> or C<prepare_run> method

=head4 instances

count of running instances

default I<1>

=cut

sub BUILD {
    my ($self) = @_;

    foreach my $req (qw/name code/) {
        die "$req attribute required" if !defined $self->$req;
    }

    if (ref $self->code ne 'CODE') {
        die 'code attribute must be CodeRef';
    }
}

=head2 create_instance()

create and return list of L<Continual::Process::Instance>

=cut
sub create_instance {
    my ($self) = @_;

    my @instances;

    foreach my $instance_id (1 .. $self->instances) {
        push @instances,
          Continual::Process::Instance->new(
            name          => $self->name,
            instance_id   => $instance_id,
            code          => $self->code,
          );
    }

    return @instances;
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
