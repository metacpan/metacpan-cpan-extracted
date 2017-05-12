package Carp::Trace;
use strict;
use Data::Dumper;
use Devel::Caller::Perl qw[called_args];

BEGIN {
    use     vars qw[@ISA @EXPORT $VERSION $DEPTH $OFFSET $ARGUMENTS];
    use     Exporter;

    @ISA    = 'Exporter';
    @EXPORT = 'trace';
}

$OFFSET     = 0;
$DEPTH      = 0;
$ARGUMENTS  = 0;
$VERSION    = '0.12';

sub trace {
    my $level   = shift || $DEPTH       || 0;
    my $offset  = shift || $OFFSET      || 0;
    my $args    = shift || $ARGUMENTS   || 0;

    my $trace = '';
    my $i = 1 + $OFFSET;

    while (1) {
        last if $level && $level < $i;

        my  @caller = caller($i);
        last unless scalar @caller;

        my  ($package, $filename, $line, $subroutine, $hasargs, $wantarray,
            $evaltext, $is_require, $hints, $bitmask) = @caller;

        my $string = $subroutine eq '(eval)'
                    ?   $package . '::' . $subroutine . qq| [$i]|
                        . (defined $evaltext ? qq[\n\t$evaltext] : '')
                    :   $subroutine . qq| [$i]|;
        $string =~ s/\n;$/;/gs;

        $string .= qq[\n\t];

        $string .= q[require|use - ] if $is_require;
        $string .= defined $wantarray
                        ? $wantarray ? 'list - ' : 'scalar - '
                        : 'void - ';
        $string .= $hasargs ? 'new stash' : 'no new stash';
        $string .=  qq[\n\t] . $filename . ' line ' . $line . qq[\n];

        if ($args) {
            local $Data::Dumper::Varname    = 'ARGS';
            local $Data::Dumper::Indent     = 1;

            for my $line ( split $/, Dumper( called_args($i) ) ) {
                $string .=  "\t$line\n";
            }
        }

        $trace = $string . $trace;

        $i++;
    }

    return $trace;
}

__END__

=head1 NAME

Carp::Trace - simple traceback of call stacks

=head1 SYNOPSIS

    use Carp::Trace;

    sub flubber {
        die "You took this route to get here:\n" .
            trace();
    }

=head1 DESCRIPTION

Carp::Trace provides an easy way to see the route your script took to
get to a certain place. It uses simple C<caller> calls to determine
this.

=head1 FUNCTIONS

=head2 trace( [DEPTH, OFFSET, ARGS] )

C<trace> is a function, exported by default, that gives a simple
traceback of how you got where you are. It returns a formatted string,
ready to be sent to C<STDOUT> or C<STDERR>.

Optionally, you can provide a DEPTH argument, which tells C<trace> to
only go back so many levels. The OFFSET argument will tell C<trace> to
skip the first [OFFSET] layers up.

If you provide a true value for the C<ARGS> parameter, the arguments
passed to each callstack will be dumped using C<Data::Dumper>.
This might slow down your trace, but is very useful for debugging.

See also the L<Global Variables> section.

C<trace> is able to tell you the following things:

=over 4

=item *

The name of the function

=item *

The number of callstacks from your current location

=item *

The context in which the function was called

=item *

Whether a new instance of C<@_> was created for this function

=item *

Whether the function was called in an C<eval>, C<require> or C<use>

=item *

If called from a string C<eval>, what the eval-string is

=item *

The file the function is in

=item *

The line number the function is on

=back

The output from the following code:

    use Carp::Trace;

    sub foo { bar() };
    sub bar { $x = baz() };
    sub baz { @y = zot() };
    sub zot { print trace() };

    eval 'foo(1)';

Might look something like this:

    main::(eval) [5]
        foo(1);
        void - no new stash
        x.pl line 1
    main::foo [4]
        void - new stash
        (eval 1) line 1
    main::bar [3]
        void - new stash
        x.pl line 1
    main::baz [2]
        scalar - new stash
        x.pl line 1
    main::zot [1]
        list - new stash
        x.pl line 1

=head1 Global Variables

=head2 $Carp::Trace::DEPTH

Sets the depth to be used by default for C<trace>. Any depth argument
to C<trace> will override this setting.

=head2 $Carp::Trace::OFFSET

Sets the offset to be used by default for C<trace>. Any offset
argument to C<trace> will override this setting.

=head2 $Carp::Trace::ARGUMENTS

Sets a flag to indicate that a C<trace> should dump all arguments for
every call stack it's printing out. Any C<args> argument to C<trace>
will override this setting.

=head1 AUTHOR

This module by
Jos Boumans E<lt>kane@cpan.orgE<gt>.

=head1 COPYRIGHT

This module is
copyright (c) 2002 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.

=cut
