#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use experimental 'signatures';

package App::sdview::Style 0.11;

use Convert::Color;
use Convert::Color::XTerm 0.06;

my %FORMATSTYLES = (
   B => { bold => 1 },
   I => { italic => 1 },
   F => { italic => 1, under => 1 },
   C => { monospace => 1, bg => Convert::Color->new( "xterm:235" ) },
   L => { under => 1, fg => Convert::Color->new( "xterm:rgb(3,3,5)" ) }, # light blue
);

sub convert_str ( $pkg, $s )
{
   return $s->clone(
      convert_tags => {
         ( map { $_ => do { my $k = $_; sub { $FORMATSTYLES{$k}->%* } } } keys %FORMATSTYLES ),
      },
   );
}

my %PARASTYLES = (
   head1    => { fg => Convert::Color->new( "vga:yellow" ), bold => 1 },
   head2    => { fg => Convert::Color->new( "vga:cyan" ), bold => 1, indent => 2 },
   head3    => { fg => Convert::Color->new( "vga:green" ), bold => 1, indent => 4 },
   head4    => { fg => Convert::Color->new( "xterm:217" ), under => 1, indent => 5 },
   plain    => { indent => 6, blank_after => 1 },
   verbatim => { indent => 8, blank_after => 1, $FORMATSTYLES{C}->%* },
   list     => { indent => 6 },
   leader   => { bold => 1 },
   table    => { indent => 8 },
   "table-heading" => { bold => 1 },
);
$PARASTYLES{item} = $PARASTYLES{plain};

sub para_style ( $pkg, $type )
{
   $PARASTYLES{$type} or
      die "Unrecognised paragraph style for $type";

   return $PARASTYLES{$type};
}

0x55AA;
