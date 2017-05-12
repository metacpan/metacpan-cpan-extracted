package Child;
use 5.006;
use strict;
use warnings;
use Carp;
use Child::Util;
use Child::Link::Proc;
use Child::Link::Parent;

use Exporter 'import';

our $VERSION = "0.013";
our @PROCS;
our @EXPORT_OK = qw/child/;

add_accessors qw/code/;

sub child(&;@) {
    my ( $code, @params ) = @_;
    my $caller = caller;
    return __PACKAGE__->new( $code, @params )->start;
}

sub all_procs { @PROCS }

sub _clean_proc {
    my $class = shift;
    my ($proc) = @_;
    return unless $proc;
    return unless @PROCS;
    @PROCS = grep { $_ && $proc != $_ } @PROCS;
}

sub all_proc_pids {
    my $class = shift;
    map { $_->pid } $class->all_procs;
}

sub wait_all {
    my $class = shift;
    $_->wait() for $class->all_procs;
}

sub new {
    my ( $class, $code, $plugin, @data ) = @_;

    return bless( { _code => $code }, $class )
        unless $plugin;

    my $build = __PACKAGE__;
    $build .= '::IPC::' . ucfirst $plugin;

    eval "require $build; 1"
        || croak( "Could not load plugin '$plugin': $@" );

    return $build->new( $code, @data );
}

sub shared_data {}

sub child_class  { 'Child::Link::Proc'  }
sub parent_class { 'Child::Link::Parent' }

sub start {
    my $self = shift;
    my $ppid = $$;
    my @data = $self->shared_data;

    if ( my $pid = fork() ) {
        my $proc = $self->child_class->new( $pid, @data );
        push @PROCS => $proc;
        return $proc;
    }

    # In the child
    @PROCS = ();
    my $parent = $self->parent_class->new( $ppid, @data );
    my $code = $self->code;

    # Ensure the child code can't die and jump out of our control.
    eval { $code->( $parent ); 1; } || do {
        # Simulate die without dying.
        print STDERR $@;
        exit 255;
    };
    exit;
}

1;

__END__

=head1 NAME

Child - Object oriented simple interface to fork()

=head1 DESCRIPTION

Fork is too low level, and difficult to manage. Often people forget to exit at
the end, reap their children, and check exit status. The problem is the low
level functions provided to do these things. Throw in pipes for IPC and you
just have a pile of things nobody wants to think about.

Child is an Object Oriented interface to fork. It provides a clean way to start
a child process, and manage it afterwords. It provides methods for running,
waiting, killing, checking, and even communicating with a child process.

B<NOTE>: kill() is unpredictable on windows, strawberry perl sends the kill
signal to the parent as well as the child.

=head1 SYNOPSIS

=head2 BASIC

    use Child;

    my $child = Child->new(sub {
        my ( $parent ) = @_;
        ....
        # exit() is called for you at the end.
    });
    my $proc = $child->start;

    # Kill the child if it is not done
    $proc->is_complete || $proc->kill(9);

    $proc->wait; #blocking

=head2 IPC

    # Build with IPC
    my $child2 = Child->new(sub {
        my $self = shift;
        $self->say("message1");
        $self->say("message2");
        my $reply = $self->read(1);
    }, pipe => 1 );
    my $proc2 = $child2->start;

    # Read (blocking)
    my $message1 = $proc2->read();
    my $message2 = $proc2->read();

    $proc2->say("reply");

=head2 SHORTCUT

Child can export the child() shortcut function when requested. This function
creates and starts the child process in one action.

    use Child qw/child/;

    my $proc = child {
        my $parent = shift;
        ...
    };

You can also request IPC:

    use Child qw/child/;

    my $child = child {
        my $parent = shift;
        ...
    } pipe => 1;

=head1 DETAILS

First you define a child, you do this by constructing a L<Child> object.
Defining a child does not start a new process, it is just the way to define
what the new process will look like. Once you have defined the child you can
start the process by calling $child->start(). One child object can start as
many processes as you like.

When you start a child an L<Child::Link::Proc> object is returned. This object
provides multiple useful methods for interacting with your process. Within the
process itself an L<Child::Link::Parent> is created and passed as the only
parameter to the function used to define the child. The parent object is how
the child interacts with its parent.

=head1 PROCESS MANAGEMENT METHODS

=over 4

=item @procs = Child->all_procs()

Get a list of all the processes that have been started. This list is cleared in
processes when they are started; that is a child will not list its siblings.

=item @pids = Child->all_proc_pids()

Get a list of all the pids of processes that have been started.

=item Child->wait_all()

Call wait() on all processes.

=back

=head1 EXPORTS

=over 4

=item $proc = child( sub { ... } )

=item $proc = child { ... }

=item $proc = child( sub { ... }, $plugin, @data )

=item $proc = child { ... } $plugin => @data

Create and start a process in one action.

=back

=head1 CONSTRUCTOR

=over 4

=item $child = Child->new( sub { ... } )

=item $child = Child->new( sub { ... }, $plugin, @plugin_data )

Create a new Child object. Does not start the child.

=back

=head1 OBJECT METHODS

=over

=item $proc = $child->start()

Start the child process.

=back

=head1 SEE ALSO

=over 4

=item L<Child::Link::Proc>

The proc object that is returned by $child->start()

=item L<Child::Link::Parent>

The parent object that is provided as the argument to the function used to
define the child.

=item L<Child::Link::IPC>

The base class for IPC plugin link objects. This provides the IPC methods.

=back

=head1 HISTORY

Most of this was part of L<Parallel::Runner> intended for use in the L<Fennec>
project. Fennec is being broken into multiple parts, this is one such part.

=head1 FENNEC PROJECT

This module is part of the Fennec project. See L<Fennec> for more details.
Fennec is a project to develop an extendable and powerful testing framework.
Together the tools that make up the Fennec framework provide a potent testing
environment.

The tools provided by Fennec are also useful on their own. Sometimes a tool
created for Fennec is useful outside the greater framework. Such tools are
turned into their own projects. This is one such project.

=over 2

=item L<Fennec> - The core framework

The primary Fennec project that ties them all together.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Child is free software; Standard perl licence.

Child is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
