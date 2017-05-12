package Carp::Reply;
BEGIN {
  $Carp::Reply::AUTHORITY = 'cpan:DOY';
}
{
  $Carp::Reply::VERSION = '0.08';
}
use strict;
use warnings;
# ABSTRACT: get a repl on exceptions in your program

use Reply 0.27;
use Reply::Config;


sub import {
    my $package = shift;

    $SIG{__DIE__} = sub { print $_[0]; repl() };
}


sub repl {
    my ($quiet) = @_;
    my $repl = Reply->new(
        config  => Reply::Config->new,
        plugins => ['CarpReply']
    );
    $repl->step('#bt') unless $quiet;
    $repl->run;
}


1;

__END__

=pod

=head1 NAME

Carp::Reply - get a repl on exceptions in your program

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  perl -MCarp::Reply script.pl

or

  use Carp::Reply ();

  sub foo {
      # ...
      Carp::Reply::repl();
      # ...
  }

=head1 DESCRIPTION

Carp::Reply provides a repl to use within an already running program, which can
introspect the current state of the program, including the call stack and
current lexical variables. It works just like L<Reply>, with the addition of
some commands to move around in the call stack.

The package and lexical environment are set to the package and lexical
environment of the current stack frame (and are updated when you use any of the
commands which move around the stack frames). The lexical variables are aliased
to the variable in the stack frame, so if the repl is invoked manually (not
through a C<__DIE__> handler), you can actually modify the contents of lexical
variables to use when the repl closes and the app starts running again.

You can start a repl at any given point in your program by inserting a call to
C<Carp::Reply::repl> in your code. In addition, the default C<import> method
for C<Carp::Reply> installs a C<__DIE__> handler which automatically launches a
repl when an exception is thrown. You can suppress this behavior by passing an
empty import list, either via C<use Carp::Reply ();> or C<perl -mCarp::Reply>.

If the repl was invoked manually (via calling C<repl>), you can resume
execution of your code by exiting the repl, typically via C<Ctrl+D>. If it was
invoked via the C<__DIE__> handler, there is no way to resume execution (this
is a limitation of perl itself).

=head1 FUNCTIONS

=head2 repl

Invokes a repl at the current point of execution.

=head1 COMMANDS

=over 4

=item #backtrace

(Aliases: #trace, #bt)

Displays a backtrace from the location where the repl was invoked. This is run
automatically when the repl is first launched.

=item #top

(Aliases: #t)

Move to the top of the call stack (the outermost call level).

=item #bottom

(Aliases: #b)

Move to the bottom of the call stack (where the repl was invoked).

=item #up

(Aliases: #u)

Move up one level in the call stack.

=item #down

(Aliases: #d)

Move down one level in the call stack.

=item #list

(Aliases: #l)

Displays a section of the source code around the current stack frame. The
current line is marked with a C<*>.

=item #env

Displays the current lexical environment.

=back

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/doy/carp-reply/issues>.

=head1 SEE ALSO

L<Carp::REPL>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Carp::Reply

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Carp-Reply>

=item * Github

L<https://github.com/doy/carp-reply>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Carp-Reply>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Carp-Reply>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
