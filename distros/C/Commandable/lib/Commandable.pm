#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2023 -- leonerd@leonerd.org.uk

package Commandable 0.11;

use v5.14;
use warnings;

=head1 NAME

C<Commandable> - utilities for commandline-based programs

=head1 DESCRIPTION

This distribution contains a collection of utilities extracted from various
commandline-based programs I have written, in the hope of trying to find a
standard base to build these from in future.

Note that "commandline" does not necessarily mean "plain-text running in a
terminal"; simply that the mode of operation is that the user types a textual
representation of some action, and the program parses this text in order to
perform it. This could equally apply to a command input text area in a GUI
program.

=head1 PROGRAM STRUCTURE

A typical program using this distribution would have a single instance of a
"finder", whose job is to work out the set of commands offered by the program.
Various subclasses of finder are provided that use different techniques to
locate the individual commands, depending on the structure provided by the
program.

=over 4

=item *

L<Commandable::Finder::SubAttributes> - expects to find each command
implemented as a subroutine within a single package. These subroutines should
all have attributes that provide description text, and specifications of
argument and option parsing. The code body of the subroutine is then used to
implement the actual command.

=item *

L<Commandable::Finder::MethodAttributes> - a variant of the above which
expects that commands are implemented as methods on an object instance.

=item *

L<Commandable::Finder::Packages> - expects to find each command implemented
as an entire package, with (constant) subroutines to give the description text
and argument and option parsing specifications. Another subroutine within the
package actually implements the command.

=back

As the user requests that commands be executed, the text of each request is
then wrapped in an instance of L<Commandable::Invocation>. This is then passed
to the finder instance to actually invoke a command by parsing its name,
options and arguments, and run the actual code body.

   my $finder = Commandable::Finder::...->new( ... );

   my $cinv = Commandable::Invocation->new( $text );

   $finder->find_and_invoke( $cinv );

The finder instance is not modified by individual invocations, and can be
reused if the program wishes to provide some sort of multiple invocation
ability; perhaps in the form of a REPL-like shell:

   my $finder = ...

   while( my $text = <STDIN> ) {
      $finder->find_and_invoke( Commandable::Invocation->new( $text ) );
   }

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
