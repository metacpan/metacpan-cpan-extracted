#!/usr/bin/perl
use strict; use warnings;

package Acme::Fork::Lazy;

=head1 NAME

Acme::Fork::Lazy - abstract forking with lazy variables

=head1 SYNOPSIS

 use Acme::Fork::Lazy qw/:all/;
 use feature 'say';

 ###
 # Single parallel calculation

 my $foo = forked { expensive_calculation_to_do_in_parallel() };
 # ...then (sooner or later...)
 say $foo; 

 ###
 # Parallel map

 my @list = map forked { sleep $_; $_*2 }, 1..10;
 sleep 5; # gives enough time for first 5 elements to be calculated
 say $_ for @list;

 ###

 END {
    wait_kids; # make sure we're not leaving behind any zombies
 }

=head1 DESCRIPTION

We often want to fork a process with an expensive calculation.  This involves making the child
write the answer back to the parent, who will then have to poll the child occasionally to check
if it answered back.  There are abstractions, like L<Poe::Wheel::Run> (lovely if you're already
using L<POE>).  This is another one, using lazy variables:

=head2 C<forked>

 my $foo = forked { do_calculation() };
 print "The answer was $foo\n";

C<forked> returns a lazy calculation that will wait on the child process and return its
result as a Perl data structure.  If the child process isn't ready, then it will wait for it.
This means that you could just as easily do:

 my $foo = forked { do_calculation() };
 do_some_stuff_that_might_take_about_the_same_time_as_calculation();
 print "The answer was $foo\n";

without having to worry about polling etc. if the work in the main process didn't quite take
long enough.

Note that the forked result must be a scalar.  

=head2 C<wait_kids>

 END {
     wait_kids();
 }

Place this anywhere that you'd like to stop and wait for the children to catch up,
and in particular in an END block to avoid producing zombies.

=head1 BUGS and TODO

Lots.  Once those are resolved, we could upgrade this from C<Acme::> to C<Proc::Forked::Lazy>.

=over 4

=item *

The Lazy modules (see L</SEE ALSO>) are all currently broken in various
exciting ways.  So you may find that certain uses (like using L<Data::Dumper>
to output the result) won't trigger forcing the lazy result, and so on.

=item *

Only scalar values may be returned by a C<forked> block.

=item *

No attempt is made to handle failure: timeouts/retry/error etc.

=item *

The client has to manually call C<wait_kids> in END to make sure all kids
exited cleanly.

=back

Suggestions and patches for any of the above are very welcome (as well as new
bug reports!)

=head1 SEE ALSO

=over 4

=item *

The lazy semantics are provided by one of the following:

=over 8

=item L<Scalar::Defer>

The original, by Audrey Tang

=item L<Data::Thunk>

An ambitious and complex implementation by Nothingmuch.

=item L<Scalar::Lazy>

A much simpler implementation.

=back

=item *

The result is currently sent back from the child process coded in L<YAML>.

=item *

If you can stomach POE, look at L<POE::Wheel::Run>

=item *

Various IPC modules wrap C<fork> in more or less palatable ways: L<IPC::Run>, L<Proc::Fork>, etc.

=back

=head1 AUTHOR and LICENSE

 (C) 2008 osfameron@cpan.org

This module is distributed under the same conditions as Perl itself.

=cut

our $VERSION = 0.03;

use IO::Pipe;
use YAML;
# use Data::Thunk;
# use Scalar::Lazy;
use Scalar::Defer;
# all need a kludge for reference example

use base 'Exporter';
our %EXPORT_TAGS = (
     all => [ qw/ forked wait_kids / ],
    );
Exporter::export_ok_tags('all');

sub forked (&) {
    my $sub = shift;
    my $p = IO::Pipe->new();

    if (my $child = fork) {
        $p->reader;
        return lazy {
            waitpid $child, 0;
            local $/ = undef;
            my $result = <$p>;
            Load($result);
            };
    } else {
        $p->writer;
        my @result = $sub->();
        print $p Dump(@result);
        exit;
    }
}
sub wait_kids {
    # Wait on all kids, possibly getting rid of zombies etc.
    use POSIX ":sys_wait_h";
    my $kid;
    do {
        $kid = waitpid(-1, 0);
    } while $kid > 0;
}

1;
