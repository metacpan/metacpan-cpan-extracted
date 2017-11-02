package Data::Consumer;

use warnings;
use strict;
use Carp qw(confess cluck);
use vars qw/$Debug $VERSION $Fail $Cmd/;

# This code was formatted with the following perltidy options:
# -ple -ce -bbb -bbc -bbs -nolq -l=100 -noll -nola -nwls='=' -isbc -nolc -otr -kis
# If you patch it please use the same options for your patch.

=head1 NAME

Data::Consumer - Repeatedly consume a data resource in a robust way

=head1 VERSION

Version 0.17

=cut

$VERSION= '0.17';

=head1 SYNOPSIS

    use Data::Consumer;

    my $consumer = Data::Consumer->new(
        type        => $consumer_name,
        unprocessed => $unprocessed,
        working     => $working,
        processed   => $processed,
        failed      => $failed,
        max_passes  => $num_or_undef,
        max_process => $num_or_undef,
        max_elapsed => $seconds_or_undef,
    );

    $consumer->consume( sub {
        my $id = shift;
        print "processed $id\n";
    } );

=head1 DESCRIPTION

It is a common requirement to need to process a feed of items of some 
sort in a robust manner. Such a feed might be records that are inserted 
into a table, or files dropped in a delivery directory.
Writing a script that handles all the edge cases, like getting "stuck"
on a failed item, and manages things like locking so that the script 
can be parallelized can be tricky and is certainly repetitive.

The aim of L<Data::Consumer> is to provide a framework to allow writing
such consumer type scripts as easy as writing a callback that processes
each item. The framework handles the rest.

The basic idea is that one need only use, or in the case of a feed type 
not already supported, define a L<Data::Consumer> subclass
which implements a few reasonably well defined primitive methods which 
handle the required tasks, and then the L<Data::Consumer> methods use 
those to provide a DWIMily consistent interface to the end consumer.

Currently L<Data::Consumer> is distributed with two subclasses, (well
three actually, but L<Data::Consumer::MySQL> is deprecated in favour
of L<Data::Consumer::MySQL2>) L<Data::Consumer::MySQL2> for handling
records in a MySQL db (using the MySQL C<GET_LOCK()> function), and
L<Data::Consumer::Dir> for handling a drop directory scenario (like
for FTP or a mail directory).

Once a resource type has been defined as a L<Data::Consumer> subclass
the use pattern is to construct the subclass with the appropriate
arguments, and then call consume with a callback.

=head2 The Consumer Pattern

The consumer pattern is where code wants to consume an 'atomic' resource
piece by piece. The consuming code doesn't really want to worry much
about how they got the piece, a task that should be handled by the framework.
The consumer subclasses assume that the resource can be modeled as a 
queue (that there is some ordering principle by which they can be processed 
in a predictable sequence). The consume pattern in full glory is something 
very close to the following following pseudo code. The items marked with 
asterisks are where user callbacks may be invoked:

    DO
        RESET TO THE BEGINNING OF THE QUEUE
	WHILE QUEUE NOT EMPTY AND CAN *PROCEED*
	    ACQUIRE NEXT ITEM TO PROCESS FROM QUEUE
	    MARK AS 'WORKING'
	    *PROCESS* ITEM 
	    IF PROCESSING FAILED
		MARK AS 'FAILED'
	    OTHERWISE 
		MARK AS 'PROCESSED'
        SWEEP UP ABANDONDED 'WORKING' ITEMS AND MARK THEM AS 'FAILED'
    UNTIL WE CANNOT *PROCEED* OR NOTHING WAS PROCESSED
    RELEASE ANY LOCKS STILL HELD

This implies that each item potentially has four states: C<unprocessed>,
C<working>, C<processed> and C<failed>. In a database these might be
values in a field, in a drop directory scenario these would be different
directories, but with all of them they would normally be supplied as
values to the L<Data::Consumer> subclass being created. 

=head2 Subclassing Data::Consumer 

L<Data::Consumer> can be used with any resource type that can be modeled
as a queue, supports some form of advisory locking mechanism, and
provides a way to discriminate between at least the C<unprocessed> and
C<processed> state.

The routines that must be defined for a new consumer type are C<new()>,
C<reset()>, C<acquire()>, C<release()>, and C<_mark_as()>,
C<_do_callback()>.

=over 4

=item new

It is almost for sure that a subclass will need to override the default
constructor.  All L<Data::Consumer> objects are blessed hashes, and in
fact you should always call the parents classes constructor first with:

    my $self= $class->SUPER::new();

=item reset

This routine is used to reset the objects internal state so the next call to acquire
will return the first available item in the queue.

=item acquire

This routine is to find and in some way lock the next item in the queue. It should ensure
that it call is_ignored() on each item to verify the item has not been requested to be 
ignored.

=item release

This routine is to release any held locks in the object. 

=item _mark_as

This routine is called to "mark" an item as a particular state. It
should be able to handle user supplied values. For instance
L<Data::Consumer::MySQL> implements this as an update statement that
maps user supplied values to the consumer state names.

Possible states are: C<unprocessed>, C<working>, C<processed>,
C<failed>.

=item _do_callback

This routine is used to call the user supplied callback with the correct
arguments.  What arguments are appropriate for the callback are context
dependent on the type of class. For instance in L<Data::Consumer::MySQL>
calls the callback with the arguments C<($consumer, $id, $dbh)> whereas
L<Data::Consumer::Dir> calls the callback with the arguments
C<($consumer, $filespec, $filehandle, $filename)>. The point is that the
end user should be passed the arguments that make sense, not necessarily
the same thing for each consumer type.

=back

Every well-behaved L<Data::Consumer> subclass should include the 
functional equivalent of the following code in its .pm file:

    use base 'Data::Consumer';
    __PACKAGE__->register();

This will ensure that it can be properly loaded by 
C<< Data::Consumer->new(type=>$shortname) >>. 

It is also normal for a L<Data::Consumer> subclass to provide special
methods as needed. For instance C<< Data::Consumer::Dir->fh() >> and
C<< Data::Consumer::MySQL->dbh() >>.



=head1 METHODS

=head2 CLASS->new(%opts)

Constructor. Normally L<Data::Consumer>'s constructor is not called
directly, instead the constructor of a subclass is used.  However to
make it easier to have a data driven load process  L<Data::Consumer>
accepts the C<type> argument which should specify the the short name of
the subclass (the part after C<Data::Consumer::>) or the full name of
the subclass.

Thus

    Data::Consumer->new(type=>'MySQL',%args);

is exactly equivalent to calling

    Data::Consumer::MySQL->new(%args);

except that the former will automatically require or use the appropriate module 
and the latter necessitates that you do so yourself.

Every L<Data::Consumer> subclass constructor supports the following
arguments on top of any that are subclass specific. Additionally some
arguments are universally used, but have different meaning depending on
the subclass. 

=over 4

=item unprocessed

How to tell if the item is unprocessed. 

How this argument is interpreted depends on the L<Data::Consumer>
subclass involved.

=item working

How to tell if the item is currently being worked on.

How this argument is interpreted depends on the L<Data::Consumer>
subclass involved.

=item processed

How to tell if the item has already been worked on.

How this argument is interpreted depends on the L<Data::Consumer>
subclass involved.

=item failed

How to tell if processing failed while handling the item.

How this argument is interpreted depends on the L<Data::Consumer>
subclass involved.

=item max_passes => $num_or_undef

Normally C<consume()> will loop through the data set until it is
exhausted.  By setting this parameter you can control the maximum number
of iterations, for instance setting it to C<1> will result in a single
pass through the data per invocation. If C<0> (or any other false value)
is treated as meaning "loop until exhausted".

=item max_processed => $num_or_undef

Maximum number of items to process per invocation.

If set to a false value there is no limit.

=item max_failed => $num_or_undef

Maximum number of failed process attempts that may occur before consume will stop.
If set to a false value there is no limit. Setting this to 1 will cause processing
to stop after the first failure.

=item max_elapsed => $seconds_or_undef

Maximum amount of time that may have elapsed when starting a new
process. If more than this value has elapsed then no further processing
occurs. If C<0> (or any false value) then there is no time limit.

=item proceed => $code_ref

This is a callback that may be used to control the looping process in
consume via the C<proceed()> method. See the documentation of
C<consume()> and C<proceed()>

=item sweep => $bool

*** NOTE CURRENTLY THIS OPTION IS DISABLED ***

If this parameter is true, and there are four modes defined
(C<unprocessed>, C<working>, C<processed>, C<failed>) then consume will
perform a "sweep up" after every pass, which is responsible for moving
"abandonded" files from the working directory (such as from a previous
process that segfaulted during processing). Generally this should
not be necessary.

=back


=head2 CLASS->register(@alias)

Used by subclasses to register themselves as a L<Data::Consumer>
subclass and register any additional aliases that the class may be
identified as.

Will throw an exception if any of the aliases are already associated to
a different class.

When called on a subclass in list context returns a list of the
subclasses registered aliases,

If called on L<Data::Consumer> in list context returns a list of all
alias class mappings.

=cut



=head2 $class_or_object->debug_warn_hook()

Specify a callback to use to capture diagnostics data produced
by a Data::Consumer object.

If called as a class method, sets the default object for all
Data::Consumer objects that have not explicitly set a hook.

If called as an object method, sets the hook to use for that
object alone.

Returns the current effective hook. Defaults to use
the C<default_debug_warn()> method for the object. Thus
it can be overridden by a subclass if necessary.

The hook will be called with the arguments

    ($consumer,$level,@lines)

and is not expected to return anything.   

=cut

my $debug_warn_hook;
sub debug_warn_hook {
    my $self= shift;
    if (@_) {
        if (ref $self) {
            $self->{debug_warn_hook}= shift;
        } else {
            $debug_warn_hook= shift;
        }
    }
    if (ref $self and defined $self->{debug_warn_hook}) {
        return $self->{debug_warn_hook};
    }
    return $debug_warn_hook || $self->can('default_debug_warn'); 
}

=head2 $class_or_object->default_debug_warn($level,$debug);

Use warn to output diagnostics. Message includes the process id
and the class name.

=cut

sub default_debug_warn {
    my $self= shift;
    my $level= shift;
    cluck($level) if $level=~/\D/;
    my $debug_level= $self->debug_level;
    if ( $debug_level > $level ) {
        warn ref($self) || $self, "\t$$\t>>> $_\n" for @_;
    }
}

=head2 $class_or_object->debug_level($level,@debug_lines)

Set the minimum debug level. 

When called as an object method sets the value of that object
alone. undef is distinct from 0 in that undef results in
the global debug level being used for that object.

When called as a class method sets the value for all objects
which do not have a defined debug level. 

Returns the current effective debug level for the object or
class. 

=cut


sub debug_level {
    my $self= shift;
    if (@_) {
        if (ref $self) {
            $self->{debug_level}= shift;
        } else {
            $Debug= shift;
        }
    }
    if (ref $self and defined $self->{debug_level}) {
        return $self->{debug_level};
    }
    return $Debug || 0;

}

=head2 $class_or_object->debug_warn($level,@debug_lines)

If the current debugging level is  above C<$level> then call
the current debug_warn_hook() to output a set of diagnostic
messages.

=cut


sub debug_warn {
    my $self=shift;
    my $level=shift;
    my $hook=$self->debug_warn_hook;
    my $pfx= ref $self ? $self->{debug_pfx} || '' : '';
    $hook->($self,$level,map { $pfx.$_ } @_);
}

BEGIN {
    my %alias2class;
    my %class2alias;
    $Debug and $Debug >= 5 and warn "\n";

    sub register {
        my $class= shift;

        ref $class
          and confess "register() is a class method and cannot be called on an object\n";
        my $pack= __PACKAGE__;

        if ( $class eq $pack ) {
            return wantarray ? %alias2class : 0 + keys %alias2class;
        }

        ( my $std_name= $class ) =~ s/^\Q$pack\E:://;
        $std_name =~ s/::/-/g;

        my @failed;
        for my $name ( $class, $std_name, @_ ) {
            if ( $alias2class{$name} and $alias2class{$name} ne $class ) {
                push @failed, $name;
                next;
            }
            __PACKAGE__->debug_warn( 5, "registered '$name' as an alias of '$class'" );
            $alias2class{$name}= $class;
            $class2alias{$class}{$name}= $class;
        }
        @failed
          and confess "Failed to register aliases for '$class' as they are already used\n",
          join( "\n", map { "\t'$_' is already assigned to '$alias2class{$_}'" } @failed ),
          "\n";
        return wantarray ? %{ $class2alias{$class} } : 0 + keys %{ $class2alias{$class} };
    }

    sub new {
        my ( $class, %opts )= @_;
        ref $class
          and confess "new() is a class method and cannot be called on an object\n";

        if ( $class eq __PACKAGE__ ) {
            my $type= $opts{type}
              or confess "'type' is a mandatory named parameter for $class->new()\n";
            my $full = $type;
            if (!$alias2class{$full}) {
		if ($full!~/::/) {
		    $full=~s/-/::/g;
		    $full=join '::',$class,$full;
		}
		eval "require $full; 1"
		    or confess "'type' parameter '$type' could not be loaded properly: $@\n";
            }
            $class= $alias2class{$full}
                or confess "'type' parameter '$type' mapped to '$full' which does not seem to exist\n";
        }
        my $object= bless {}, $class;
        $class->debug_warn( 5, "created new object '$object'" );
        return $object;
    }
}

=head2 $object->last_id()

Returns the identifier for the last item acquired.

Returns undef if acquire has never been called or if the last
attempt to acquire data failed because none was available.

=cut

sub last_id {
    my $self= shift;
    return $self->{last_id};
}

# Until i figure out to make gedit handle begin/end directives this has to
# stay commented out
#=begin dev
#
#=head2 $object->_mark_as($type,$id)
#
#** Must be overriden **
#
#Mark an item as a particular type if the object defines that type.
#
#This is wrapped by mark_as() for error checking, so you are guaranteed
#that $type will be one of
#
#    'unprocessed', 'working', 'processed', 'failed'
#
#and that $object->{$type} will be true value, and that $id will be from
#the currently acquired item.
#
#=end dev

=head2 $object->mark_as($type)

Mark an item as a particular type if the object defines that type.

Allowed types are C<unprocessed>, C<working>, C<processed>, C<failed>

=cut

sub _mark_as { confess "must be overriden" }

BEGIN {
    my ( %valid, @valid );
    @valid= qw ( unprocessed working processed failed );
    @valid{@valid}= ( 1 .. @valid );

    sub mark_as {
        my $self= shift @_;
        my $key= shift @_;

        $valid{$key}
          or confess "Unknown type in mark_as(), valid options are ",
          join( ", ", map { "'$_'" } @valid ),
          "\n";

        my $id= @_ ? shift @_ : $self->last_id;
        defined $id
          or confess "Nothing acquired to be marked as '$key' in mark_as.\n";

        return unless defined $self->{$key};
        return $self->_mark_as( $key, $id );
    }
}

=head2 $object->process($callback)

Marks the current item as C<working> and processes it using the
C<$callback>. If the C<$callback> dies then the item is marked as
C<failed>, otherwise the item is marked as C<processed> once the
C<$callback> returns. The return value of the C<$callback> is ignored.

C<$callback> will be called with at least two arguments, the first being
the $consumer object itself, and the second being an identifier for the
current record. Normally additional, likely to be useful, arguments are 
provided as well, on a per subclass basis. For example 
L<Data::Consumer::MySQL> will pass in the consumer object, the id of the to 
be processed record, and a copy of the consumers database handle as well for 
convenience. On the other hand L<Data::Consumer::Dir> will pass in the 
consumer object, followed by a filespecification for the file to be 
processed, an open filehandle to the file, and the filename itself (with 
no path).

The callback may call the methods 'leave', 'ignore', 'fail', and 'halt' on 
the consumer object before returning, typically by doing something like

    return $consumer->ignore;

this allows the callback to send specific signals to consume, specifically

    leave  : return the item to the unprocessed state after the callback returns.
    ignore : return the item to the unprocessed state after the callback returns
             and never attempt to process it again with this consumer object.
    fail   : same result as dieing in a callback, except without throwing an exception
             in the situation where there might be $SIG{__DIE__} hooks to worry about.
    halt   : stop the consume() process after this has been executed

For further details always consult the relevant subclasses documentation for
C<process()>

=cut

sub process {
    my $self= shift;
    my $callback= shift;
    delete $self->{fail};
    my $id= $self->last_id;
    defined $id
      or $self->error("Undefined last_id. Nothing acquired yet?");
    $self->mark_as('working');
    local $Cmd;
    delete $self->{defer_leave};
    my $error= $self->_do_callback($callback);
    $error ||= $self->{fail};
    if ( $error ) {
        $self->mark_as('failed');
        $self->error($error);
    } else {
        if ($self->{defer_leave}) {
            $self->mark_as('unprocessed');
        } else {
            $self->mark_as('processed');
        }
    }
    return 1;
}


=head2 $consumer->leave()

Sometimes its useful to defer processing. This method when called
from within a consume/process callback will result in the 
item being marked as 'unprocessed' after the callback returns
(so long as it does not die).

Typically this is invoked as

    return $consumer->leave;

from withing a consume/process callback.

Returns $consumer. Will die if not 'unprocessed' state is defined. 

=cut

sub leave {
    my $self= shift;
    confess("Can't leave as 'unprocessed' is undefined!") if not defined $self->{unprocessed};
    $self->{defer_leave}++;
    return $self;
}

=head2 $consumer->ignore(@list)

This can used to cause acquire to ignore each item in @list. 

If @list is empty then it is assumed it is being called from
within consume/process and marks the currently acquired item
as ignored and calls C<< $consumer->leave() >>.

Returns $consumer. Will die if no 'unprocessed' state is defined.

=cut


sub ignore {
    my $self= shift;
    if (@_) {
        for my $id (@_) {
            $self->{ignore}{$id}++;
        }
    } else {
        my $id= $self->last_id;
        $self->{ignore}{$id}++;
        $self->leave;
    }
    return $self;
}

=head2 $consumer->fail($message)

Same as doing C<die($message)> from within a consume/process callback except
that no exception is thrown (no C<$SIG{__DIE__}> callbacks are invoked) and
the error is deferred until the callback actually returns.

Typically used as

    return $consumer->fail;

from within a consumer() callback.

Returns the $consumer object.

=cut

sub fail {
    my $self= shift;
    $self->{fail}= shift;
    return $self;
}

=head2 $consumer->halt()

Causes consume() to halt processing and exit once
the callback returns. Typically invoked like

    return $consumer->halt;

or

    return $consumer->fail->halt;

Returns the consumer object.

=cut


sub halt {
    my $self= shift;
    $self->{halt}++;
    return $self;
}



=head2 $object->is_ignored($id)

Returns true if an item has been set to be ignored. If $id is omitted
defaults to last_id

=cut

sub is_ignored { 
    my $self= shift;
    my $id= @_ ? shift @_ : $self->last_id;
    return if !defined $id;
    return $self->{ignore}{$id} ? 1 : 0
}

=head2  $object->reset()

Reset the state of the object.

=head2 $object->acquire()

Acquire an item to be processed.

Returns an identifier to be used to identify the item acquired.

=head2 $object->release()

Release any locks on the currently held item.

Normally there is no need to call this directly.

=cut

sub reset   { confess "abstract method must be overriden by subclass\n"; }
sub acquire { confess "abstract method must be overriden by subclass\n"; }
sub release { confess "abstract method must be overriden by subclass\n"; }

=head2 $object->error()

Calls the C<error> callback if the user has provided one, otherwise
calls C<confess()>. Probably not all that useful for an end user.

=cut

sub error {
    my $self= shift;
    if ( $self->{error} ) {
        $self->{error}->(@_);
    } else {
        confess @_;
    }
}

=head2 $object->consume($callback)

Consumes a data resource until it is exhausted using C<acquire()>,
C<process()>, and C<release()> as appropriate. Normally this is the main
method used by external processes.

Before each attempt to acquire a new resource, and once at the end of
each pass consume will call C<proceed()> to determine if it can do so.
The user may hook into this by specifying a callback in the constructor.
This callback will be executed with no args when it is in the inner loop
(per item), and with the number of passes at the end of each pass
(starting with 1).

=head2 $object->proceed($passes)

Returns C<true> if the conditions specified at construction time are
satisfied and processing may proceed. Returns C<false> otherwise.

If the user has specified a C<proceed> callback in the constructor then
this will be executed before any other rules are applied, with a
reference to the current C<$object>, a reference to the runstats, and if
being called at the end of pass with the number of passes.

If this callback returns C<true> then the other rules will be applied,
and only if all other conditions from the constructor are satisfied
will C<proceed()> itself return C<true>.

=head2 $object->runstats()

Returns a reference to a hash of statistics about the last (or currently running)
execution of consume. Example:

	{
          'passes' 		=> 2,
          'processed_this_pass' => 0,
          'processed' 		=> 3,
          'start_time' 		=> 1209750962,
          'failed' 		=> 0,
          'elapsed' 		=> 0,
          'end_time' 		=> 1209750962,
          'failed_this_pass' 	=> 0
        }

Note that start_time and end_time are unix timestamps.

=cut

sub runstats { $_[0]->{runstats} }

sub proceed {
    my $self= shift;
    my $runstats= $self->{runstats};
    $runstats->{end_time}= time;
    $runstats->{elapsed}= $runstats->{end_time} - $runstats->{start_time};

    if ( my $cb= $self->{proceed} ) {
        $cb->( $self, $self->{runstats}, @_ )    # pass on the $passes argument if its there
          or return;
    }
    for my $key (qw(elapsed passes processed failed)) {
        my $max= "max_$key";
        return if $self->{$max} && $runstats->{$key} >= $self->{$max};
    }
    return if $self->{halt};
    return 1;
}

sub consume {
    my $self= shift;
    my $callback= shift;

    my $passes= 0;

    unless ($self->{runstats}) {
        $self->{runstats}= {};
        $self->{runstats}{$_}= 0 
            for qw(passes processed failed processed_this_pass failed_this_pass);
    }

    my $runstats= $self->{runstats};
    $runstats->{start_time}= time;

    $self->reset();
    do {
        ++$runstats->{passes};
        $runstats->{processed_this_pass}= $runstats->{failed_this_pass}= 0;
        while ( $self->proceed && defined( my $item= $self->acquire ) ) {
            eval {
                $self->process($callback);
                $runstats->{processed_this_pass}++;
                $runstats->{processed}++;
                1;
              }
              or do {
                $runstats->{failed_this_pass}++;
                $runstats->{failed}++;

                # quotes force string copy
                $self->debug_warn(5, "Failed during \$self->process(\$callback): $@");
              }
        }
      } while $self->proceed( $runstats->{passes} )
          && $runstats->{processed_this_pass};

    # if we still hold a lock let it go.
    delete $self->{halt};
    $self->release;
    return $runstats;
}


=head1 AUTHOR

Yves Orton, C<< <YVES at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-consumer at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Consumer>.

I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Consumer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Consumer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Consumer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Consumer>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Consumer>

=back


=head1 ACKNOWLEDGEMENTS

Igor Sutton <IZUT@cpan.org> for ideas, testing and support

=head1 COPYRIGHT & LICENSE

Copyright 2008, 2010, 2011 Yves Orton, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Data::Consumer

