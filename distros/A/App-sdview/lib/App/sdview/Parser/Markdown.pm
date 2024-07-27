#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;

use Object::Pad 0.807;

package App::sdview::Parser::Markdown 0.17;
class App::sdview::Parser::Markdown :strict(params);

apply App::sdview::Parser;

use File::Slurper 'read_text';

use String::Tagged::Markdown 0.05;

use constant format => "Markdown";
use constant sort_order => 20;

=head1 NAME

C<App::sdview::Parser::Markdown> - parse Markdown files for L<App::sdview>

=head1 SYNOPSIS

   $ sdview README.md

   $ sdview -f Markdown my-document

=head1 DESCRIPTION

This parser module adds to L<App::sdview> the ability to parse input text in
Markdown formatting.

It uses a custom in-built parser for the block-level parts of the formatting,
able to handle comments, verbatim blocks, headings in both C<#>-prefixed and
C<=>-underlined styles, bullet and numbered lists, and tables.

It uses L<String::Tagged::Markdown> to parse the inline-level formatting,
supporting bold, italic, strikethrough, and fixed-width styles, and links.

=cut

sub find_file ( $class, $name ) { return undef }

sub can_parse_file ( $class, $file )
{
   return $file =~ m/\.(?:md|markdown)$/;
}

method parse_file ( $fh )
{
   return $self->parse_string( read_text $fh );
}

field @_paragraphs;

sub _split_table_row ( $str )
{
   $str =~ m/^\s*\|/ or return undef;
   $str =~ m/\|\s*$/ or return undef;

   my @cols = split m/\|/, $str, -1;
   shift @cols; pop @cols;

   s/^\s+//, s/\s+$// for @cols;

   return \@cols;
}

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
         my $language = $line =~ s/^\s+|\s+$//gr;
         push @_paragraphs, App::sdview::Para::Verbatim->new(
            language => ( length $language ? $language : undef ),
            text     => String::Tagged->new,
         );
         $in_verb++;
         next;
      }

      if( length $line ) {
         push @lines, $line;
         next;
      }

      while( @lines ) {
         if( $lines[0] =~ m/^<!--/ ) { # comment
            ;
         }
         elsif( $lines[0] =~ m/^    / ) { # verbatim
            my $raw = join "\n", @lines;
            $raw =~ s/^    //mg;

            push @_paragraphs, App::sdview::Para::Verbatim->new(
               text => String::Tagged->new( $raw ),
            );
         }
         elsif( $lines[0] =~ s/^(#+)\s+// ) { # heading
            my $level = length $1;
            push @_paragraphs, App::sdview::Para::Heading->new(
               level => $level,
               text  => $self->_handle_spans( shift @lines ),
            );

            next;
         }
         elsif( @lines >= 2 and $lines[1] =~ m/^([=-])\1*$/ ) { # heading
            my $level = ( $1 eq "=" ) ? 1 : 2;
            push @_paragraphs, App::sdview::Para::Heading->new(
               level => $level,
               text  => $self->_handle_spans( shift @lines ),
            );

            shift @lines;

            next;
         }
         elsif( $lines[0] =~ s/^[*+-]\s+// ) { # bullet list
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
                  listtype => "bullet",
                  text => $self->_handle_spans( $raw )
            ) );

            next;
         }
         elsif( $lines[0] =~ s/^(\d+)([\.\)])\s+// ) { # numbered list
            # parens aren't strictly Markdown format, but we'll accept them
            # anyway because so many other parsers do, and people use them
            my ( $num, $sep ) = ( $1, $2 );
            my $raw = shift @lines;
            while( @lines and $lines[0] !~ m/^\d+\Q$sep/ ) {
               $raw .= " " . ( shift(@lines) =~ m/^\s*(.*)$/ )[0];
            }

            my $list;
            if( @_paragraphs and $_paragraphs[-1]->type eq "list-number" ) {
               $list = $_paragraphs[-1];
            }
            else {
               push @_paragraphs, $list = App::sdview::Para::List->new(
                  listtype => "number",
                  indent   => 4,
                  initial  => $num,
               );
            }

            $list->push_item( App::sdview::Para::ListItem->new(
                  listtype => "number",
                  text => $self->_handle_spans( $raw )
            ) );

            next;
         }
         elsif( @lines >= 2 and 
               my $cells = _split_table_row( $lines[0] ) and
               my $aligns = _split_table_row( $lines[1] ) ) { # table
            shift @lines;

            my @colalign = map {
               m/^(:?)-{3,}(:?)$/ or warn "Unexpected table heading separator text: $_\n";
               ( $1 and $2 ) ? "centre" :
               ( $2        ) ? "right" :
                               "left";
            } @$aligns;

            my @rows;

            do {
               shift @lines;

               push @rows, [ map {
                  my $s = $cells->[$_];
                  App::sdview::Para::TableCell->new(
                     align => $colalign[$_],
                     text => $self->_handle_spans( $cells->[$_] ),
                  );
               } 0 .. $#colalign ];
            } while( @lines and $cells = _split_table_row( $lines[0] ) );

            push @_paragraphs, my $p = App::sdview::Para::Table->new( rows => \@rows );
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
   return String::Tagged::Markdown->parse_markdown( $s )
      ->clone(
         convert_tags => {
            # bold, italic stay as they are
            fixed  => "monospace",
            strike => "strikethrough",
            link   => sub ($t, $v) { return link => { uri => $v } },
         },
         only_tags => [qw( bold italic fixed strike link )],
      );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
