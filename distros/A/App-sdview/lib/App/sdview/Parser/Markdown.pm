#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;

use Object::Pad 0.41;

package App::sdview::Parser::Markdown 0.01;
class App::sdview::Parser::Markdown
   does App::sdview::Parser;

use File::Slurper 'read_text';

use constant format => "Markdown";

sub can_parse_file ( $class, $file )
{
   return $file =~ m/\.md$/;
}

method parse_file ( $fh )
{
   return $self->parse_string( read_text $fh );
}

has @_paragraphs;

method parse_string ( $str )
{
   my $in_verb;

   my @lines;

   foreach ( split( m/\n/, $str ), "" ) {
      my $line = $_; # So we have a copy, because foreach my ... will alias the readonly ""

      if( $in_verb ) {
         my $para = $_paragraphs[-1];

         if( $line =~ m/^\`\`\`/ ) {
            undef $in_verb;
            next
         }

         length $para->text and
            $para->text->append( "\n" );

         $para->text->append( $line );
         next;
      }

      if( $line =~ s/^\`\`\`// ) {
         # Ignore the type specifier for now
         push @_paragraphs, App::sdview::Para::Verbatim->new(
            text => String::Tagged->new,
         );
         $in_verb++;
         next;
      }

      if( length $line ) {
         push @lines, $line;
         next;
      }

      while( @lines ) {
         if( $lines[0] =~ m/^    / ) {
            my $raw = join "\n", @lines;
            $raw =~ s/^    //mg;

            push @_paragraphs, App::sdview::Para::Verbatim->new(
               text => String::Tagged->new( $raw ),
            );
         }
         elsif( $lines[0] =~ s/^(#+)\s+// ) {
            my $level = length $1;
            push @_paragraphs, App::sdview::Para::Heading->new(
               level => $level,
               text  => $self->_handle_spans( shift @lines ),
            );

            next;
         }
         elsif( @lines >= 2 and $lines[1] =~ m/^([=-])\1*$/ ) {
            my $level = ( $1 eq "=" ) ? 1 : 2;
            push @_paragraphs, App::sdview::Para::Heading->new(
               level => $level,
               text  => $self->_handle_spans( shift @lines ),
            );

            shift @lines;

            next;
         }
         elsif( $lines[0] =~ s/^[*+-]\s+// ) {
            my $raw = shift @lines;
            while( @lines and $lines[0] !~ m/^[*+-]/ ) {
               $raw .= " " . ( shift(@lines) =~ m/^\s*(.*)$/ )[0];
            }

            my $list;
            if( @_paragraphs and $_paragraphs[-1]->type eq "list-bullet" ) {
               $list = $_paragraphs[-1];
            }
            else {
               push @_paragraphs, $list = App::sdview::Para::List->new(
                  listtype => "bullet",
                  indent   => 4,
               );
            }

            $list->push_item( App::sdview::Para::ListItem->new(
                  text => $self->_handle_spans( $raw )
            ) );

            next;
         }
         else {
            push @_paragraphs, App::sdview::Para::Plain->new(
               text => $self->_handle_spans( join " ", @lines ),
            );
         }

         @lines = ();
      }
   }

   return @_paragraphs;
}

method _handle_spans ( $s )
{
   my $ret = String::Tagged->new;

   my %tags;

   while( pos $s < length $s ) {
      if( $s =~ m/\G\\(.)/gc ) {
         $ret->append_tagged( $1, %tags );
      }
      elsif( $s =~ m/\G`/gc ) {
         # Pull the contents ourselves so as to disarm the meaning of other
         # chars, especially * and _, inside the code
         $s =~ m/\G(.*?)`/gc;
         $ret->append_tagged( $1, C => 1 );
      }
      elsif( $s =~ m/\G(([*_])\2?)/gc ) {
         my $tag = ( length $1 > 1 ) ? "B" : "I";
         $tags{$tag} ? delete $tags{$tag} : $tags{$tag}++;
      }
      elsif( $s =~ m/\G\[(.*?)\]/gc ) {
         my $label = $1;
         $s =~ m/\((.*?)\)/gc; my $target = $1;

         $ret->append_tagged( $label, L => { target => $target }, %tags );
      }
      elsif( $s =~ m/\G([^`\\*_[]+)/gc ) {
         $ret->append_tagged( $1, %tags );
      }
   }

   return $ret;
}

0x55AA;
