#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;

use Object::Pad 0.41;

package App::sdview::Parser::Pod 0.01;
class App::sdview::Parser::Pod
   isa Pod::Simple
   does App::sdview::Parser;

use List::Keywords qw( any );
use List::Util qw( min );

use String::Tagged;

use constant format => "POD";

sub can_parse_file ( $class, $file )
{
   return $file =~ m/\.pm$|\.pl$|\.pod$/;
}

BUILD
{
   $self->nix_X_codes( 1 );
}

has @_parastack;

has %_curtags;
has $_curpara;

method parse_file ( $fh )
{
   push @_parastack, [];
   $self->SUPER::parse_file( $fh );
   return $_parastack[0]->@*;
}

method parse_string ( $str )
{
   push @_parastack, [];
   $self->SUPER::parse_string_document ( $str );
   return $_parastack[0]->@*;
}

my %PARA_TYPES = (
   Para     => "App::sdview::Para::Plain",
   Verbatim => "App::sdview::Para::Verbatim",
);
my @FORMAT_TYPES = qw( B I F C L );

method _handle_element_start ($type, $attrs)
{
   if( $type eq "Document" ) {
      %_curtags = ();
   }
   elsif( $type =~ m/^head(\d+)$/ ) {
      push $_parastack[-1]->@*, $_curpara = App::sdview::Para::Heading->new(
         level => $1,
         text  => String::Tagged->new,
      );
      %_curtags = ();
   }
   elsif( my $class = $PARA_TYPES{$type} ) {
      push $_parastack[-1]->@*, $_curpara = $class->new(
         text => String::Tagged->new,
      );
      %_curtags = ();
   }
   elsif( $type eq "L" ) {
      $_curtags{L} = { target => $attrs->{to} };
   }
   elsif( any { $type eq $_ } @FORMAT_TYPES ) {
      ++$_curtags{$type};
   }
   elsif( $type =~ m/^over-(.*)/ ) {
      push $_parastack[-1]->@*, App::sdview::Para::List->new(
         listtype => $1,
         indent   => $attrs->{indent},
      );
      push @_parastack, [];
      undef $_curpara;
   }
   elsif( $type =~ m/^item-(.*)/ ) {
      push @_parastack[-1]->@*, $_curpara = App::sdview::Para::ListItem->new(
         text => String::Tagged->new,
      );
   }
   else {
      print STDERR "START $_[0]\n";
   }
}

method _handle_element_end ($type, @)
{
   if( $type eq "Document" ) {
      # nothing
   }
   elsif( $type =~ m/^head\d+$/ ) {
      # nothing
   }
   elsif( $PARA_TYPES{$type} ) {
      $type eq "Verbatim" and
         $_parastack[-1][-1] = $self->trim_leading_whitespace( $_parastack[-1][-1] );
   }
   elsif( any { $type eq $_ } @FORMAT_TYPES ) {
      delete $_curtags{$type};
   }
   elsif( $type =~ m/^over-(.*)/ ) {
      my @items = ( pop @_parastack )->@*;
      $_parastack[-1][-1]->push_item( $_ ) for @items;
   }
   elsif( $type =~ m/^item-.*/ ) {
      # nothing
   }
   else {
      print STDERR "END $_[0]\n";
   }
}

method _handle_text
{
   $_curpara->text->append_tagged( $_[0], %_curtags );
}

method trim_leading_whitespace ( $para )
{
   my @lines = $para->text->split( qr/\n/ );

   my $trimlen = min map { m/^(\s*)/; $+[1] } grep { length } @lines;

   length and $_ = $_->substr( $trimlen, length $_ ) for @lines;

   my $text = shift @lines;
   $text .= "\n" . $_ for @lines;

   return (ref $para)->new(
      text => $text,
   );
}

0x55AA;
