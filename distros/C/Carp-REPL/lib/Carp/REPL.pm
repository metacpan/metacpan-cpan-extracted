package Carp::REPL;
use strict;
use warnings;
use 5.006000;

our $VERSION = '0.18';

our $noprofile = 0;
our $bottom_frame = 0;

sub import {
    my $nodie  = grep { $_ eq 'nodie'    } @_;
    my $warn   = grep { $_ eq 'warn'     } @_;
    my $test   = grep { $_ eq 'test'     } @_;
    $noprofile = grep { $_ eq 'noprofile'} @_;
    my $repl   = grep { $_ eq 'repl'     } @_;

    if ($repl) {

        require Sub::Exporter;
        my $import_repl = Sub::Exporter::build_exporter(
            {
                exports    => ['repl'],
                into_level => 1,
            }
        );

        # get option of 'repl'
        my $seen;
        my ($maybe_option) = grep { $seen || $_ eq 'repl' && $seen++ } @_;

        # now do the real 'repl' import
        $import_repl->( __PACKAGE__, 'repl',
            ref $maybe_option ? $maybe_option : ()
        );
    }
    
    $SIG{__DIE__}  = \&repl unless $nodie;
    $SIG{__WARN__} = \&repl if $warn;

    if ($test) {
        require Test::Builder;
        my $ok = \&Test::Builder::ok;

        no warnings 'redefine';
        *Test::Builder::ok = sub {
            local $Test::Builder::Level = $Test::Builder::Level + 1;
            my $passed = $ok->(@_);
            local $bottom_frame = $Test::Builder::Level;
            repl("Test failure") if !$passed;
            return $passed;
        };
    }
}

sub repl {
    my $quiet = @_ && !defined($_[0]);

    warn @_, "\n" unless $quiet; # tell the user what blew up

    require Devel::REPL::Script;

    my ($runner, $repl);
    if ($noprofile) {
        $repl = $runner = Devel::REPL->new;
    }
    else {
        $runner = Devel::REPL::Script->new;
        $repl = $runner->_repl;
    }

    $repl->load_plugin('Carp::REPL');

    warn $repl->stacktrace unless $quiet;

    $runner->run;
}

1;

__END__

=head1 NAME

Carp::REPL - read-eval-print-loop on die and/or warn

=head1 SYNOPSIS

The intended way to use this module is through the command line.

    perl -MCarp::REPL tps-report.pl
        Can't call method "cover_sheet" without a package or object reference at tps-report.pl line 6019.

    # instead of exiting, you get a REPL!

    $ $form
    27B/6

    $ $self->get_form
    27B/6

    $ "ah ha! there's my bug, I thought get_form returned an object"
    ah ha! there's my bug, I thought get_form returned an object

=head1 USAGE

=head2 C<-MCarp::REPL>

=head2 C<-MCarp::REPL=warn>

Works as command line argument. This automatically installs the die handler for
you, so if you receive a fatal error you get a REPL before the universe
explodes. Specifying C<=warn> also installs a warn handler for finding those
mysterious warnings.

=head2 C<use Carp::REPL;>

=head2 C<use Carp::REPL 'warn';>

Same as above.

=head2 C<use Carp::REPL 'nodie';>

Loads the module without installing the die handler. Use this if you just want
to run C<Carp::REPL::repl> on your own terms.

=head2 C<use Carp::REPL 'test';>

=head2 C<-MCarp::REPL=test>

Load a REPL on test failure! (as long as it uses L<Test::More/ok>)

=head1 FUNCTIONS

=head2 repl

This module's interface consists of exactly one function: repl. This is
provided so you may install your own C<$SIG{__DIE__}> handler if you have no
alternatives.

It takes the same arguments as die, and returns no useful value. In fact, don't
even depend on it returning at all!

One useful place for calling this manually is if you just want to check the
state of things without having to throw a fake error. You can also change any
variables and those changes will be seen by the rest of your program.

    use Carp::REPL 'repl';

    sub involved_calculation {
        # ...
        $d = maybe_zero();
        # ...
        repl(); # $d = 1
        $sum += $n / $d;
        # ...
    }

Unfortunately if you instead go with the usual C<-MCarp::REPL>, then
C<$SIG{__DIE__}> will be invoked and there's no general way to recover. But you
can still change variables to poke at things.

=head1 COMMANDS

Note that this is not supposed to be a full-fledged debugger. A few commands
are provided to aid you in finding out what went awry. See
L<Devel::ebug> if you're looking for a serious debugger.

=over 4

=item * :u

Moves one frame up in the stack.

=item * :d

Moves one frame down in the stack.

=item * :top

Moves to the top frame of the stack.

=item * :bottom

Moves to the bottom frame of the stack.

=item * :t

Redisplay the stack trace.

=item * :e

Display the current lexical environment.

=item * :l

List eleven lines of source code of the current frame.

=item * :q

Close the REPL. (C<^D> also works)

=back

=head1 VARIABLES

=over 4

=item * $_REPL

This represents the Devel::REPL object.

=item * $_a

This represents the arguments passed to the subroutine at the current frame in
the call stack. Modifications are ignored (how would that work anyway?
Re-invoke the sub?)

=back

=head1 CAVEATS

Dynamic scope probably produces unexpected results. I don't see any easy (or
even difficult!) solution to this. Therefore it's a caveat and not a bug. :)

=head1 SEE ALSO

L<Devel::REPL>, L<Devel::ebug>, L<Enbugger>, L<CGI::Inspect>

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-carp-repl at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Carp-REPL>.

=head1 ACKNOWLEDGEMENTS

Thanks to Nelson Elhage and Jesse Vincent for the idea.

Thanks to Matt Trout and Stevan Little for their advice.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2008 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

