package Context::Vars::Context;

use 5.010;
use strict;
use warnings;

use Context::Vars ();

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Context::Vars::Context - one captured set of values

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Context::Vars qw($request_id);

    my $ctx = Context::Vars->capture;

    $ctx->run(sub { print "$request_id\n" });

    my @names = $ctx->names;
    my $id    = $ctx->get('request_id');

=head1 DESCRIPTION

A set of values for the variables, kept: what L<Context::Vars/capture> or
L<Context::Vars/current> returns. Objects of this class are made only by
those two methods. One blessed by hand, or restored by a serialiser, is
refused by every method.

An object belongs to the thread that made it. A new thread does not get it.

=head1 METHODS

=head2 run

    my @result = $ctx->run(sub { ... }, @args);

Calls the code with the arguments, with every variable reading the values
the object holds, and returns what the code returned, in the caller's
context: list, scalar or void. When the code returns or dies, the variables
read what they read before. A die is not caught.

The object itself is what the code runs in. A change made to it during one
call, and not undone when a sub returns, is seen by the next call of C<run>
on the same object.

=head2 names

    my @names = $ctx->names;

The names of the variables that have a value in the object, sorted, without
the C<$>.

=head2 get

    my $value = $ctx->get('request_id');

The value one variable has in the object, without running anything in it.
The name may be given with or without the C<$>. A variable with no value
there gives C<undef>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
