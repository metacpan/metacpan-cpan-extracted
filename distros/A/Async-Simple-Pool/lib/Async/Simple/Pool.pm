package Async::Simple::Pool;

=head1 NAME

Async::Simple::Pool - Simple manager of asyncronous tasks

=head1 SYNOPSIS

Simplest way:

    use Async::Simple::Pool;
    use Data::Dumper;

    my $task = sub{
        my $data = shift;

        return $data->{i} * 10;
    };

    my $data = [ { i => 1 }, { i => 2 }, { i => 3 } ];

    my $pool = Async::Simple::Pool->new( $task, $data );

    my $result = $pool->process;

    say Dumper $result;

    $VAR1 = [
              10,
              20,
              30
            ];


Some other ways to do $pool->new(), using various param sets.

Note: If you pass $data to $pool->new() then all processes will be started immediately.
You can call $pool->process after "new" and get your results in no time.

    my $pool = Async::Simple::Pool->new( $task, $data );               # Simplest way to create a new pool. Results will be available just after "new"

    my $pool = Async::Simple::Pool->new( %pool_params );               # Creates a new pool. The only one param "task" is required by default.

    my $pool = Async::Simple::Pool->new( $task, %pool_params );        # "$task" is required, al params are optional

    my $pool = Async::Simple::Pool->new( $data, %pool_params );        # $data - required, all pool_params except "task" are optional

    my $pool = Async::Simple::Pool->new( $task, $data, %pool_params ); # $task, $data - required, all pool_params are optional


By default "task" is required and must be a CodeRef.
For example:

    $task = sub { my $task_X_data = shift; some useful code; return $task_X_result };


$data can be ArrayRef of your tasks params.

    $data = [ $task_data1, $task_data2, ... ];


Also $data can be HashRef of your tasks params.
In this case you can pass any scalars as keys of this hash. They will be mirrored into result

    $data = { task_id1 => $task_data1, task_id2 => $task_data2, ... };


The "pool->new()" creates "$pool->tasks_count" count of "$pool->task_class objects".
By default task_class is "Async::Simple::Task::Fork".
In this case "$pool->tasks_count" processes will be preforked (10 by default).
Each of them starts to wait for data which will be provided by pool later.


This is the main dispatcher of pool. It behavior depends on %pool_params.
If you pass $data to $pool->process, this data will be added to execution.

    $results = $pool->process( $data );


Type of $result depends on pool params that you pass in $pool->new( %pool_params );
By default result is arrayref.


You can use these %pool_params:

        data          - ArrayRef/HashRef. A data for tasks, as described above,

        tasks_count   - Integer number of workers. 10 by default.

        flush_data    - 1 - remove or 0 - don't remove results from pool, when they has been readed by $pool->process()

        result_type   - list (list of ready results) / full_list (list of all results) / hash (hash of ready results)

        break_on      - busy (when all workers are busy) / run(all data is executing) / done (all result are ready)

        task_class    - see explanation below. For example 'Your::Task::Class';

        task_params   - Any params you wish to pass to each task object to $task->new( %$here ).


The last way to use pool is to make your own task class.
You can make your own class of task. This class MUST has at least this code:

    package Your::Task::Class;

    use parent 'Async::Simple::Task';

    # Trying to read result.
    # If result found, call $self->result( $result );
    # If result is not ready, do nothing
    sub get {
        my $self = shift;

        return unless you have result;

        # result can be undef; Don't worry, all will be ok!
        $self->result( $result );
    };

    # Just push data to execution in your way
    sub put {
        my ( $self, $data ) = @_;

        $self->clear_answer; # Optional, if you plan to use your package regardlessly from this pool.

        # Pass your data to your processor here
    }

    1;


=head1 DESCRIPTION

Allows to work with pool of async processes.

There are many other similar packages you can find on CPAN: Async::Queue, Anyevent::FIFO, Task::Queue, Proc::Simple.

The main difference of this package is convenience and simplicity of usage.


=head1 METHODS

    $pool->new( various params as described above )

    $pool->process( $optional_data_ref )


=head1 SUPPORT AND DOCUMENTATION

    After installing, you can find documentation for this module with the
    perldoc command.

    perldoc Async::Simple::Task

    You can also look for information at:

        RT, CPAN's request tracker (report bugs here)
            http://rt.cpan.org/NoAuth/Bugs.html?Dist=Async-Simple-Task

        AnnoCPAN, Annotated CPAN documentation
            http://annocpan.org/dist/Async-Simple-Task

        CPAN Ratings
            http://cpanratings.perl.org/d/Async-Simple-Task

        Search CPAN
            http://search.cpan.org/dist/Async-Simple-Task/


=head1 AUTHOR

    ANTONC <antonc@cpan.org>

=head1 LICENSE

    This program is free software; you can redistribute it and/or modify it
    under the terms of the the Artistic License (2.0). You may obtain a
    copy of the full license at:

    L<http://www.perlfoundation.org/artistic_license_2_0>

=cut


# Async::Queue, Anyevent::FIFO - very similar to this, but have no enough sugar, has Anyevent dependence, has no prefork and fixed pool
# Task::Pool - wery similar, uses tasks, results represented as a spream
# Task::Queue - low level code
# Proc::Simple - wery similar byt not flexible enough


use Modern::Perl;
use Moose;
use namespace::autoclean;
use Class::Load;
use Clone;
use JSON::XS;

our $VERSION = '0.18';

=head2 data

You can pass hashref or arrayref as data

When it is array, then each item of it will be passed to task as task params
ids for internal format will be generated automatically by increasing from 0

When is is hashref, then each value of hash will be passed to task as task params
ids for internal format will be the same as in your hash

In both cases it converts to internal format:

    { id => { source => paramref1, result => if_processed1 }, { source => paramref2, result => if_processed2 },  ... };

=cut

has data => (
    is       => 'rw',
    isa      => 'HashRef[HashRef]',
    default  => sub { return {} },
);


=head2 tasks_count

tasks_count - an integer number of tasks that will be created (defailt is 10).

=cut

has tasks_count => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => 10,
);


=head2 flush_data

flush_data - (1|0) - remove used data and results after is has been readed in $self->process;

=cut

has flush_data => (
    is       => 'rw',
    isa      => 'Str',
    default  => 0,
);


=head2 result_type

defines structure of results. results_type = (hash|list|fulllist)

    when 'list'     - returns all results as list without placing them to the order of source data

    when 'fulllist' - returns all results as list with the full accordance to the source data order and positions

    when 'hash'     - resurns hash, where index is the position of corresponding source data item and value - result

=cut

has result_type => (
    is       => 'rw',
    isa      => 'Str',
    default  => 'fulllist',
);


=head2 break_on

Condition of stopping waiting for results and do something other before next check.

    'busy' = $self->process will exit after filling all the tasks with tasks, without any checks

    'run'  = $self->process will end straight after the last task started

    'done' = $self->process will wait until all the tasks have finished their work

    Default is 'done'

=cut

has break_on => (
    is       => 'rw',
    isa      => 'Str',
    default  => 'done',
);


=head2 task_class

Task object class name. Default is 'Async::Simple::Fork'.

=cut

has task_class => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => (
        $^O =~ /^(dos|os2|MSWin32|NetWare)$/
            ? 'Async::Simple::Task::ForkTmpFile'
            : 'Async::Simple::Task::Fork'
    ),
);


=head2 task_params

Task init params.

Pool will push all these params to task->new( here ).

You can pass all these params directly into pool constructor.
In this case task_params will be separated by magic;)

=cut

has task_params => (
    is       => 'rw',
    isa      => 'HashRef',
);


=head2 logger

Something that can write your logs
It can be one of types: CodeRef, FileHandle, Str, Int

In case of CodeRef, we will call it with one param = 'text to log'
In case of FileHandle, we will try to write in it
In case of Str, we try to interprete it as file_name and write into it
Also you can pass 'stdout' or 'stderr' as string

By default logger is undefined, so nobody writes nothing to nowhere

=cut

has logger => (
    is       => 'rw',
    isa      => 'CodeRef | FileHandle | Str',
);



# Tasks - ArrayRef of task objects
has tasks => (
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    required => 1,
    builder  => 'make_tasks',
);


# List of all internal keys of data
# desceases when a new process is added
has queue_keys => (
    is       => 'rw',
    isa      => 'ArrayRef',
    default  => sub { return [] },
);


# List of all internal keys of data
# desceases when we ask for result vith flush_data is setted
has all_keys => (
    is       => 'rw',
    isa      => 'ArrayRef',
    default  => sub { return [] },
);


=head2 new( some various params )

some ways to call it:

    my $pool    = Async::Simple::Pool->new( $task );                   # Process should be started below.

    my $pool    = Async::Simple::Pool->new( $task, \@data );           # Process will be started inside new.

    my $pool    = Async::Simple::Pool->new( \@data, task => $task );   # Process will be started inside new.

    my $results = Async::Simple::Pool->new( $task, \@data )->results;  # Just do everything and give me my results!

    my $pool = Async::Simple::Pool->new( task => $task );              # Minimal init with hash of params, all by default, process sould be started manually below


full list of params for default task type (Async::Simple::Fork) with default values.

    my $pp = Async::Simple::Pool->new(
        tasks_count   => 10,
        break_on      => 'done', # [ 'busy', 'run', 'done' ]
        data          => \@data,
        task_class  => 'Async::Simple::Fork',
        task_params => { # Can be placed into pool params directly
            task          => $task,
            timeout       => 0.01,
        },
    );

It is a good idea to run new() before gathering all this huge amount of data, and run $pool->process separately:

    my $pool = Async::Simple::Pool->new( $task );

    <collecting all your data after forking>

    my $results = $pool->process( \@your_data );

=cut


# params parsing, some sugar
around BUILDARGS => sub {
    my ( $orig, $class, @params ) = @_;

    my ( $task, $data );
    $task = shift @params  if ref $params[0] eq 'CODE';
    $data = shift @params  if ref $params[0];

    my %params = @params;

    # Hack for earlier logginf
    bless( Clone::clone( \%params ), $class )->log( 'INIT: Received params', \%params );

    my ( @new_keys, $keys );

    if ( $data ) {
        ( $data, $keys ) = _conv_data_to_internal( {}, $data );
        push @new_keys, @$keys;
    };

    if ( $params{data} ) {
        ( $data, $keys ) = _conv_data_to_internal( $data, $params{data} );
        push @new_keys, @$keys;
    };

    $params{task_params}{task} //= $task;
    $params{data} = $data  if $data;
    $params{queue_keys} = \@new_keys;
    $params{all_keys}   = Clone::clone \@new_keys;

    my @task_param_names = grep !$class->can($_), keys %params;

    for ( @task_param_names ) {
        $params{task_params}{$_} //= delete $params{$_};
    };

    my $i = 0;

    # Hack for earlier logginf
    bless( Clone::clone( \%params ), $class )->log( 'INIT: Parsed params', \%params );

    return $class->$orig( %params );
};


=head2 BUILD

Internal. Overrided init for magic with params.

=cut

sub BUILD {
    my ( $self ) = @_;

    my $task_class = $self->task_class;

    $self->log( 'BUILD: task class', $task_class );

    Class::Load::load_class( $task_class );

    my @bad_task_param_names = grep !$task_class->can($_), keys %{ $self->task_params // {} };

    if ( scalar @bad_task_param_names ) {
        $self->log( 'BUILD: bad_task_param_names', \@bad_task_param_names );
        die 'Unknown params found: (' . join( ', ', @bad_task_param_names ) . ' )';
    };

    if ( scalar keys %{ $self->data } ) {
        $self->log( 'BUILD', '$self->process called' );
        $self->process;
    }
};


=head2 process

Main dispatcher of child tasks

    - writes data to tasks

    - checks for results


We don't care about all internal fails, dying or hang ons of your tasks.

If your task can do something bad, please write workaround for this case inside your "sub".

Will be called inside new() in case you pass data there.

=cut

sub process {
    my ( $self, $new_data ) = @_;

    if ( $new_data ) {
        $self->log( 'PROCESS: new data received', $new_data )  if $self->logger;

        my ( $data, $keys ) = _conv_data_to_internal( $self->data, $new_data );

        $self->log( 'PROCESS: new data parsed', $data )  if $self->logger;

        $self->data( $data );
        push @{ $self->queue_keys }, @$keys;
        push @{ $self->all_keys   }, @$keys;
    };

    my $break_on_busy = $self->break_on eq 'busy';
    my $break_on_run  = $self->break_on eq 'run';

    while( 1 ) {
        $self->log( 'PROCESS', 'internal cycle unless exit condition' )  if $self->logger;

        $self->read_tasks()  if grep $_->has_id, @{ $self->tasks };
        $self->write_tasks();

        if ( $break_on_busy ) {
            $self->log( 'PROCESS', 'internal cycle exit: all threads are busy' )  if $self->logger;
            last;
        }

        # Has not started data
        next if scalar @{ $self->queue_keys };

        if ( $break_on_run ) {
            $self->log( 'PROCESS', 'internal cycle exit: all tasks are started' )  if $self->logger;
            last;
        }

        # Has unprocessed data
        next if grep $_->has_id, @{ $self->tasks };

        $self->log( 'PROCESS', 'internal cycle exit: all tasks done' )  if $self->logger;
        last;
    };

    $self->log( 'PROCESS: finished', $self->results )  if $self->logger;

    return $self->results;
};


=head2 results

Internal.
Returns all results that already gathered
by default returns hash, where keys equal to indexes of source data list
and values are the results for data at these indexes.

=cut

sub results {
    my ( $self ) = @_;

    my $data = $self->data;

    my $is_list = $self->result_type =~ /list/;
    my $is_full = $self->result_type =~ /full/;

    my $results = $is_list ? [] : {};

    for ( @{ $self->all_keys } ) {
        my $result     = $data->{$_}->{result};
        my $has_result = exists $data->{$_}->{result};

        next  if !$is_full && !$has_result;

        $is_list
            ? ( push @$results, $result  )
            : ( $results->{$_} = $result );

        if ( $self->flush_data && $has_result ) {
            delete $data->{$_};
        };
    };

    $self->all_keys( [ keys %$data ] )  if $self->flush_data;

    return $results;
}


=head2 make_tasks

Internal.
All tasks are created here.
Called from constructor.

=cut

sub make_tasks {
    my ( $self ) = @_;

    my @tasks;
    my $task_class = $self->task_class;

    for( 1 .. $self->tasks_count ) {
        my $task = $task_class->new( %{ $self->task_params } );
        push @tasks, $task;

        $self->log( 'NEW THREAD ADDED', { ref $task => {%$task} } )  if $self->logger;
    };

    return \@tasks;
};


=head2 read_tasks

Internal.
Reads busy tasks.

=cut

sub read_tasks {
    my ( $self ) = @_;

    my @busy_tasks = grep $_->has_id, @{ $self->tasks }  or return;

    $self->log( 'READ TASKS', { busy_tasks_found => scalar @busy_tasks } )  if $self->logger;

    my $data = $self->data;

    for my $task ( @busy_tasks ) {
        $task->clear_answer;
        $task->get();

        unless ( $task->has_answer ) {
            $self->log( 'READ TASKS NO ANSWER', { id => $task->id } )  if $self->logger;
            next;
        };

        $self->log( 'READ TASKS GOT ANSWER', { id => $task->id, answer => $task->answer } )  if $self->logger;

        $data->{ $task->id }->{result} = $task->answer;
        $task->clear_id;
    };
};


=head2 write_tasks

Internal.
Writes to free tasks.

=cut

sub write_tasks {
    my ( $self ) = @_;

    my @free_tasks = grep !$_->has_id, @{ $self->tasks }  or return;

    $self->log( 'WRITE TASKS', { free_tasks_found => scalar @free_tasks } )  if $self->logger;

    my $data = $self->data;

    for my $task ( @free_tasks ) {

        my $pointer = shift @{ $self->queue_keys };

        return unless defined $pointer;

        $self->log( 'WRITE TASKS: TASK ADDED', { id => $pointer, data => $data->{ $pointer }->{source} } )  if $self->logger;

        $task->id( $pointer );

        # just in case, if somebody did not care for this in "task" package
        $task->clear_answer;

        $task->put( $data->{ $pointer }->{source} );
    };
};


=head2 _conv_data_to_internal

Internal.
Converts source data ( hashref or arrayref ) to internal representation ( hashref ).

=cut

sub _conv_data_to_internal {
    my ( $int_data, $data ) = @_;

    my @new_keys;
    my %new_data;

    # $pool->new( coderef, [ @data ], %params );
    if ( ref $data eq 'ARRAY' ) {

        # Gets max integer index in existing source data indexes,
        my $i = ( [ sort { $a <=> $b } grep /^\d+$/, keys %$int_data ]->[-1] || -1 ) + 1;

        push @new_keys, $_ for $i..$i+@$data-1;
        %new_data = map { $_, { source => $data->[$_-$i] } } @new_keys;

    }
    # $pool->new( coderef, { %data }, %params );
    elsif ( ref $data eq 'HASH' ) {
        @new_keys = keys %$data;
        %new_data = map { $_, { source => $data->{$_} } } @new_keys;
    };

    return { %$int_data, %new_data }, \@new_keys;
};


=head2 fmt_log_text

Internal.
Adding extra data to logging text
yyyy-mm-dd hh:mm:ss	(Program)[pid]: $text

=cut

sub fmt_log_text {
    my ( $self, $action, $text ) = @_;

    unless ( defined $text ) {
        $text   = $action;
        $action = 'DEFAULT';
    };

    my ( $ss, $mi, $hh, $dd, $mm, $yyyy ) = localtime();
    $yyyy += 1900;
    my $date_time = sprintf '%04d-%02d-%02d %02d:%02d:%02d', $yyyy, $mm, $dd, $hh, $mi, $ss;

    if ( ref $text ) {
        $text = JSON::XS->new->allow_unknown->allow_blessed->encode( $text );
    }

    return sprintf "%s\t%s\t%s\t%s\t%s", $date_time, $$, $0, $action, $text;
}


=head2 log

Internal.
Writes pool log

=cut

sub log {
    my ( $self, $action, $text ) = @_;

    # No logger - no problems
    my $logger = $self->logger or return;

    my $log_text = $self->fmt_log_text( $action, $text );

    if ( ref $logger eq 'CODE' ) {
        $logger->( $log_text );
    }
    elsif ( ref $logger eq 'GLOB' ) {
        die "logger file $logger not found" unless -f $logger;
        die "logger file $logger not found" unless -w $logger;
        say $logger $log_text;
    }
    elsif ( $logger =~ /^stdout$/ai ) {
        say STDOUT $log_text;
    }
    elsif ( $logger =~ /^stderr$/ai ) {
        say STDERR $log_text;
    }
    else {
        open ( my $f, '>>', $logger ) or die 'can`t open log file ' . $logger;
        $self->logger( $f );
        $self->log( $text );
    }
};

__PACKAGE__->meta->make_immutable;
