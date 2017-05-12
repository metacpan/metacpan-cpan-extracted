# ABSTRACT: Call asynchronous APIs synchronously
package AnyEvent::Capture;
{
  $AnyEvent::Capture::VERSION = '0.1.1';
}
use strict;
use warnings;
use AnyEvent ();
use Sub::Exporter -setup => {
    exports => [qw( capture )],
    groups => { default => [qw( capture )] },
};


sub capture(&) {
    my( $todo ) = @_;
    my $cv = AE::cv;
    my(@results) = $todo->( sub { $cv->send(@_) } );
    return $cv->recv;
}

1;


__END__
=pod

=encoding utf-8

=head1 NAME

AnyEvent::Capture - Call asynchronous APIs synchronously

=head1 VERSION

version 0.1.1

=head1 SYNOPSIS

    use AnyEvent::Capture;
    use AnyEvent::Socket qw( inet_aton );
    
    # Call the async version of inet_aton in a synchronous fashion, but
    # while we're doing this other events will fire.
    my @ips = capture { inet_aton( 'localhost', shift ) };

    # An example of waiting for a child without blocking events from firing
    # while we wait.
    sub wait_for_child($) {    
        my( $pid ) = @_;
        my($rpid,$rstatus) = capture { AnyEvent->child(pid=>$pid, cb=>shift) };
        return $rstatus;
    }

=head1 DESCRIPTION

Simple sugar to allow you to call an event based API in a blocking fashion. 
Other events will of course continue to fire while you're waiting.

The first argument passed to your block will be the event listener you
should use as your callback.  The capture call will return when that
subroutine is called.

Any return result from your block will be stored until the callback is
triggered.  This way guard objects returned from AnyEvent won't immediate
expire the listener.

=head1 HELPERS

=head2 sub capture( CodeRef $todo ) returns Any

Executes $todo, passing it a CodeRef to be used as an event listener.  After
$todo returns, it enters the event loop and waits till the CodeRef is
called.  The return value of $todo will be stored until such time as the
CodeRef is called.  It then returns the arguments that were passed to the
CodeRef.

In so doing, it allows you to call an asychronous function in a synchronous
fashion.

This module is similar to L<Data::Monad::CondVar> but much simpler.  You
could write the example using L<Data::Monad::CondVar> this way:

    my @ips = (as_cv {inet_aton( 'localhost', shift ) })->recv;

=head1 SEE ALSO



=over 4

=item *

L<Data::Monad::CondVar|Data::Monad::CondVar>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/iarna/AnyEvent-Capture>
and may be cloned from L<git://https://github.com/iarna/AnyEvent-Capture.git>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

More information can be found at:

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/AnyEvent-Capture>

=back

=head2 Bugs / Feature Requests

Please report any bugs at L<https://github.com/iarna/AnyEvent-Capture/issues>.

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

