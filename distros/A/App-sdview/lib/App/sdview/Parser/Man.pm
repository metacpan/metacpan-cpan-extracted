#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk

use v5.26;
use utf8;

use Object::Pad 0.66;

package App::sdview::Parser::Man 0.09;
class App::sdview::Parser::Man
   :does(App::sdview::Parser)
   :strict(params);

use Parse::Man::DOM 0.03;

use String::Tagged;

sub find_file ( $class, $name )
{
   open my $f, "-|", "man", "--path", $name;
   my $file = <$f>; chomp $file if defined $file;
   close $f;
   $? == 0 or return undef;
   return $file;
}

sub can_parse_file ( $class, $file )
{
   return $file =~ m/\.[0-9](pm)?(\.gz)?/n;
}

field @_paragraphs;

method parse_file ( $fh )
{
   return $self->_parse( Parse::Man::DOM->new->from_file( $fh ) );
}

method parse_string ( $str )
{
   return $self->_parse( Parse::Man::DOM->new->from_string( $str ) );
}

method _parse ( $dom )
{
   # Not much we can do with the meta sections

   @_paragraphs = ();

   foreach my $para ( $dom->paras ) {
      my $type = $para->type;
      if( my $code = $self->can( "_handle_$type" ) ) {
         $self->$code( $para );
      }
      else {
         print STDERR "TODO: para->type = $type\n";
      }
   }

   return @_paragraphs;
}

my %FONTTAGS = (
   B  => { B => 1 },
   I  => { I => 1 },
   CW => { C => 1 },
);

sub _chunklist_to_taggedstring ( $chunks, %opts )
{
   my $ret = String::Tagged->new;

   my $linefeed = $opts{linefeed} // " ";

   foreach my $chunk ( $chunks->@* ) {
      my %tags;

      my $font = $chunk->font // "";
      %tags = $FONTTAGS{$font}->%* if $FONTTAGS{$font};

      my $text = $chunk->text;
      $text = "\n"      if $chunk->is_space;
      $text = $linefeed if $chunk->is_linebreak;
      $text = "\n\n"    if $chunk->is_break;

      $ret->append_tagged( $text, %tags );
   }

   # Trim trailing space
   $ret =~ m/([ \n]+)$/ and
      $ret->set_substr( $-[1], $+[1]-$-[1], "" );

   return $ret;
}

method _handle_heading ( $para )
{
   push @_paragraphs, App::sdview::Para::Heading->new(
      level => $para->level, 
      text => String::Tagged->new( $para->text ),
   );
}

method _handle_plain ( $para )
{
   push @_paragraphs, App::sdview::Para::Plain->new(
      text => _chunklist_to_taggedstring( [ $para->body->chunks ] ),
      indent => $para->indent,
   );
}

method _handle_term ( $para )
{
   my $list;
   if( @_paragraphs and $_paragraphs[-1]->type eq "list-text" ) {
      $list = $_paragraphs[-1];
   }
   else {
      push @_paragraphs, $list = App::sdview::Para::List->new(
         listtype => "text",
         indent   => 4,
      );
   }

   $list->push_item(
      App::sdview::Para::ListItem->new(
         listtype => "text",
         term => _chunklist_to_taggedstring( [ $para->term->chunks ] ),
         text => _chunklist_to_taggedstring( [ $para->definition->chunks ] )
      )
   );
}

method _handle_example ( $para )
{
   push @_paragraphs, App::sdview::Para::Verbatim->new(
      text => _chunklist_to_taggedstring( [ $para->body->chunks ], linefeed => "\n" ),
   );
}

method _handle_indent ( $para )
{
   my $listtype = "(plain)";
   if( defined( my $marker = $para->marker ) ) {
      $listtype = "text";
      $listtype = "bullet" if $marker eq "•";
   }

   my $list;
   if( @_paragraphs and (
         ( $listtype eq "(plain)" ? $_paragraphs[-1]->type =~ m/^list-/
                                  : $_paragraphs[-1]->type eq "list-$listtype" ) ) ) {
      $list = $_paragraphs[-1];
   }
   else {
      push @_paragraphs, $list = App::sdview::Para::List->new(
         listtype => $listtype,
         indent   => $para->indent,
      );
   }

   if( $listtype eq "(plain)" ) {
      $list->push_item(
         App::sdview::Para::Plain->new(
            text => _chunklist_to_taggedstring( [ $para->body->chunks ] ),
            indent => $para->indent,
         )
      );
   }
   else {
      $list->push_item(
         App::sdview::Para::ListItem->new(
            listtype => $listtype,
            text     => _chunklist_to_taggedstring( [ $para->body->chunks ] ),
         )
      );
   }
}

0x55AA;
