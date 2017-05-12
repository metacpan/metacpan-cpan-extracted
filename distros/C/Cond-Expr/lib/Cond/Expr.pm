use strict;
use warnings;

package Cond::Expr; # git description: 0.04-25-gb42799c
# ABSTRACT: Conditionals as expressions

our $VERSION = '0.05';

use Sub::Exporter -setup => {
    exports => ['cond'],
    groups  => { default => ['cond'] },
};

use Devel::CallParser;
use Devel::CallChecker;

use XSLoader;

XSLoader::load(
    __PACKAGE__,
    $VERSION,
);

#pod =head1 SYNOPSIS
#pod
#pod     my %args = (
#pod         foo => 'bar',
#pod         (cond
#pod             ($answer == 42) { answer => $answer }
#pod             ($answer)       { wrong_answer => 1 }
#pod             otherwise       { no_answer    => 1 }
#pod         ),
#pod     );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module implements a Lisp-alike C<cond> control structure.
#pod
#pod =head2 How is this different from…
#pod
#pod =over 4
#pod
#pod =item * C<given>/C<when>
#pod
#pod C<given> is a statement, not an expression, and is therefore not readily usable
#pod as part of an expression unless its use is wrapped within a C<do> block, which
#pod is cumbersome.
#pod
#pod Additionally, this module avoids all the, possibly unwanted, side effects
#pod C<given>/C<when> and its underlying smart matching mechanism happen to impose.
#pod
#pod =item * C<if>/C<elsif>/C<else>
#pod
#pod Similar to C<given>, C<if> is a statement, needing special care in order to be
#pod useful as part of a surrounding expression.
#pod
#pod =item * Nested ternary C<?:>
#pod
#pod Using nested ternary C<?:> expressions, such as in
#pod
#pod   my %args = (
#pod       foo => 'bar',
#pod       (
#pod             ($answer == 42) ? (answer => $answer)
#pod           : ($answer)       ? (wrong_answer => 1)
#pod           :                   (no_answer => 1)
#pod       ),
#pod   );
#pod
#pod can be used to achieve functionality similar to what this module provides. In
#pod fact, the above use of C<?:> is exactly what the L</SYNOPSIS> for this module
#pod will compile into. The main difference is the C<cond> syntax provided by this
#pod module being easier on the eye.
#pod
#pod =back
#pod
#pod =func C<cond>
#pod
#pod Takes a set of test/expression pairs. It evaluates each test one at a time. If a test
#pod returns logical true, C<cond> evaluates and returns the value of the corresponding
#pod expression and doesn't evaluate any of the other tests or expressions. When none of the
#pod provided tests yield a true value, C<()> or C<undef> is returned in list and
#pod scalar context, respectively.
#pod
#pod =head1 PERL REQUIREMENTS
#pod
#pod Due to the particular XS interfaces being used, this module requires a minimum
#pod Perl version of 5.014.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cond::Expr - Conditionals as expressions

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    my %args = (
        foo => 'bar',
        (cond
            ($answer == 42) { answer => $answer }
            ($answer)       { wrong_answer => 1 }
            otherwise       { no_answer    => 1 }
        ),
    );

=head1 DESCRIPTION

This module implements a Lisp-alike C<cond> control structure.

=head2 How is this different from…

=over 4

=item * C<given>/C<when>

C<given> is a statement, not an expression, and is therefore not readily usable
as part of an expression unless its use is wrapped within a C<do> block, which
is cumbersome.

Additionally, this module avoids all the, possibly unwanted, side effects
C<given>/C<when> and its underlying smart matching mechanism happen to impose.

=item * C<if>/C<elsif>/C<else>

Similar to C<given>, C<if> is a statement, needing special care in order to be
useful as part of a surrounding expression.

=item * Nested ternary C<?:>

Using nested ternary C<?:> expressions, such as in

  my %args = (
      foo => 'bar',
      (
            ($answer == 42) ? (answer => $answer)
          : ($answer)       ? (wrong_answer => 1)
          :                   (no_answer => 1)
      ),
  );

can be used to achieve functionality similar to what this module provides. In
fact, the above use of C<?:> is exactly what the L</SYNOPSIS> for this module
will compile into. The main difference is the C<cond> syntax provided by this
module being easier on the eye.

=back

=head1 FUNCTIONS

=head2 C<cond>

Takes a set of test/expression pairs. It evaluates each test one at a time. If a test
returns logical true, C<cond> evaluates and returns the value of the corresponding
expression and doesn't evaluate any of the other tests or expressions. When none of the
provided tests yield a true value, C<()> or C<undef> is returned in list and
scalar context, respectively.

=head1 PERL REQUIREMENTS

Due to the particular XS interfaces being used, this module requires a minimum
Perl version of 5.014.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Cond-Expr>
(or L<bug-Cond-Expr@rt.cpan.org|mailto:bug-Cond-Expr@rt.cpan.org>).

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge David Mitchell Olivier Mengué Sawyer X

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

David Mitchell <davem@iabyn.com>

=item *

Olivier Mengué <dolmen@cpan.org>

=item *

Sawyer X <xsawyerx@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
