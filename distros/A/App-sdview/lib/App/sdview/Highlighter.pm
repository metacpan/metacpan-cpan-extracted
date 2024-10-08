#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use experimental 'signatures';

package App::sdview::Highlighter 0.19;

use constant HAVE_TEXT_TREESITTER => defined eval {
   require Text::Treesitter;
   require Text::Treesitter::QueryCursor;
   require Text::Treesitter::QueryMatch;
};

use Convert::Color;
use Convert::Color::XTerm;

# chunks of this code copypasted from Text-Treesitter/examples/highlight.pl

my %TS_FOR_LANGUAGE;
my %HIGHLIGHTS_FOR_LANGUAGE;

sub highlight_str ( $cls, $str, $language, %opts )
{
   return unless HAVE_TEXT_TREESITTER;
   return if $language eq "text";

   my $ts = $TS_FOR_LANGUAGE{ $language } //= eval {
      Text::Treesitter->new(
         lang_name => $language,
         #lang_dir  => $LANGUAGE_DIR,
      )
   };
   defined $ts or return;

   my $query_highlight = $HIGHLIGHTS_FOR_LANGUAGE{ $language } //= eval {
      $ts->load_query_file( "highlights.scm" )
   };
   unless( defined $query_highlight ) {
      my $e = $@;
      warn "Unable to load $language highlights: $e\n";
      return;
   }

   # TODO: handle injections

   my $tree;
   if( defined $opts{start_byte} ) {
      $tree = $ts->parse_string_range( $str, %opts{qw( start_byte end_byte )} );
   }
   else {
      $tree = $ts->parse_string( $str );
   }
   my $root = $tree->root_node;

   my $qc = Text::Treesitter::QueryCursor->new;

   $qc->exec( $query_highlight, $root );

   while( my $captures = $qc->next_match_captures ) {
      CAPTURE: foreach my $capturename ( sort keys $captures->%* ) {
         # TODO: actually implement the priority logic
         next if $capturename eq "priority";

         my $node = $captures->{$capturename};

         my $start = $tree->byte_to_char( $node->start_byte );
         my $len   = $tree->byte_to_char( $node->end_byte ) - $start;

         my $format = App::sdview::Style->highlight_style( $capturename )
            or next;

         $str->apply_tag( $start, $len, $_, $format->{$_} ) for keys %$format;
      }
   }
}

0x55AA;
