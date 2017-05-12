package Closure::Loop;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.3');

my @SIGS    = qw(last next redo);
my @EXPORTS = qw(yield);

sub import {
    my $caller  = caller;
    my %signals = map { $_ => 1 } ( @SIGS, @_ );

    no strict 'refs';

    for my $sig (keys %signals) {
        *{ $caller . '::' . $sig } = sub {
            my $self = shift;
            croak "$sig must be called as a method"
                unless ref($self) && $self->isa($caller);
            die [ $self, $sig ];
        };

        *{ $caller . '::is_' . $sig } = sub {
            my $self  = shift;
            croak "is_$sig must be called as a method"
                unless ref($self) && $self->isa($caller);
            my $excep = shift || $@;
            return ref($excep) eq 'ARRAY' &&
                   $excep->[0] == $self &&
                   $excep->[1] eq $sig;
        };
    }

    for my $sub ( @EXPORTS ) {
        *{ $caller . '::' . $sub } = \&{ $sub };
    }
}

sub yield {
    my $self = shift;
    my $cb   = shift;

    croak "yield must be called as a method"
        unless ref($self);

    croak "yield must be called with a callback (code ref)"
        unless ref($cb) eq 'CODE';

    Y: {
        eval {
            $cb->(@_);
        };
        redo Y if $self->is_redo;
        return if $self->is_next;
        die $@ if $@;
    }
}

1;
__END__

=head1 NAME

Closure::Loop - redo, last, next for closure based loops

=head1 VERSION

This document describes Closure::Loop version 0.0.3

=head1 SYNOPSIS

    package MyIterator;
    use Closure::Loop;      # mixin

    sub new {
        my $class = shift;
        return bless { }, $class;
    }

    sub forAll {
        my $self = shift;
        my $cb   = pop || die "No callback";

        for my $i (@_) {
            eval {
                $self->yield($cb, $i);
            };
            last if $self->is_last;
            die $@ if $@;
        }
    }

    package main;

    my $iter = MyIterator->new();

    my @in  = ( 1, 2, 3 );
    my @out = ( );

    $iter->forAll(@in, sub {
        my $i = shift;
        $iter->next if $i == 2;     # skip value
        push @out, $i;
    });

    # @out is ( 1, 3 )

=head1 DESCRIPTION

An idea that Perl programmers can usefully borrow from Ruby is the
concept of synthesizing new looping constructs by passing a block of
code to a function that repeatedly calls it with successive values in
a sequence.

In Ruby this looks like this:

    def count_to_ten
        i = 1
        while i <= 10
            yield i
            i = i + 1
        end
    end

    count_to_ten do |i|
        puts i
    end

In Perl the same thing looks like this:

    sub count_to_ten {
        my $block = shift;
        my $i = 1;
        while ($i <= 10) {
            $block->($i);
            $i++;
        }
    }

    count_to_ten(sub {
        my $i = shift;
        print "$i\n";
    });

That example is deliberately trivial. In practice this technique can be
used to implement a loop like construct that, for example, walks the
nodes in a binary tree - something that isn't easy with a normal loop.

The body of the loop is actually a closure so it has complete access to
the lexical scope in which it is defined. In short it works just like
the body of a loop for our purposes - with one exception.

For normal Perl loops it's possible to use the last, next and redo
statements to modify iteration of the loop. That won't work as expected
here. If we use them in our pseudo loop we'll get a warning (because
we're actually trying to jump out of a subroutine using them) and
they'll end up affecting the first enclosing loop or block they find -
which may impact unpredictably on the iterator function, particularly if
it doesn't actually contain a loop.

This module makes it easy to implement modules that expose iterator
methods and which provide an interface for controlling the iteration of
the loop which resembles an object oriented version of Perl's normal
loop control statements.

Here's a simple module:

    package MyIterator;
    use Closure::Loop;      # mixin

    sub new {
        my $class = shift;
        return bless { }, $class;
    }

    sub forAll {
        my $self = shift;
        my $cb   = pop || die "No callback";

        for my $i (@_) {
            eval {
                $self->yield($cb, $i);
            };
            last if $self->is_last;
            die $@ if $@;
        }
    }

The forAll iterator isn't very exciting; it just iterates over whatever
arguments we pass to it. Still, it does enough to illustrate the point.

When you use Closure::Loop three loop control methods (C<redo>, C<last>
and C<next>) and four helper methods (C<is_redo>, C<is_last>, C<is_next>
and C<yield>) are added to your class.

Instead of calling the supplied block (or callback) directly your
iterator should call C<yield> passing it the callback and any
parameters. C<yield> handles C<redo> and C<next> itself. Calls to
C<last> will throw an exception object which must be trapped with an
eval and can be tested for by calling C<is_last>.

Because the logic for getting out of a (possibly deeply recursive)
iterator depends on how it's structured your code needs to handle
C<last> itself. The behaviour of C<next> and C<redo> can be handled
automatically by C<yield>

In the example above a call to the C<last> method is turned into a
normal Perl C<last> to break out of the loop but it's up to you to
handle it correctly depending on the semantics of the iterator.

Here's some code that calls the iterator:

    use MyIterator;

    my $iter = MyIterator->new();

    my @in  = ( 1, 2, 3 );
    my @out = ( );

    $iter->forAll(@in, sub {
        my $i = shift;
        $iter->next if $i == 2;     # skip value
        push @out, $i;
    });

    # @out is ( 1, 3 )

Where the next statement would be used in a normal loop we instead call
the iterator object's C<next> method - but the effect is the same: the
iterator immediately starts the next iteration. Similarly a call to the
iterator's C<redo> method will restart the current iteration of the
loop. Finally, because we implemented support for C<last> in C<forAll>
we could call $iter->last to terminate iteration cleanly.

Optionally you may declare additional loop control methods like this

    use Closure::Loop qw(prune);

That would import C<prune> and C<is_prune> into your module's namespace
in addition to the standard loop control methods. You might then write
a tree walker that would respond to 

    $iter->prune;

by aborting traversal of the current subtree without stopping
altogether.

=head1 INTERFACE 

=over

=item C<next>

Called within the body of a loop block causes the next iteration of the loop
to start immediately.

=item C<redo>

Restarts the current iteration of the loop passing the same parameters.

=item C<last>

Immediately terminates iteration.

=item C<yield( args )>

Called within the iterator to pass control to the loop body. Handles C<redo>
and C<next> internally and throws an exception if C<last> is called. The exception
is a reference to a two element array:

    [ $self, 'last' ]

The C<is_last> helper may be used to detect this specific exception value. Unrecognised
exceptions should be rethrown:

    die $@ if $@;

=item C<is_last()>

Returns true if the current value of $@ (or the value supplied as the
first argument) is an exception that represents the C<last> loop control
message for this object.

=item C<is_redo()>

Returns true if the current value of $@ (or the value supplied as the
first argument) is an exception that represents the C<redo> loop control
message for this object.

=item C<is_next()>

Returns true if the current value of $@ (or the value supplied as the
first argument) is an exception that represents the C<next> loop control
message for this object.

=back

=head1 DIAGNOSTICS

=over

=item C<< %s must be called as a method >>

All of the methods added to your class must actually be called as
methods.

=item C<< yield must be called with a callback (code ref) >>

C<yield> expects a code reference to call.

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-closure-loop@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
