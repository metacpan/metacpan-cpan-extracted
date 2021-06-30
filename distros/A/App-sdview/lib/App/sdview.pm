#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;
use utf8;

use Object::Pad;

package App::sdview 0.02;
class App::sdview;

use List::Keywords qw( first );

use Term::Size;
use Convert::Color;
use Convert::Color::XTerm 0.06;
use String::Tagged::Terminal;

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

my %FORMATSTYLES = (
   B => { bold => 1 },
   I => { italic => 1 },
   F => { italic => 1, under => 1 },
   C => { monospace => 1, bg => Convert::Color->new( "xterm:235" ) },
   L => { under => 1, fg => Convert::Color->new( "xterm:rgb(3,3,5)" ) }, # light blue
);

my %PARASTYLES = (
   head1    => { fg => Convert::Color->new( "vga:yellow" ), bold => 1 },
   head2    => { fg => Convert::Color->new( "vga:cyan" ), bold => 1, indent => 2 },
   head3    => { fg => Convert::Color->new( "vga:green" ), bold => 1, indent => 4 },
   # TODO head4
   plain    => { indent => 6, blank_after => 1 },
   verbatim => { indent => 8, blank_after => 1, $FORMATSTYLES{C}->%* },
);
$PARASTYLES{item} = $PARASTYLES{plain};

my @PARSER_CLASSES = qw(
   App::sdview::Parser::Pod
   App::sdview::Parser::Markdown
);

require ( "$_.pm" =~ s{::}{/}gr ) for @PARSER_CLASSES;

method run ( $file, %opts )
{
   my $parser_class;

   if( defined $opts{format} ) {
      $parser_class = first { $_->format eq $opts{format} } @PARSER_CLASSES or
         die "Unrecognised format name $opts{format}\n";
   }

   if( ! -f $file ) {
      open my $f, "-|", "perldoc", "-l", $file;
      $file = <$f>; chomp $file if defined $file;
      close $f;
      $? and return $? >> 8;
   }

   $parser_class //= do {
      first { $_->can_parse_file( $file ) } @PARSER_CLASSES or
         die "Unable to find a handler for $file\n";
   };

   my @paragraphs = $parser_class->new->parse_file( $file );

   # Unless -n switch
   open my $outh, "|-", "less", "-R";
   $outh->binmode( ":encoding(UTF-8)" );
   select $outh;

   my $TERMWIDTH = Term::Size::chars;

   my $nextblank;

   # To avoid recusion over a bunch of variables as state, we'll maintain a queue
   while ( @paragraphs ) {
      my $para = shift @paragraphs;

      my $margin;
      my $leader;
      my %typestyle;

      if( ref $para eq "HASH" ) {
         $margin = $para->{margin};
         $leader = sprintf "%-*s", $margin, $para->{leader};

         %typestyle = ( $para->%* );

         $para = $para->{para};
      }

      if( $para->type =~ m/^list-(.*)$/ ) {
         my $listtype = $1;

         my $n = 1;

         unshift @paragraphs, map {
            my $item = $_;
            if( $item->type ne "item" ) {
               # non-items just stand as they are + indent
               { para => $item, margin => $margin + $para->indent }
            }
            elsif( $listtype eq "bullet" ) {
               { para => $item, margin => $margin + $para->indent, leader => "*" }
            }
            elsif( $listtype eq "number" ) {
               { para => $item, margin => $margin + $para->indent, leader => sprintf "%d.", $n++ }
            }
            elsif( $listtype eq "text" ) {
               { para => $item, margin => $margin, blank_after => 0 }
            }
         } $para->items;
         next;
      }

      say "" if $nextblank;

      %typestyle = ( $PARASTYLES{ $para->type }->%*, %typestyle );

      my $s = $para->text->clone(
         convert_tags => {
            ( map { $_ => do { my $k = $_; sub { $FORMATSTYLES{$k}->%* } } } keys %FORMATSTYLES ),
         },
      );

      $typestyle{$_} and $s->apply_tag( 0, -1, $_ => $typestyle{$_} )
         for qw( fg bg bold under italic monospace );

      $nextblank = !!$typestyle{blank_after};

      my @lines = $s->split( qr/\n/ );

      my $indent = $typestyle{indent} // 0;
      $indent += $margin;

      foreach my $line ( @lines ) {
         length $line or
            ( print "\n" ), next;

         $s = String::Tagged::Terminal->new_from_formatting( $line );

         my $width = $TERMWIDTH - $indent - length($leader // "");

         while( length $s ) {
            my $part;
            if( length($s) > $width ) {
               if( substr($s, 0, $width) =~ m/(\s+)\S*$/ ) {
                  my $partlen = $-[1];
                  my $chopat = $+[1];

                  $part = $s->substr( 0, $partlen );
                  $s->set_substr( 0, $chopat, "" );
               }
               else {
                  die "ARGH: notsure how to trim this one\n";
               }
            }
            else {
               $part = $s;
               $s = "";
            }

            print " "x($indent - length($leader // ""));
            print $leader if defined $leader;
            print $part->build_terminal . "\n";

            undef $leader;
         }
      }
   }
}

=head1 TODO

=over 4

=item *

Add more formats. nroff and ReST at least. Perhaps others.

=item *

Improved Markdown parser. Currently the parser is very simple.

=item *

Other outputs. Consider a L<Tickit>-based frontend. Also some structured file
writers - allowing cross-conversion between POD, Markdown, ReST, nroff and
maybe also HTML output.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
