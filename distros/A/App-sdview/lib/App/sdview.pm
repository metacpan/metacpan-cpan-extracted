#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use utf8;

use Object::Pad 0.800;

package App::sdview 0.15;
class App::sdview :strict(params);

use App::sdview::Style;

use List::Keywords qw( first );

=head1 NAME

C<App::sdview> - a terminal document viewer for Pod and other syntaxes

=head1 SYNOPSIS

   use App::sdview;

   exit App::sdview->new->run( "some-file.pod" );

=head1 DESCRIPTION

This module implements a terminal-based program for viewing structured
documents. It currently understands Pod, some simple Markdown formatting, and
a basic understanding of nroff (for manpages). Future versions may expand on
these abilities, extending them or adding new formats.

To actually use it, you likely wanted wanted to see the F<bin/sdview> script.

   $ sdview Some::Module

   $ sdview lib/Some/Module.pm

   $ sdview README.md

   $ sdview man/somelib.3

Various output plugins exist. By default it will output a terminal-formatted
rendering of the document via the F<less> pager, but it can also output
plaintext, Pod, Markdown.

   $ sdview Some::Module -o plain > module.txt

   $ sdview Some::Module -o Markdown > module.md

=cut

# Permit loaded output modules to override
our $DEFAULT_OUTPUT = "terminal";

use Module::Pluggable
   search_path => "App::sdview::Parser",
   sub_name    => "PARSERS",
   require     => 1;

use Module::Pluggable
   search_path => "App::sdview::Output",
   sub_name    => "OUTPUTS",
   require     => 1;

method run ( $file, %opts )
{
   if( -f( my $configpath = "$ENV{HOME}/.sdviewrc" ) ) {
      App::sdview::Style->load_config( $configpath );
   }

   my @PARSER_CLASSES = sort { $a->sort_order <=> $b->sort_order } PARSERS();
   my @OUTPUT_CLASSES = OUTPUTS();

   my $parser_class;

   if( defined $opts{format} ) {
      $parser_class = first { $_->can( "format" ) and $_->format eq $opts{format} } @PARSER_CLASSES or
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

   $opts{output} //= $DEFAULT_OUTPUT;

   my $output_class = first { $_->can( "format" ) and $_->format eq $opts{output} } @OUTPUT_CLASSES or
      die "Unrecognised output name $opts{output}\n";

   my @paragraphs = $parser_class->new->parse_file( $file );

   $output_class->new->output( @paragraphs );
}

=head1 TODO

=over 4

=item *

Customisable formatting and style information in C<App::sdview::Style>.

=item *

Add more formats. ReST perhaps. Maybe others too.

=item *

Improved Markdown parser. Currently the parser is very simple.

=item *

Other outputs. Consider a L<Tickit>-based frontend.

Also more structured file writers - ReST.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
