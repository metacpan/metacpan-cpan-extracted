#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Commandable::Output 0.11;

use v5.14;
use warnings;

use constant HAVE_STRING_TAGGED => defined eval {
   require String::Tagged;
   require Convert::Color;
};

use constant HAVE_STRING_TAGGED_TERMINAL => defined eval {
   require String::Tagged::Terminal;
};

=head1 NAME

C<Commandable::Output> - abstractions for printing output from commands

=head1 DESCRIPTION

This package contains default implementations of methods for providing printed
output from commands implemented using L<Commandable>. These methods are
provided for the convenience of user code, and are also used by built-in
commands provided by the C<Commandable> system itself.

Implementations are permitted (encouraged, even) to replace any of these
methods in order to customise their behaviour. 

=head2 WITH C<String::Tagged>

If L<String::Tagged> and L<Convert::Color> are available, this module applies
formatting to strings by using the L<String::Tagged::Formatting> conventions.
The C<format_heading> and C<format_note> methods will return results as
instances of C<String::Tagged>, suitable to pass into the main C<printf>
method.

=cut

=head1 METHODS

=cut

sub _format_string
{
   my $self = shift;
   my ( $text, $tagmethod ) = @_;

   return $text unless HAVE_STRING_TAGGED;

   my %tags;
   %tags = $self->$tagmethod if $self->can( $tagmethod );

   if( $tags{fg} and !ref $tags{fg} ) {
      $tags{fg} = Convert::Color->new( $tags{fg} );
   }

   return String::Tagged->new_tagged( $text, %tags );
}

=head2 printf

   Commandable::Output->printf( $format, @args )

The main output method, used to send messages for display to the user. The
arguments are formatted into a single string by Perl's C<printf> function.
This method does not append a linefeed. To output a complete line of text,
remember to include the C<"\n"> at the end of the format string.

The default implementation writes output on the terminal via STDOUT.

In cases where the output should be sent to some other place (perhaps a GUI
display widget of some kind), the application should replace this method with
something that writes the display to somewhere more appropriate. Don't forget
to use C<sprintf> to format the arguments into a string.

   no warnings 'redefine';
   sub Commandable::Output::printf
   {
      shift; # the package name
      my ( $format, @args ) = @_;

      my $str = sprintf $format, @args;

      $gui_display_widget->append_text( $str );
   }

If L<String::Tagged::Terminal> is available, the output will be printed using
this module, by first converting the format string and arguments using
L<String::Tagged/from_sprintf> and then constructing a terminal string using
L<String::Tagged::Terminal/new_from_formatting>. This means the default
implementation will be able to output formatted strings using the
L<String::Tagged::Formatting> conventions.

=cut

sub printf
{
   shift;
   my ( $format, @args ) = @_;

   if( HAVE_STRING_TAGGED_TERMINAL ) {
      String::Tagged::Terminal->new_from_formatting(
         String::Tagged->from_sprintf( $format, @args )
      )->print_to_terminal;
      return;
   }

   printf $format, @args;
}

=head2 print_heading

   Commandable::Output->print_heading( $text, $level )

Used to send output that should be considered like a section heading.
I<$level> may be an integer used to express sub-levels; increasing values from
1 upwards indicate increasing sub-levels.

The default implementation formats the text string using L</format_heading>
then prints it using L</printf> with a trailing linefeed.

=cut

sub print_heading
{
   my $self = shift;
   my ( $text, $level ) = @_;

   $self->printf( "%s\n", $self->format_heading( $text, $level ) );
}

=head2 format_heading

   $str = Commandable::Output->format_heading( $text, $level )

Returns a value for printing, to represent a section heading for the given
text and level.

The default implementation applies the following formatting if
C<String::Tagged> is available:

=over 4

=item Level 1

Underlined

=item Level 2

Underlined, cyan colour

=item Level 3

Bold

=back

=cut

use constant TAGS_FOR_HEADING_1 => ( under => 1 );
use constant TAGS_FOR_HEADING_2 => ( under => 1, fg => "vga:cyan", );
use constant TAGS_FOR_HEADING_3 => ( bold => 1 );

sub format_heading
{
   my $self = shift;
   my ( $text, $level ) = @_;

   $level //= 1;

   return $self->_format_string( $text, "TAGS_FOR_HEADING_$level" );
}

=head2 format_note

   $str = Commandable::Output->format_note( $text, $level )

Returns a value for printing, to somehow highlight the given text (which
should be a short word or string) at the given level.

The default implementation applies the following formatting if
C<String::Tagged> is available:

=over 4

=item Level 0

Bold, yellow colour

=item Level 1

Bold, cyan colour

=item Level 2

Bold, magenta colour

=back

=cut

use constant TAGS_FOR_NOTE_0 => ( bold => 1, fg => "vga:yellow" );
use constant TAGS_FOR_NOTE_1 => ( bold => 1, fg => "vga:cyan" );
use constant TAGS_FOR_NOTE_2 => ( bold => 1, fg => "vga:magenta" );

sub format_note
{
   my $self = shift;
   my ( $text, $level ) = @_;

   $level //= 0;

   return $self->_format_string( $text, "TAGS_FOR_NOTE_$level" );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
