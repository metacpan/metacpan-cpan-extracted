package Async::Simple::Task::ForkTmpFile;

=head1 NAME

    Async::Simple::Task::ForkTmpFile - Forks child process.
    It waits for "data" whic will be passed via "put", and executed "sub" with this "data" as an argument.
    Result of execution will be returned to parent by "get".

    The behaviour of this class all the same as of Async::Simple::Task::Fork
    except that it use files as interprocess transport instead of pipes.

    This class is recommended only as workaround for systems which don't support
    bidirectional pipes.

=head1 SYNOPSIS

    use Async::Simple::Task::ForkTmpFile;

    my $sub  = sub { sleep 1; return $_[0]{x} + 1 };                    # Accepts $data as @_ and returns any type you need

    my $task = Async::Simple::Task::ForkTmpFile->new( task => &$sub );  # Creates a child process, which waits for data and execute &$sub if data is passed

    my $data = { x => 123 };                                            # Any type you wish: scalar, array, hash

    $task->put( $data );                                                # Put a task data to sub in the child process

    # ...do something useful in parent while our data working ...

    my $result = $task->get; # result = undef because result is not ready yet
    sleep 2; # or do something else....
    my $result = $task->get; # result = 2

    $task->put( $data );                                           # Put another data to task sub and so on,....

Result and data can be of any type and deep which can be translated via Data::Serializer->new( serializer => Storable ) # by default

If your "sub" can return undef you should check $task->has_result, as a mark that result is ready.


=head1 DESCRIPTION

Allows to initialize fork process.

After that, executes "sub" for each "data" passed to child process.


=head1 METHODS

=head2 C<new>

Forks a process

    my $task = Async::Simple::Task::ForkTmpFile->new( task => &$sub, %other_optional_params );

Params (all param except "task" are optional):

    task         => coderef, function, called for each "data" passed to child process via $task->put( $data );

    timeout      => timeout in seconds between child checkings for new data passed. default 0.01

    kill_on_exit => kill (1) or not (0) subprocess on object destroy (1 by default).


=head2 C<put>

Puts data to task.

    $self->put( $data );


=head2 C<get>

Tries to read result from task.

Returns undef if it is not ready.

In case, your function can return undef, you shoud check $task->has_answer, as a mark of ready result.

    my $result = $self->get();


=head1 SUPPORT AND DOCUMENTATION

    After installing, you can find documentation for this module with the perldoc command.

    perldoc Async::Simple::Task::ForkTmpFile

    You can also look for information at:

        RT, CPAN's request tracker (report bugs here)
            http://rt.cpan.org/NoAuth/Bugs.html?Dist=Async-Simple-Task-ForkTmpFile

        AnnoCPAN, Annotated CPAN documentation
            http://annocpan.org/dist/Async-Simple-Task-ForkTmpFile

        CPAN Ratings
            http://cpanratings.perl.org/d/Async-Simple-Task-ForkTmpFile

        Search CPAN
            http://search.cpan.org/dist/Async-Simple-Task-ForkTmpFile/


=head1 AUTHOR

ANTONC <antonc@cpan.org>

=head1 LICENSE

    This program is free software; you can redistribute it and/or modify it
    under the terms of the the Artistic License (2.0). You may obtain a
    copy of the full license at:

    L<http://www.perlfoundation.org/artistic_license_2_0>

=cut


use Modern::Perl;
use Moose;
use namespace::autoclean;
use Data::Serializer;
use Time::HiRes qw/ alarm sleep /;
use File::Temp ();

our $VERSION = '0.12';

extends 'Async::Simple::Task::Fork';


=head1 Attributes

=head2 task

    task = sub {
        my ( $data ) = @_; # source data for task
        ... your task code ...
        return( $result );
    }

=cut


=head2 answer

Result of current task

=cut


=head2 has_answer

has_answer is true, if the task has been finished and result has been ready

=cut


=head2 timeout

timeout - positive numeric value = seconds between checking for result.

inherited from Async::Simple::Task.

=cut


=head2 kill_on_exit

Kills process from parent in case of object desctuction

=cut


=head2 new()

    my $task = Async::Simple::Task::ForkTmpFile->new( %all_optional_params );


Possible keys for %all_optional_params:

    task         => coderef, function, called for each "data" passed to child process via $task->put( $data );

    timeout      => timeout in seconds between child checkings for new data passed. default 0.01

    kill_on_exit => kill (1) or not (0) subprocess on object destroy (1 by default).

=cut


=head2 BUILD

internal. Some tricks here:)

    1. Master process called $task->new with fork() inside
    2. After forking done we have two processes:
    2.1. Master gets one side of reader/writer tmp file handlers and pid of child
    2.2. Child - another side of tmp file handlers and extra logic with everlasting loop

=cut


=head2 fork_child

Makes child process and returns pid of child process to parent or 0 to child process

=cut

sub fork_child {
    my ( $self ) = @_;

    # Connections via tmp files: parent -> child and child -> parent
    my $parent_writer = File::Temp->new();
    my $parent_reader = File::Temp->new();

    my $parent_writer_fname = $parent_writer->filename;
    my $parent_reader_fname = $parent_reader->filename;


    my $pid = fork() // die "fork() failed: $!";

    # child
    unless ( $pid ) {
        open( my $child_reader, '<', $parent_writer_fname );
        open( my $child_writer, '>', $parent_reader_fname );

        $child_writer->autoflush(1);

        $self->writer( $child_writer );
        $self->reader( $child_reader );

        # Important!
        # Just after that we trap into BUILD
        # with the infinitive loop for child process (pid=0)
        return 0;
    }

    # parent
    $parent_writer->autoflush(1);

    $self->writer( $parent_writer );
    $self->reader( $parent_reader );

    return $pid;
};


=head2 get

Reads from task, if something can be readed or returns undef after timeout.

    my $result = $task->get;

Please note! If your function can return an undef value, then you shoud check

    $task->has_result.

=cut

sub get {
    my ( $self ) = @_;

    my $fh = $self->reader;
    my $data;

    # Try to read "marker" into data within timeout
    # Each pack starts with an empty line and serialized string of useful data.
    eval {
        local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
        alarm $self->timeout;
        $data = <$fh>;
        alarm 0;
    } or do {
        # Can't read data
        return unless $data;
        # Alarm caught but something readed, will continue
        undef $@;
    };

    return unless defined $data;
    return unless $data eq "-\n";

    # Read useful data without any timeouts
    # or die, if parent/child has closed connection
    undef $data;

    for ( 1..1000 ) {
        $data = <$fh>;
        last  if defined $data;
        sleep $self->timeout;
    }

    return unless defined $data;

    my $answer = $data
        ? eval{ $self->serializer->deserialize( $data )->[0] }
        : undef;

    $self->answer( $answer );
};


=head2 put

Writes task to task.

    $task->put( $data );

=cut


=head2 get_serializer

Internal. Returns an object that must have 2 methods: serialize and deserialize.
By default returns Data::Serializer with Storable as backend.

    $self->serializer->serialize( $task_data_ref );

    $result_ref = $self->serializer->deserialize();

=cut


__PACKAGE__->meta->make_immutable;
