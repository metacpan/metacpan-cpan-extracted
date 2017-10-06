package Async::Simple::Task;

=head1 NAME

Async::Simple::Task - base class for asyncronous task packages

=head1 SYNOPSIS

    use Async::Simple::Task::ChildPkg;

    my $task = Async::Simple::Task::ChildPkg->new( %params );      # Creates a task, which waits for data and doing something with it

    $task->put( $data );                                           # Put a task data to task

    # ...do something useful in parent while our data working ...

    my $result = $task->get; # result = undef because result is not ready yet
    sleep $timeout; # or do something else....
    my $result = $task->get; # your result

    $task->put( $data );                                           # Put another data and so on,....

Result and data can be of any type you wish.

If your "get" can return undef as result, you should check $task->has_result, as a mark that result is ready.


=head1 DESCRIPTION

Allows to initialize async process.

After that, puts to him many similar packs of data one after other.


=head1 METHODS

=head2 C<new>

Initialize async task routine.

    my $task = Async::Simple::Task::ChildPkg->new( %optional_params );


=head2 C<put>

Puts data to task

    $self->put( $data );


=head2 C<get>

Tries to read result from task.

Returns result or undef in case when result is not ready.

In case, your function can return undef as result,
you shoud check $task->has_answer, as a mark of ready result.

    my $result = $self->get();


=head1 SUPPORT AND DOCUMENTATION

    After installing, you can find documentation for this module with the perldoc command.

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


use Modern::Perl;
use Moose;
use namespace::autoclean;

our $VERSION = '0.18';


=head1 Attributes

=head2 get

    my $result = $task->get;

Reads from task, if something can be readed or returns undef after timeout.

You should override this.

=cut


=head2 put

    $task->put( $data );

Makes task.

You should override this.

=cut


=head2 answer

Result of current task

=cut


has answer => (
    is       => 'rw',
    isa      => 'Any',
    predicate => 'has_answer',
    clearer   => 'clear_answer',
);


=head2 has_answer

has_answer is true, if the task has been finished and result is ready.

=cut


=head2 timeout

timeout - positive numeric value = seconds between checking for result

=cut

has timeout  => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
    default  => 0.01,
);


=head2 id

Index of current task task.

This fields is just for your purpose, it is not intersected with any of internal logic.

Use id as a unique marker of task, in casw when you have a list of similar tasks.

=cut

has id => (
    is       => 'rw',
    isa      => 'Str',
    predicate => 'has_id',
    clearer   => 'clear_id',
);


__PACKAGE__->meta->make_immutable;
