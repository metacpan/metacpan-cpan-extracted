package AnyEvent::Tools;

use 5.010001;
use strict;
use warnings;
use Carp;

require Exporter;
use AnyEvent::Util;
use AnyEvent::AggressiveIdle 0.04, qw(aggressive_idle stop_aggressive_idle);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
    all => [
            qw(
                    mutex rw_mutex
                    async_for async_repeat
                    async_rfor async_foreach
                    pool buffer
            )
    ],
    mutex   => [ qw( mutex rw_mutex ) ],
    foreach => [ qw( async_for async_rfor async_repeat )   ],
    pool    => [ qw( pool buffer ) ],


);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.12';

sub pool(@)
{
    require AnyEvent::Tools::Pool;

    no strict 'refs';
    no warnings 'redefine';
    *{ __PACKAGE__ . "::pool" } = sub (@) {
        return AnyEvent::Tools::Pool->new(@_);
    };

    goto &pool;
}


sub buffer(@)
{
    require AnyEvent::Tools::Buffer;
    no warnings 'redefine';
    no strict 'refs';
    *{ __PACKAGE__ . "::buffer" } = sub (@) {
        return new AnyEvent::Tools::Buffer(@_);
    };

    goto &buffer;
}

sub mutex()
{
    require AnyEvent::Tools::Mutex;

    no strict 'refs';
    no warnings 'redefine';
    *{ __PACKAGE__ . "::mutex" } = sub () {
        return AnyEvent::Tools::Mutex->new;
    };

    goto &mutex;
}

sub rw_mutex()
{
    require AnyEvent::Tools::RWMutex;

    no strict 'refs';
    no warnings 'redefine';
    *{ __PACKAGE__ . "::rw_mutex" } = sub () {
        return AnyEvent::Tools::RWMutex->new;
    };

    goto &rw_mutex;
}

sub _async_repeati($$&;&);
sub async_repeat($&;&) {
    my ($count, $cb, $cbe) = @_;

    if (!$count) {
        $cbe->() if $cbe;
        return;
    }
    return &_async_repeati(0, $count, $cb, $cbe);
}

sub async_for($&;&) {
    my ($obj, $cb, $cbe) = @_;
    if ('ARRAY' eq ref $obj or "$obj" =~ /=ARRAY\(/) {
        unless (@$obj) {
            $cbe->() if $cbe;
            return;
        }
        return &async_repeat(
            scalar(@$obj),
            sub {
                my ($g, $index, $first, $last) = @_;
                $cb->($g, $obj->[$index], $index, $first, $last);
            },
            $cbe
        );
    }

    if ('HASH' eq ref $obj or "$obj" =~ /=HASH\(/) {
        unless (%$obj) {
            $cbe->() if $cbe;
            return;
        }

        my @keys = keys %$obj;
        return &async_repeat(
            scalar(@keys),
            sub {
                my ($g, $index, $first, $last) = @_;
                $cb->($g, $keys[$index], $obj->{$keys[$index]}, $first, $last);
            },
            $cbe
        );
    }

    croak "Usage: async_for ARRAYREF|HASHREF, callback [, end_callback ]";
}


sub async_foreach($&;&) { goto &async_for; }


sub async_rfor($&;&) {
    my ($obj, $cb, $cbe) = @_;
    if ('ARRAY' eq ref $obj or "$obj" =~ /=ARRAY\(/) {
        unless (@$obj) {
            $cbe->() if $cbe;
            return;
        }
        return &async_repeat(
            scalar(@$obj),
            sub {
                my ($g, $index, $first, $last) = @_;
                $cb->(
                    $g,
                    $obj->[$#$obj - $index],
                    $#$obj - $index,
                    $first,
                    $last
                );
            },
            $cbe
        );
    }

    if ('HASH' eq ref $obj or "$obj" =~ /=HASH\(/) {
        unless (%$obj) {
            $cbe->() if $cbe;
            return;
        }

        my @keys = keys %$obj;
        return &async_repeat(
            scalar(@keys),
            sub {
                my ($g, $index, $first, $last) = @_;
                $cb->(
                    $g,
                    $keys[$#keys - $index],
                    $obj->{$keys[$#keys - $index]},
                    $first,
                    $last
                );
            },
            $cbe
        );
    }

    croak "Usage: async_for ARRAYREF|HASHREF, callback [, end_callback ]";
}

sub _async_repeati($$&;&) {
    my ($start, $count, $cb, $cbe) = @_;

    my $idle;
    my $wantarray = wantarray;
    $idle = aggressive_idle sub {

        my (undef, $guard) = @_;
        my $first = $start == 0;
        my $last  = $start >= $count - 1;

        if ($start >= $count) {
            $cbe->() if $cbe;
            undef $idle;
            undef $cb;
            undef $cbe;
            undef $guard;
            return;
        }

        $cb->($guard, $start, $first, $last);
        $start++;
    };

    return unless defined $wantarray;
    return guard { undef $cbe; undef $cb; undef $idle; };
}

1;
__END__

=head1 NAME

AnyEvent::Tools - instrument collection for L<AnyEvent>.

=head1 SYNOPSIS

=head2 Objects pool

    use AnyEvent::Tools qw(pool);
    my $dbh1 = ...
    my $dbh2 = ...

    ...
    my $dbhN = ...


    my $pool = pool($dbh1, $dbh2, $dbh3, ..., $dbhN);

    # later
    ...
    $pool->get(sub {
        my ($guard, $dbh) = @_;
        ... # Enjoy $dbh here

        undef $guard;           # the other process can use the $dbh
    });


=head2 Mutexes

    use AnyEvent::Tools qw(mutex);

    my $dbh = new AnyEvent::DBI(bla);
    my $mutex_dbh = mutex;


    sub some_callback() {
        ...
        $mutex_dbh->lock(sub {
            my ($mutex_guard) = @_;

            $dbh->exec("SELECT * FROM table", sub {
                my ($dbh, $rows, $rv) = @_;
                ...

                undef $mutex_guard; # unlock mutex
            });

        });
    }

=head2 Read/Write mutexes

    # Your data
    my @shared_data;

    use AnyEvent::Tools qw(rw_mutex);
    use AnyEvent::Tools qw(:mutex);     # mutex and rw_mutex
    my $rw_mutex = rw_mutex;

    sub some_callback() {
        ...
        $rw_mutex->rlock(sub {
            my ($mutex_guard) = @_;

            ...

            # You can read Your data here
            ...
            # later
            ... = sub {
                # done

                undef $mutex_guard;     # unlock mutex
            }

        });
    }

    sub other_callback() {
        ...
        $rw_mutex->wlock(sub {
            my ($mutex_guard) = @_;
            ...

            # You can write Your data here
            ...
            # later
            ... = sub {
                # done

                undef $mutex_guard;     # unlock mutex
            }

        });
    }


=head2 Foreaches

    use AnyEvent::Tools qw(:foreach);

    async_repeat $count,
        sub {
            my ($guard, $iteration, $first_flag, $last_flag) = @_;

            ... do something $count times
        },
        sub {
            ... # do something after all cycles
        };


    async_foreach
            \@array,
            sub {
                my ($guard, $element, $index, $first_flag, $last_flag) = @_;

                ... # do something with $array[$index];
            },
            sub {
                ... # do something after all cycles

            };

    async_foreach
            \%hash,
            sub {
                my ($guard, $key, $value, $first_flag, $last_flag) = @_;

                ... # do something with $hash{$key};
            },
            sub {
                my ($guard) = @_;

                ... # do something after all cycles

            };


=head2 Buffers

    use AnyEvent::Tools ':pool';    # pool and buffer
    use AnyEvent::Tools qw(buffer); # buffer only
    my $buffer = buffer;
    $buffer->on_flush( sub { ($guard, $objects_aref) = @_; .... });

    ...

    $buffer->push($obj1);
    $buffer->push($obj2);
    $buffer->push($obj3);
    $buffer->push($obj4);

    $buffer->flush;


    # autoflush after 30 second
    $buffer->interval(30);

    # autoflush if it contains more than 50 elements
    $buffer->size(50);


=head1 DESCRIPTION

In spite of event machine is started as one process, You may want to
share one resource between a lot of subprocesses.
Sometimes You also want to do  something with a  lot of data placed
in hashes/arrays.


=head1 FUNCTIONS

=head2 mutex

returns unlocked mutex.

This object provides the following methods:

=head3 lock(CODEREF)

You declare that You want to lock mutex. When it is possible the mutex will
be locked and Your callback will be called.

If the method is called in non-void context it returns guard object which can
be destroyed. So if You want You can cancel Your lockrequest.

Example:

    $mutex->lock(sub {
        my $guard = shift;
        ... # do something

        undef $guard;       # unlock mutex
    });

The callback receives a guard (see L<AnyEvent::Util#guard>) which unlocks the
mutex. Hold the guard while You need locked resourse.

=head3 is_locked

Returns B<TRUE> if mutex is locked now. Usually You shoudn't
use the function.


=head2 rw_mutex

returns unlocked read-write mutex.

This object provides the following methods:

=head3 rlock(CODEREF)

You declare that You want to lock mutex for reading. When it is
possible the mutex will be locked and Your callback will be called.

There may be a lot of read processes running simultaneously
that catch the lock.

=head3 wlock(CODEREF).

You declare that You want to lock mutex for writing. When it is
possible the mutex will be locked and Your callback will be called.

There may be only one write process that catches the lock.

Both callbacks receive a guard to hold the mutex locked.


=head3 rlock_limit(NUMBER)

Get/Set count limit for rlock. If an rlock request is come and this limit
is reached the request will be queued.


=head3 is_locked

Returns B<TRUE> if the mutex has 'read' or 'write' lock status.

=head3 is_rlocked

Returns B<TRUE> if the mutex has 'read' lock status.

B<Important>: this method returns B<FALSE> if the mutex is
wlocked (L<is_wlocked>), so if You want to know if any lock
is set, use the function L<is_locked>.

=head3 is_wlocked

Returns B<TRUE> if the mutex has 'write' lock status.

Usually You shoudn't use is_[rw]?locked functions.


=head2 async_repeat(COUNT, CALLBACK [, DONE_CALLBACK ])

Repeats calling Your callback(s).

    async_repeat 10, sub { $count++ };
    async_repeat 20, sub { $count++ }, sub { $done = 1 };

The function async_repeat returns the guard if it is called in non-void
context. Destroy the guard if You want to cancel iterations.

Iteration callback receives the following arguments:

=over

=item 1. guard

The next iteration will not start until the guard is destroyed.

=item 2. iteration number

The number of current iteration.

=item 3. first_flag

TRUE on the first iteration.

=item 4. last_flag

TRUE on the last iteration.

=back

=head2 async_for(HASREF|ARRAYREF, CALLBACK [, DONE_CALLBACK ]);

Calls Your callbacks for each array or hash element.

The function returns the guard if it is called in non-void
context. Destroy the guard if You want to cancel iterations.

If You process an array using the function, iteration callback
will receive the following arguments:

=over

=item 1. guard

The next iteration will not start until the guard is destroyed.

=item 2. element

Next array element.

=item 3. index

Index of array element.

=item 4. first_flag

The iteration is the first.

=item 5. last_flag

The iteration is the last.

=back

If You process a hash using the function, iteration callback
will receive the following arguments:

=over

=item 1. guard

The next iteration will not start until the guard is destroyed.

=item 2. key

=item 3. value

=item 4. first_flag

The iteration is the first.

=item 5. last_flag

The iteration is the last.

=back

=head2 async_rfor(HASREF|ARRAYREF, CALLBACK [, DONE_CALLBACK ]);

The same as async_for but has reverse sequence.


=head2 pool

Returns the object that incapsulates object collection. You can cacth one
object of the collection using the method:

=head3 get($callback)

    $pool->get(sub { my ($guard, $object) = @_; ... });

If there is a free object in the pool, Your callback will be called.
The callback receives also a guard. Hold the guard while You use the
object.


There are also a few methods:

=head3 push($object);

    my $id = $pool->push($dbh);

Add an object in pool. Returns the object's identifier. You can use
that to delete the object from pool:

=head3 delete($id)

    $pool->delete($id);
    $pool->delete($id, sub { # on_delete });

Deletes object from pool.

B<Note>: The function will croak if it receives an ivalid object id.


=head2 buffer

Returns the buffer object. Can receive a few named arguments: L<interval>,
L<size>, L<on_flush>. They are the same that the following functions.

It provides the following methods:

=head3 push

Push the object into buffer.

    $buffer->push(123);
    $buffer->push($obj);
    $buffer->push(1,2,3);

=head3 unshift

Unshift the object into buffer

    $buffer->unshift(123);
    $buffer->unshift(1,2,3);

=head3 unshift_back

The function can be called only inside L<on_flush> handler (until its
guard destroyed). It can be used to unshift non-flushed data (for
example: if an error was occured) back to buffer. Receives B<ARRAYREF>
(like L<on_flush>'s callback).

=head3 flush

Flush buffer (calls L<on_flush> function)

=head3 interval

Get/Set autoflush interval (zero == periodical autoflush is disabled)


=head3 size

Get/Set buffer size (zero == buffer overflow autoflush is disabled)

=head3 unique_cb

If the callback is defined it will be called for each pushing element
to determine its key value. If the key has already appeared since last
L<flush> the element will be ignored. So buffer will contain only unique
objects.

=head3 on_flush

Set flush callback. It will be called if L<flush> function is called or
buffer overflow is detected or timeout is exceeded.

The callback receives two arguments:

=over

=item guard

If You hold the guard, and user calls L<flush>, flushing will be delayed.

=item arrayref

Reference to object list that were accumulated.

=head1 SEE ALSO

L<AnyEvent>

=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 VCS

The project is placed in my git repo. See here:
L<http://git.uvw.ru/?p=anyevent-tools;a=summary>

=cut
