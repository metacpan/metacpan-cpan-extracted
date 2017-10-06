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
use File::Spec;

our $VERSION = '0.18';

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

=head2 tmp_dir

    Path, that used for store tomporary files.
    This path must be writable.
    It can be empty; in this case ( File::Spec->tmpdir() || $ENV{TEMP} ) will be used

    By default:
    During taint -T mode always writes files to current directory ( path = '' )
    Windows outside taint -T mode writes files by default to C:\TEMP or C:\TMP
    Unix    outside taint -T mode writes files by default to /var/tmp/

=cut

has tmp_dir => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => 'make_tmp_dir',
);

sub make_tmp_dir {
    my ( $self ) = @_;

    my $tmp_dir = File::Spec->tmpdir() || '';

    # For WIN taint mode calculated path starts with '\'. Remove it and stay at current(empty) dir
    $tmp_dir = '' if $tmp_dir =~ /^\\$/;

    # TEMP = C:\Users\XXXXXX~1\AppData\Local\Temp
    $tmp_dir ||= $ENV{TEMP} // '';

    # Untaint ENV: fallback, if File::Spec->tmpdir failed
    return [ $tmp_dir =~ /^(.+)$/ ]->[0];
};


=head2 BUILD

internal. Some tricks here:)

    1. Master process called $task->new with fork() inside
    2. After forking done we have two processes:
    2.1. Master gets one side of reader/writer tmp file handlers and pid of child
    2.2. Child - another side of tmp file handlers and extra logic with everlasting loop

=cut

#  Writable pipe between parent and child.
#  Each of them has pair of handlers, for duplex communication.
has writer => (
    is       => 'rw',
    isa      => 'Str',
);


#   Readable pipe between parent and child.
#   Each of them has pair of handlers, for duplex communication.
has reader => (
    is       => 'rw',
    isa      => 'Str',
);


=head2 fork_child

Makes child process and returns pid of child process to parent or 0 to child process

=cut

sub fork_child {
    my ( $self ) = @_;

    my( $randname, $parent_writer_fname, $parent_reader_fname );
    $randname = sub {
        my @x = ( 'a'..'z', 'A'..'Z', 0..9 );
        join( "", map { $x[ int( rand @x - 0.01 ) ] } 1 .. 64 )
    };

    for ( 1..10 ) {
    	$parent_writer_fname = File::Spec->catfile( $self->tmp_dir, '_pw_tmp_' . $randname->() );
    	$parent_reader_fname = File::Spec->catfile( $self->tmp_dir, '_pr_tmp_' . $randname->() );

  	next if -f $parent_writer_fname || -f $parent_reader_fname;
	last;
    };

    die 'Can`t obtain unique fname'  if -f $parent_writer_fname || -f $parent_reader_fname;

    my $pid = fork() // die "fork() failed: $!";

    # With taint mode we use current directory as temp,
    # Otherwise - default writable temp directory from File::Spec->tmpdir();

    # child
    unless ( $pid ) {
        $self->writer( $parent_reader_fname );
        $self->reader( $parent_writer_fname );

        # Important!
        # Just after that we trap into BUILD
        # with the infinitive loop for child process (pid=0)
        return 0;
    }

    # parent
    $self->writer( $parent_writer_fname );
    $self->reader( $parent_reader_fname );

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

    # Try to read "marker" into data within timeout
    # Each pack starts with an empty line and serialized string of useful data.
    open( my $fh, '<', $self->reader ) or return;

    my $data = <$fh>;

    return unless defined $data;
    return unless $data =~ /\n/;

    close( $fh );

    # In case, when reader still opened for writing
    # We are not allowed to remove file, so we should wait
    for ( 1..10 ) {
        last  if unlink $self->reader;
	sleep $self->timeout;
    }

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

    unlink $self->writer;
    $self->clear_answer;

    my $save_flush = $|;
    $| = 1;

    open( my $fh, '>', $self->writer );

    # Each pack starts with an empty line and serialized string of useful data
    say $fh $self->serializer->serialize( [ $data ] );

    close $fh;

    $| = $save_flush;

};


=head2 get_serializer

Internal. Returns an object that must have 2 methods: serialize and deserialize.
By default returns Data::Serializer with Storable as backend.

    $self->serializer->serialize( $task_data_ref );

    $result_ref = $self->serializer->deserialize();

=cut


=head2 DEMOLISH

Destroys object and probably should finish the child process.

=cut

sub DEMOLISH {
    my ( $self ) = @_;

    unlink $self->writer;
    unlink $self->reader;
}



__PACKAGE__->meta->make_immutable;
