#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use utf8;

use Object::Pad 0.800;

package App::sdview 0.20;
class App::sdview :strict(params);

use Sublike::Extended 0.29 'method';

use App::sdview::Style;
use App::sdview::Highlighter;

use List::Keywords qw( first );

=head1 NAME

C<App::sdview> - a terminal document viewer for Pod and other syntaxes

=head1 SYNOPSIS

=for highlighter perl

   use App::sdview;

   exit App::sdview->new->run( "some-file.pod" );

=head1 DESCRIPTION

This module implements a terminal-based program for viewing structured
documents. It currently understands Pod, some simple Markdown formatting, and
a basic understanding of nroff (for manpages). Future versions may expand on
these abilities, extending them or adding new formats.

To actually use it, you likely wanted wanted to see the F<bin/sdview> script.

=for highlighter

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
   inner       => 0,
   require     => 1;

use Module::Pluggable
   search_path => "App::sdview::Output",
   sub_name    => "OUTPUTS",
   inner       => 0,
   require     => 1;

# Must call this *before* ->run entersub so that DEFAULT_OUTPUT is overridden properly
my @OUTPUT_CLASSES = OUTPUTS();

method run ( $file,
   :$format = undef,
   :$output //= $DEFAULT_OUTPUT,
   :$highlight = 0,
   :$output_options //= [],
   %opts
) {
   my @PARSER_CLASSES = sort { $a->sort_order <=> $b->sort_order } PARSERS();

   if( ( $format // "" ) eq "?" ) {
      say "Parser format types:";
      $_->can( "format" ) and say "  " . $_->format . "  (provided by $_)"
         for @PARSER_CLASSES;
      exit 0;
   }
   if( ( $output // "" ) eq "?" ) {
      say "Output format types:";
      $_->can( "format" ) and say "  " . $_->format . "  (provided by $_)"
         for @OUTPUT_CLASSES;
      exit 0;
   }

   if( -f( my $configpath = "$ENV{HOME}/.sdviewrc" ) ) {
      App::sdview::Style->load_config( $configpath );
   }

   my %output_options = map {
      map { m/^(.*?)=(.*)$/ ? ( $1 => $2 ) : ( $_ => !!1 ) } split m/,/, $_;
   } $output_options->@*;

   my $parser_class;

   if( defined $format ) {
      $parser_class = first { $_->can( "format" ) and $_->format eq $format } @PARSER_CLASSES or
         die "Unrecognised format name $format\n";
   }

   if( !defined $file ) {
      die "Require a FILE to read - such as doc.md or doc.pod\n";
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

   my $output_class = first { $_->can( "format" ) and $_->format eq $output } @OUTPUT_CLASSES or
      die "Unrecognised output name $output\n";

   my @paragraphs = $parser_class->new->parse_file( $file );

   if( $highlight ) {
      apply_highlights( $_ ) for @paragraphs;
   }

   # TODO: unrecognised output option key names will not look very neat here
   $output_class->new( %output_options )->output( @paragraphs );
}

sub apply_highlights ( $para )
{
   if( $para->type eq "verbatim" and defined( my $language = $para->language ) ) {
      App::sdview::Highlighter->highlight_str( $para->text, $language );
   }

   if( $para->type =~ m/^list-/ ) {
      apply_highlights( $_ ) for $para->items;
   }
}

=head1 TODO

=over 4

=item *

Add more formats. ReST perhaps. Maybe others too.

=item *

Improved Markdown parser. Currently the parser is very simple.

=item *

Also more structured file writers - ReST.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
