package AlignDB::Run;
use Moose;
use POE;
use POE::Wheel::Run;
use POE::Filter::Line;

our $VERSION = '1.0.2';

has parallel => ( is => 'rw', isa => 'Int',      default => sub {4}, );
has jobs     => ( is => 'rw', isa => 'ArrayRef', default => sub { [] }, );
has code => ( is => 'rw', isa => 'CodeRef', required => 1 );
has opt => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub BUILD {
    my $self = shift;

    POE::Session->create(
        inline_states => {
            _start       => sub { $_[KERNEL]->yield("next_task") },
            next_task    => \&_next_task,
            task_message => sub { print "$_[ARG0]\n"; },
            task_done    => \&_task_done,
            sig_child    => \&_sig_child,
        },
        heap => {
            parallel => $self->parallel,
            jobs     => $self->jobs,
            code     => $self->code,
            opt      => $self->opt,
            count    => 0,
            all      => scalar @{ $self->jobs },
        },
    );
}

sub run {

    # Run until there are no more tasks.
    $poe_kernel->run;
}

sub _next_task {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    my $parallel = $heap->{parallel};
    my $jobs     = $heap->{jobs};
    my $code     = $heap->{code};
    my $opt      = $heap->{opt};

    while (1) {
        my $running = scalar keys %{ $heap->{task} };
        last if $running >= $parallel;

        my $next = shift @{$jobs};
        last unless defined $next;

        $heap->{count}++;
        printf "===Do task %u out of %u===\n", $heap->{count}, $heap->{all};

        my $task = POE::Wheel::Run->new(
            Program => sub {

                # Required for this to work on MSWin32
                binmode(STDOUT);
                binmode(STDERR);

                $code->( $next, $opt );
            },
            StdioFilter  => POE::Filter::Line->new,
            StderrFilter => POE::Filter::Line->new,
            StdoutEvent  => 'task_message',
            StderrEvent  => 'task_message',
            CloseEvent   => 'task_done',
        );

        $heap->{task}->{ $task->ID } = $task;
        $kernel->sig_child( $task->PID, "sig_child" );
    }
}

# Delete the child wheel, and try to start a new task to take its place.
sub _task_done {
    my ( $kernel, $heap, $task_id ) = @_[ KERNEL, HEAP, ARG0 ];
    delete $heap->{task}->{$task_id};
    $kernel->yield("next_task");
}

# Detect the CHLD signal as each of our children exits.
sub _sig_child {
    my ( $heap, $sig, $pid, $exit_val ) = @_[ HEAP, ARG0, ARG1, ARG2 ];
    delete $heap->{$pid};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AlignDB::Run - Run in parallel without pains.

=head1 SYNOPSIS

    use AlignDB::Run;

    my $worker = sub {
        my $job = shift;

        print "$job\n";
        return;
    };

    my $run = AlignDB::Run->new(
        parallel => 4,
        jobs     => [1 .. 8],
        code     => $worker,
        opt      => {foo => "bar",}
    );
    $run->run;

=head1 ATTRIBUTES

C<parallel> - run in parallel mode

C<jobs> - All jobs to be done

C<code> - code ref

C<opt> - hash ref

=head1 METHODS

=head2 run

Start run your code

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009- by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
