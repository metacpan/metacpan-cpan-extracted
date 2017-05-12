# ABSTRACT: Block till one or more events fire
package AnyEvent::Collect;
{
  $AnyEvent::Collect::VERSION = '0.1.0';
}
use strict;
use warnings;
use AnyEvent;
use Event::Wrappable;
use Sub::Exporter -setup => {
    exports => [qw( collect collect_all collect_any event )],
    groups => { default => [qw( collect collect_all collect_any event )] },
    };

use constant COLLECT_TYPE => 0;
use constant COLLECT_CV   => 1;

my @cvs;



sub collect_all(&) {
    my( $todo ) = @_;
    my $cv = AE::cv;
    Event::Wrappable->wrap_events( $todo, sub {
        my( $listener ) = @_;
        $cv->begin;
        my $ended = 0;
        return sub { $listener->(@_); $cv->end unless $ended++ };
    } );
    $cv->recv;
}
*collect = *collect_all;

sub collect_any(&) {
    my( $todo ) = @_;
    my $cv = AE::cv;
    Event::Wrappable->wrap_events( $todo, sub {
        my( $listener ) = @_;
        return sub { $listener->(@_); $cv->send };
    } );
    $cv->recv;
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

AnyEvent::Collect - Block till one or more events fire

=head1 VERSION

version 0.1.0

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Collect;

    # Wait for all of a collection of events to trigger once:
    my( $w1, $w2 );
    collect {
        $w1 = AE::timer 2, 0, event { say "two" };
        $w2 = AE::timer 3, 0, event { say "three" };
    }; # Returns after 3 seconds having printed "two" and "three"

    # Wait for any of a collection of events to trigger:
    my( $w3, $w4 );
    collect_any {
        $w3 = AE::timer 2, 0, event { say "two" };
        $w4 = AE::timer 3, 0, event { say "three" };
    };
    # Returns after 2 seconds, having printed 2.  Note however that
    # the other event will still be emitted in another second.  If
    # you were to then execute the sleep below, it would print three.


    # Or using L<ONE>
    use ONE::Timer;
    use AnyEvent::Collect;
    collect {
        ONE::Timer->after( 2 => event { say "two" } );
        ONE::Timer->after( 3 => event { say "three" } );
    }; # As above, returns after three seconds having printed "two" and
       # "three"

    # And because L<ONE> is based on L<MooseX::Event> and L<MooseX::Event>
    # is integrated with L<Event::Wrappable>, you can just pass in raw subs
    # rather then using the event helper:

    collect_any {
        ONE::Timer->after( 2 => sub { say "two" } );
        ONE::Timer->after( 3 => sub { say "three" } );
    }; # Returns after 2 seconds having printed "two"

=head1 DESCRIPTION

This allows you to reduce a group of unrelated events into a single event.
Either when the first event is emitted, or after all events have been
emitted at least once.

For your convenience this re-exports the event helper from
L<Event::Wrappable>.  Only event listeners created with it or via a class
that integrates with Event::Wrappable (eg, L<MooseX::Event>) will be
captured.

=head1 HELPERS

=head2 sub event( CodeRef $todo )

See L<Event::Wrappable> for details.

=head2 sub collect( CodeRef $todo )

=head2 sub collect_all( CodeRef $todo )

Will return after all of the events declared inside the collect block have
been emitted at least once.

=head2 sub collect_any( CodeRef $todo )

Will return after any of the events declared inside the collect block have
been emitted at least once.  Note that it doesn't actually cancel the
unemitted events-- you'll have to do that yourself, if that's what you want.

=for test_synopsis use 5.10.0;

=head1 SEE ALSO



=over 4

=item *

L<Event::Wrappable|Event::Wrappable>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/iarna/AnyEvent-Collect>
and may be cloned from L<git://https://github.com/iarna/AnyEvent-Collect.git>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

More information can be found at:

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/AnyEvent-Collect>

=back

=head2 Bugs / Feature Requests

Please report any bugs at L<https://github.com/iarna/AnyEvent-Collect/issues>.

=head1 AUTHOR

Rebecca Turner <becca@referencethis.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Rebecca Turner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

