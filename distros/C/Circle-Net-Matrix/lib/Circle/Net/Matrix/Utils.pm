#  You may distribute under the terms of the GNU General Public License
#
#  (C) Paul Evans, 2017 -- leonerd@leonerd.org.uk

package Circle::Net::Matrix::Utils;

use strict;
use warnings;

our $VERSION = '0.03';

use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(
   parse_markdownlike
);

use String::Tagged;

my %DEFAULT_PATTERNS = (
   '*'  => 'italic',
   '**' => 'bold',
   '`'  => 'monospace',
);

=head1 FUNCTIONS

=cut

=head2 parse_markdownlike

   $st = parse_markdownlike( $str )

Attempts to parse some markdown-like formatting tags from the input C<$str>,
returning a L<String::Tagged::Formatting> instance representing it.
In particular, the following markup is recognised

   *italic*
   **bold**
   `monospace`

This parser does not attempt to be a complete, nor a fully-compatible Markdown
parser, but simply tries to provide a useful function for entering formatted
messages.

=cut

sub parse_markdownlike
{
   my ( $str, $patterns ) = @_;

   $patterns //= \%DEFAULT_PATTERNS;
   keys %$patterns or croak "Cannot parse_markdownlike with no marker patterns";

   my %tags = ();

   my $match_marker = join "|", map { quotemeta }
                                sort { length $b <=> length $a } # longest first so ** wins over *
                                keys %$patterns;
   $match_marker = qr/$match_marker/;

   my $ret = String::Tagged->new;

   while( length $str ) {
      if( $str =~ m/(\w?)($match_marker)(\w?)/ ) {
         my $word_before = length $1;
         my $marker      = $2;
         my $markstart   = $-[2];
         my $markend     = $+[2];
         my $word_after  = length $3;

         # prefix before marker
         $ret->append_tagged( substr( $str, 0, $markstart ), %tags ) if $markstart > 0;

         if( $word_after and !$word_before ) {
            $tags{ $patterns->{$marker} } = 1;
         }
         elsif( $word_before and !$word_after ) {
            delete $tags{ $patterns->{$marker} };
         }
         else {
            # This isn't actually a tag start/stop so ignore it and continue
            $ret->append_tagged( substr( $str, $markstart, $markend - $markstart ), %tags );
         }

         substr( $str, 0, $markend ) = "";
      }
      else {
         $ret->append_tagged( $str, %tags );
         last;
      }
   }

   return $ret if $ret->tagnames;
   return $ret->str;
}

0x55AA;
