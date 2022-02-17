#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;
use utf8;

use Object::Pad;

package App::sdview 0.06;
class App::sdview :strict(params);

use List::Keywords qw( first );

=head1 NAME

C<App::sdview> - a terminal document viewer for POD and other syntaxes

=head1 SYNOPSIS

   use App::sdview;

   exit App::sdview->new->run( "some-file.pod" );

=head1 DESCRIPTION

This module implements a terminal-based program for viewing structured
documents. It currently understands POD and some simple Markdown formatting,
though future versions are expected to handle nroff (for manpages) and other
styles.

To actually use it, you likely wanted wanted to see the F<bin/sdview> script.

=cut

my @PARSER_CLASSES = qw(
   App::sdview::Parser::Pod
   App::sdview::Parser::Markdown
   App::sdview::Parser::Man
);

require ( "$_.pm" =~ s{::}{/}gr ) for @PARSER_CLASSES;

my @OUTPUT_CLASSES = qw(
   App::sdview::Output::Terminal
   App::sdview::Output::Plain
   App::sdview::Output::Pod
   App::sdview::Output::Markdown
   App::sdview::Output::Man
);

require ( "$_.pm" =~ s{::}{/}gr ) for @OUTPUT_CLASSES;

method run ( $file, %opts )
{
   my $parser_class;

   if( defined $opts{format} ) {
      $parser_class = first { $_->format eq $opts{format} } @PARSER_CLASSES or
         die "Unrecognised format name $opts{format}\n";
   }

   if( ! -f $file ) {
      my $name = $file;

      foreach my $class ( $parser_class ? ( $parser_class ) : @PARSER_CLASSES ) {
         defined( $file = $class->find_file( $name ) ) and
            $parser_class = $class, last;
      }

      defined $file or
         die "Unable to find a file for '$name'\n";
   }

   $parser_class //= do {
      first { $_->can_parse_file( $file ) } @PARSER_CLASSES or
         die "Unable to find a handler for $file\n";
   };

   $opts{output} //= "terminal";

   my $output_class = first { $_->format eq $opts{output} } @OUTPUT_CLASSES or
      die "Unrecognised output name $opts{output}\n";

   my @paragraphs = $parser_class->new->parse_file( $file );

   $output_class->new->output( @paragraphs );
}

=head1 TODO

=over 4

=item *

Add more formats. ReST perhaps. Maybe others too.

=item *

Improved Markdown parser. Currently the parser is very simple.

=item *

Other outputs. Consider a L<Tickit>-based frontend.

Also more structured file writers - ReST and maybe also HTML output.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
