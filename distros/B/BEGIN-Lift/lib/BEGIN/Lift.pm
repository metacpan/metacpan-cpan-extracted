package BEGIN::Lift;
# ABSTRACT: Lift subroutine calls into the BEGIN phase

use strict;
use warnings;

our $VERSION;
our $AUTHORITY;

use Sub::Name              ();
use B::CompilerPhase::Hook ();

use Devel::CallParser;
use XSLoader;
BEGIN {
    $VERSION   = '0.06';
    $AUTHORITY = 'cpan:STEVAN';
    XSLoader::load( __PACKAGE__, $VERSION );
}

sub install {
    my ($pkg, $method, $handler) = @_;

    # need to force a new CV each time here
    # not entirely sure why, but I assume
    # that perl was trying to optimize things
    # which is not what I actually want.
    my $cv = eval 'sub {}';

    # now we need to install the stub
    # we just created, but first we need to
    # verify that we are the only ones using
    # the typeglob we are installing into.
    # This makes it easier/safer to delete
    # the stub before runtime.
    {
        no strict 'refs';
        die "Cannot install the lifted keyword ($method) into package ($pkg) when that typeglob (\*${pkg}::${method}) already exists"
            if exists ${"${pkg}::"}{$method};
        *{"${pkg}::${method}"} = $cv;
    }

    # give the handler a name so that
    # it shows up sensibly in stack
    # traces and the like ...
    Sub::Name::subname( "${pkg}::${method}", $handler );

    # install the keyword handler ...
    BEGIN::Lift::Util::install_keyword_handler(
        $cv, sub { $handler->( $_[0] ? $_[0]->() : () ) }
    );

    # clean things up ...
    B::CompilerPhase::Hook::enqueue_UNITCHECK {
        no strict 'refs';
        # NOTE:
        # this is safe only because we
        # confirmed above that there was
        # no other use of this typeglob
        # and so it is ok to delete
        delete ${"${pkg}::"}{$method}
    };
}

1;

__END__

=pod

=head1 NAME

BEGIN::Lift - Lift subroutine calls into the BEGIN phase

=head1 SYNOPSIS

  package Cariboo;
  use strict;
  use warnings;

  use BEGIN::Lift;

  sub import {
      my $caller = caller;

      BEGIN::Lift::install(
          ($caller, 'extends') => sub {
              no strict 'refs';
              @{$caller . '::ISA'} = @_;
          }
      );
  }

  package Foo;
  use Cariboo;

  extends 'Bar';

  # functionally equivalent to ...
  # BEGIN { @ISA = ('Bar') }

=head1 DESCRIPTION

This module serves a very specific purpose, which is to provide a
mechanism through which we can "lift" a given subroutine to be
executed entirely within the C<BEGIN> phase of the Perl compiler
and to leave no trace of itself in the C<RUN> phase.

=head2 Modules loaded at runtime?

If a package that uses this module is loaded at runtime (perhaps
via the C<require> builtin), it will still work correctly (to the
best of my knowledge that is).

=head1 FUNCTIONS

=head2 C<install( $package, $keyword_name, $keyword_handler )>

This will install a lifted subroutine named C<$keyword_name> into
the specified C<$package>. All calls to this the lifted subroutine
will execute the C<$keyword_handler> immediately after parsing it.

If this subroutine is called outside of the C<BEGIN> phase, an error
will be thrown. If there already exists a typeglob for C<$keyword_name>
then an error will be thrown.

=head1 CAVEATS

=head2 All arguments to lifted subroutines must be C<BEGIN> time safe

This means they require no runtime initiatlization or access to
runtime initialized variables (as they won't be initialized).

For instance, given a lifted subroutine called C<add>, this code is
C<BEGIN> time safe because the arguments are numeric literals.

  add( 1, 1 );

While this version is not safe because it relies on the C<@args>
variable being initialized at runtime.

  my @args = (1, 1);
  add( @args );

=head1 PARSING ISSUES

Ideally we can (eventually) detect these situations and error
accordingly so that this is no longer a burden to the user of this
module, but instead just part of the normal operation of it.

=head2 Non-void context

If, for instance, a lifted sub is called such that the return value
is to be assigned to a variable, such as:

  my $x = my_lifted_sub();

It will not behave as expected, since C<my_lifted_sub> is evaluated
entirely at C<BEGIN> time, the resulting value for C<$x> at C<RUN>
time is C<undef>.

=head2 Expression context

If, for instance, a lifted sub is called within an expression where
the return value is important, such as:

  if ( my_lifted_sub() && 10 ) { ... }

It will not behave as expected, since C<my_lifted_sub> is evaluated
entirely at C<BEGIN> time and has the value of C<undef> at runtime,
the conditional will always fail.

=head2 Statement modifier context

If, for instance, a lifted sub call is guarded by a statement modifier,
such as:

  my_lifted_sub() if 0;

It will not behave as expected, since the lifted sub call is evaluated
entirely at C<BEGIN> time the statement modifier has no affect at all
and <my_lifted_sub> will always be executed.

=head1 SEE ALSO

=over 4

=item L<Devel::BeginLift>

This does a similar thing, but does it via "some slightly insane perlguts magic",
while this module has much the same goals, it will (hopefully) accomplish it with
less insanity.

=back

=head1 AUTHOR

Stevan Little <stevan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Stevan Little.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


