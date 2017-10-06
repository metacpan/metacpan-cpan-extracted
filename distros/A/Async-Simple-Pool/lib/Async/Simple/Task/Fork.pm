package Async::Simple::Task::Fork;

=head1 NAME

    Async::Simple::Task::Fork - Forks child process.
    It waits for "data" whic will be passed via "put", and executed "sub" with this "data" as an argument.
    Result of execution will be returned to parent by "get".


=head1 SYNOPSIS

    use Async::Simple::Task::Fork;

    my $sub  = sub { sleep 1; return $_[0]{x} + 1 };             # Accepts $data as @_ and returns any type you need

    my $task = Async::Simple::Task::Fork->new( task => &$sub );  # Creates a child process, which waits for data and execute &$sub if data is passed

    my $data = { x => 123 };                                     # Any type you wish: scalar, array, hash

    $task->put( $data );                                         # Put a task data to sub in the child process

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

    my $task = Async::Simple::Task::Fork->new( task => &$sub, %other_optional_params );

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

    perldoc Async::Simple::Task::Fork

    You can also look for information at:

        RT, CPAN's request tracker (report bugs here)
            http://rt.cpan.org/NoAuth/Bugs.html?Dist=Async-Simple-Task-Fork

        AnnoCPAN, Annotated CPAN documentation
            http://annocpan.org/dist/Async-Simple-Task-Fork

        CPAN Ratings
            http://cpanratings.perl.org/d/Async-Simple-Task-Fork

        Search CPAN
            http://search.cpan.org/dist/Async-Simple-Task-Fork/


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




our $VERSION = '0.18';


extends 'Async::Simple::Task';


=head1 Attributes

=head2 task

    task = sub {
        my ( $data ) = @_; # source data for task
        ... your task code ...
        return( $result );
    }

=cut

has task => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
);


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

has kill_on_exit => (
    is       => 'rw',
    isa      => 'Int',
    default  => 1,
);


#  Writable pipe between parent and child.
#  Each of them has pair of handlers, for duplex communication.
has writer => (
    is       => 'rw',
    isa      => 'FileHandle',
);


#   Readable pipe between parent and child.
#   Each of them has pair of handlers, for duplex communication.
has reader => (
    is       => 'rw',
    isa      => 'FileHandle',
);


#    Object that must have 2 methods: encode + decode.
#    Encoded data must be a singe string value
#    By default serialization uses Data::Serializer with "Storable".
has serializer => (
    is       => 'ro',
    isa      => 'Any',
    lazy     => 1,
    required => 1,
    builder  => 'get_serializer',
);


#  In child always has value = 0
#  For parent has Int value > 0
has pid => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    lazy     => 1,
    builder  => 'fork_child',
);


=head2 new()

    my $task = Async::Simple::Task::Fork->new( %all_optional_params );


Possible keys for %all_optional_params:

    task         => coderef, function, called for each "data" passed to child process via $task->put( $data );

    timeout      => timeout in seconds between child checkings for new data passed. default 0.01

    kill_on_exit => kill (1) or not (0) subprocess on object destroy (1 by default).

=cut


=head2 BUILD

internal. Some tricks here:)

    1. Master process called $task->new with fork() inside
    2. After forking done we have two processes:
    2.1. Master gets one side of reader/writer pipes and pid of child
    2.2. Child - another side of pipes and extra logic with everlasting loop

=cut

sub BUILD {
    my ( $self ) = @_;

    # Return for master process
    # Only child tasks must go down and make a loop
    return $self  if $self->pid;

    # Child loop: untill parent is alive
    while ( 1 ) {
        $self->clear_answer;
        $self->get;

        unless ( $self->has_answer ) {
            sleep $self->timeout;
            next;
        }

        my $result = eval{ $self->task->( $self->answer ) };
        $self->clear_answer;
        $self->put( $result // $@ // '' );
    }

    exit(0);
};


=head2 fork_child

Makes child process and returns pid of child process to parent or 0 to child process

=cut

sub fork_child {
    my ( $self ) = @_;

    # This is here instead of BEGIN, because this package uses as "extends" in Async::Simple::Task::ForkTmpFile
    # TODO: Maybe it would be great to move this code(function) to separate package
    # if ( $^O =~ /^(dos|os2|MSWin32|NetWare)$/ ) {
    #     die 'Your OS does not support threads... Use Async::Simple::Task::ForkTmpFile instead.';
    # };

    # Pipes: parent -> child and child -> parent
    pipe my( $parent_reader, $child_writer  )  or die 'Child  to Parent pipe open error';
    pipe my( $child_reader,  $parent_writer )  or die 'Parent to Child  pipe open error';

    my $pid = fork() // die "fork() failed: $!";

    # child
    unless ( $pid ) {
        close $parent_reader;
        close $parent_writer;

        $child_writer->autoflush(1);

        $self->writer( $child_writer );
        $self->reader( $child_reader );

        # Important!
        # Just after that we trap into BUILD
        # with the infinitive loop for child process (pid=0)
        return 0;
    }

    # parent
    close $child_writer;
    close $child_reader;

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

    my $pipe = $self->reader;
    my $data;

    # Try to read "marker" into data within timeout
    # Each pack starts with an empty line and serialized string of useful data.
    eval {
        local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
        alarm $self->timeout;
        $data = <$pipe>;
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
    $data = <$pipe>;

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

sub put {
    my ( $self, $data ) = @_;

    $self->clear_answer;

    my $pipe = $self->writer;

    # Each pack starts with an empty line and serialized string of useful data
    say $pipe '-';
    say $pipe $self->serializer->serialize( [ $data ] );

};


=head2 get_serializer

Internal. Returns an object that must have 2 methods: serialize and deserialize.
By default returns Data::Serializer with Storable as backend.

    $self->serializer->serialize( $task_data_ref );

    $result_ref = $self->serializer->deserialize();

=cut

sub get_serializer {
    my ( $self ) = @_;

    Data::Serializer->new( serializer => 'Storable' );
};


=head2 DEMOLISH

Destroys object and probably should finish the child process.

=cut

sub DEMOLISH {
    my ( $self ) = @_;

    return unless $self->pid && $self->kill_on_exit;

    kill 'KILL', $self->pid;
}

__PACKAGE__->meta->make_immutable;
