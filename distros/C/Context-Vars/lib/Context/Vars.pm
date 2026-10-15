package Context::Vars;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Context::Vars', $VERSION);

1;

__END__

=head1 NAME

Context::Vars - variables with context scope

=head1 VERSION

Version 0.04

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

=head1 ARRAYS, HASHES AND STRUCTURES

    use Context::Vars qw(@trail %seen $config);

Arrays and hashes are imported as scalars are, and follow the same rule: a
change to one, an element stored or deleted, a C<push>, a whole assignment,
holds until the sub it is written in returns.

The rule goes all the way down. A plain hash or array stored in any context
variable, at any depth, belongs to the context: C<< $seen{a}{b} = 1 >>,
C<< push @{ $seen{list} }, 1 >> or C<< $config->{db}{host} = 'x' >> in a sub is
undone when that sub returns, and a capture or a wrapped callback sees the
structure as it was at that moment. What is stored is the variable's own
copy: changing the hash or array that was assigned does not change the
variable, and the other way round.

An object, or a code reference, stored anywhere in such a structure is kept
as the reference it is, and what it points at is shared, as its class
expects.

What you read back is not the hash or array that was stored but one that
stands for it: C<ref> says C<HASH> or C<ARRAY> and everything a hash or array
does works, but two reads of C<$seen{a}> are two different references, and
C<==> between them is false. Copy one out, C<< { %{ $seen{a} } } >>, for an
ordinary hash.

Reading or writing an element costs more than it does in an ordinary hash or
array: some hundreds of nanoseconds against some tens, and more for each level
down.

=head1 LIMITS

=over 4

=item * Names are plain identifiers: C<$name>, C<@name>, C<%name>.

=item * No event loop captures for you. A callback sees its registering
code's values only when it is wrapped; see L</CALLBACKS AND LOOPS>.

=item * An assignment the module cannot see when the sub is compiled is not
scoped to that sub. That is one made through C<@_>, a C<for>, C<grep> or
C<map> alias, a symbolic reference, a string C<eval> inside a sub that makes
no other assignment, or a hash or array read out of a variable and kept in a
lexical before it is written through: C<< my $h = $seen{a}; $h->{b} = 1 >>.
It changes whatever context is current.

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
