#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;

use Object::Pad;

package App::sdview::Output::Terminal 0.04;
class App::sdview::Output::Terminal :strict(params);

use constant format => "terminal";

use Convert::Color;
use Convert::Color::XTerm 0.06;
use String::Tagged::Terminal;
use Term::Size;

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
   list     => { indent => 6 },
);
$PARASTYLES{item} = $PARASTYLES{plain};

sub _convert_str ( $s )
{
   return $s->clone(
      convert_tags => {
         ( map { $_ => do { my $k = $_; sub { $FORMATSTYLES{$k}->%* } } } keys %FORMATSTYLES ),
      },
   );
}

method output ( @paragraphs )
{

   # Unless -n switch
   open my $outh, "|-", "less", "-R";
   $outh->binmode( ":encoding(UTF-8)" );
   select $outh;

   my $TERMWIDTH = Term::Size::chars;

   my $nextblank;

   # To avoid recusion over a bunch of variables as state, we'll maintain a queue
   while ( @paragraphs ) {
      my $para = shift @paragraphs;

      my $margin = 0;
      my $leader;
      my %typestyle;
      my $indent;

      if( ref $para eq "HASH" ) {
         $margin = $para->{margin};
         $leader = $para->{leader};
         $indent = $para->{indent};

         %typestyle = ( $para->%* );

         $para = $para->{para};
      }

      if( $para->type =~ m/^list-(.*)$/ ) {
         my $listtype = $1;

         my $n = 1;

         my $indent = $PARASTYLES{list}{indent} // 0;

         unshift @paragraphs, map {
            my $item = $_;
            my $leader;
            if( $item->type ne "item" ) {
               # non-items just stand as they are + indent
            }
            elsif( $listtype eq "bullet" ) {
               $leader = String::Tagged->new( "*" );
            }
            elsif( $listtype eq "number" ) {
               $leader = String::Tagged->sprintf( "%d.", $n++ );
            }
            elsif( $listtype eq "text" ) {
               $leader = _convert_str( $item->term );
            }

            { para => $item, margin => $margin + $indent, indent => $para->indent, leader => $leader }
         } $para->items;
         next;
      }

      say "" if $nextblank;

      %typestyle = ( $PARASTYLES{ $para->type }->%*, %typestyle );

      my $s = _convert_str( $para->text );

      $typestyle{$_} and $s->apply_tag( 0, -1, $_ => $typestyle{$_} )
         for qw( fg bg bold under italic monospace );

      $nextblank = !!$typestyle{blank_after};

      my @lines = $s->split( qr/\n/ );
      @lines or @lines = ( String::Tagged->new ) if defined $leader;

      $indent //= $typestyle{indent};
      $indent //= 0;

      foreach my $line ( @lines ) {
         length $line or defined $leader or
            ( print "\n" ), next;

         $s = String::Tagged::Terminal->new_from_formatting( $line );

         my $width = $TERMWIDTH - $margin - $indent;

         while( length $s or defined $leader ) {
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

            if( defined $leader ) {
               $leader = String::Tagged::Terminal->new_from_formatting( $leader );

               if( length $leader <= $indent ) {
                  # If the leader will fit on the same line
                  print " "x$margin, $leader->build_terminal, " "x($indent - length $leader);
               }
               else {
                  # Spill the leader onto its own line
                  print " "x$margin, $leader->build_terminal;

                  print "\n", " "x$margin, " "x$indent if length $part;
               }

               undef $leader;
            }
            else {
               print " "x$margin, " "x$indent;
            }

            print $part->build_terminal . "\n";
         }
      }
   }
}

0x55AA;
