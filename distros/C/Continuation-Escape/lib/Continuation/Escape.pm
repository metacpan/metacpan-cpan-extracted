package Continuation::Escape;
use strict;
use warnings;
use 5.8.0;
use base 'Exporter';
our @EXPORT = 'call_cc';
our $VERSION = '0.03';

use Scope::Upper qw/unwind HERE/;

# This registry is just so we can make sure that the user is NOT trying to save
# and run continuations later.
# Sorry if the name got you excited. :/
our %CONTINUATION_REGISTRY;

sub call_cc (&) {
    my $code = shift;

    my $escape_level = HERE;
    my $wantarray = wantarray;

    my $escape_continuation;
    $escape_continuation = sub {
        if (!exists($CONTINUATION_REGISTRY{$escape_continuation})) {
            require Carp;
            Carp::croak("Escape continuations are not usable outside of their original scope.");
        }

        unwind(($wantarray ? @_ : $_[0]) => $escape_level);
    };

    local $CONTINUATION_REGISTRY{$escape_continuation} = $escape_continuation;
    return $code->($escape_continuation);
}

1;

__END__

=head1 NAME

Continuation::Escape - escape continuations (returning higher up the stack)

=head1 SYNOPSIS

    use Continuation::Escape;

    my $ret = call_cc {
        my $escape = shift;

        # ...
        sub {
            # ...
            $escape->(1 + 1);
            # code never reached
        }->();
        # code never reached
    };

    $ret # 2

=head1 NAME

An escape continuation is a limited type of continuation that only allows you
to jump back up the stack. Invoking an escape continuation is a lot like
throwing an exception, however escape continuations do not necessarily indicate
exceptional circumstances.

This module builds on Vincent Pit's excellent L<Scope::Upper> to give you a
nicer interface to returning to outer scopes.

=head1 CONTEXT

If the return context of the continuation is scalar, the first argument to the
continuation will be returned. This is slightly more useful than C<1>, the
number of arguments to the continuation. This DWIMs when you want to return
a scalar anyway.

=head1 CAVEATS

Escape continuations are B<not> real continuations. They are not re-invokable
(meaning you only get to run them once) and they are not savable (once the
C<call_cc> block ends, calling the continuation it gave you is an error). This
module goes to some length to ensure that you do not try to do either of these
things.

Real continuations in Perl would require a lot of work. But damn would they be
nice. Does anyone know how much work would even be involved? C<:)>

=head1 AUTHOR

Shawn M Moore, C<sartak@gmail.com>

=head1 THANKS TO

Vincent Pit for writing the excellent L<Scope::Upper> which does B<two> things
that I've wanted forever (escape continuations and localizing variables at
higher stack levels).

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

