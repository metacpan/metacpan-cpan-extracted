package Context::Vars;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Context::Vars', $VERSION);

1;

__END__

=head1 NAME

Context::Vars - variables with context scope

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Context::Vars q{$variable};

    $variable = 'one';

    sub change {
        $variable = 'two';
        print $variable;    # two
    }

    change();

    print $variable;    # one

    # A callback run later sees the values of the moment it was wrapped.
    sub handle {
        my ($id) = @_;
        $variable = $id;
        return Context::Vars->wrap(sub { print "$variable\n" });
    }

    my $later = handle('request 42');
    $later->();      # request 42

=head1 DESCRIPTION

A name given to C<use> becomes a scalar in the calling package. Every package
that imports the same name shares the one variable, and what it reads is the
value in the context that is current at that moment.

An assignment to the variable holds until the sub it is written in returns,
through any block in that sub and any way out of it, and is seen by every sub
that sub calls. Code outside any sub keeps what it assigns for the program.

A callback wrapped with L</wrap>, or run with L<Context::Vars::Context/run>,
sees the values of the moment it was wrapped or captured, wherever and
whenever it runs: from an event loop, after other work has changed them, or
after other requests have come and gone.

=head1 LIMITS

=over 4

=item * Only scalars can be imported, with a plain name: C<$name>.

=item * No event loop captures for you. A callback sees its registering
code's values only when it is wrapped; see L</CALLBACKS AND LOOPS>.

=item * An assignment the module cannot see when the sub is compiled is not
scoped to that sub. That is one made through C<@_>, a C<for> or C<grep>
alias, a symbolic reference, or a string C<eval> inside a sub that makes no
other assignment. It changes whatever context is current.

=item * A variable can hold a reference to a hash, an array, code or an
object, and the reference is its value: a sub's scope covers which reference
the variable holds, not what that reference points at. A change made through
it, C<< $variable->{key} = 1 >>, is seen by every context holding the same
reference. To change a structure for one sub only, assign a changed copy:
C<< $variable = { %$variable, key => 1 } >>. Vivifying through a variable that
is not set, C<< $variable->{key} = 1 >> when it holds nothing, sets it in
whatever context is current.

=item * A sub that only assigns a variable for its caller changes nothing
the caller can see: the assignment ends when that sub returns. Return the
value and let the caller assign it.

=back

=head1 CALLBACKS AND LOOPS

A callback that runs later, from an event loop, a queue or a future, sees the
values of the moment it was registered only if whatever registered it
captured them. L</wrap> does that for one callback. A loop that does it for
every callback it keeps is said to be wired.

A callback on a loop that is not wired runs outside any context. There a
variable reads nothing, unless code outside any sub has assigned it, in which
case it reads that value: never the value of the task that registered the
callback.

=head1 ASYNC SUBS

Under L<Future::AsyncAwait>, an C<async sub> keeps its own variables across
C<await>: after the await it reads what it could see before it, and what it
assigns is not seen by the code that resumed it. This needs nothing from
L<Future::AsyncAwait> to install, and works whichever of the two modules is
loaded first.

=head1 METHODS

These are for code that runs other code later: an event loop, a queue, a
future, a test. An application that only reads and assigns its variables does
not need them.

=head2 capture

    my $ctx = Context::Vars->capture;

Returns a L<Context::Vars::Context> holding the values every variable has
now. Later assignments, here or anywhere, do not change what it holds.

=head2 wrap

    my $callback = Context::Vars->wrap(sub { ... });

Returns a code reference that calls the given one with the values every
variable has now, wherever and whenever it is called. Its arguments are
passed through and its return value is returned. Each call starts from those
values afresh: nothing one call does is seen by the next.

=head2 current

    my $ctx = Context::Vars->current;

Returns a L<Context::Vars::Context> for the context code is running in now,
rather than a copy of it. Code run in it with L<Context::Vars::Context/run>
and the code running now share their values.

=head1 C ABI

An event loop, a future or a queue written in C can capture the variables
when a callback is registered and run the callback with them, and C code can
read and assign a variable by name, with no Perl call in between. The header,
F<context_vars_abi.h>, is installed with this module and found through
L<ExtUtils::Depends>; it describes the table of functions, how to find it at
run time, and the three calls a loop makes for each callback. A consumer
needs that header and nothing else.

=head1 DEPENDENCIES

L<HAMT>. Loading this module fails, with a message that says why, when HAMT
is not installed or is too old.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-context-vars at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Context-Vars>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
