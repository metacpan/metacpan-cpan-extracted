#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use experimental 'signatures';

package App::sdview::Style 0.12;

use Convert::Color;
use Convert::Color::XTerm 0.06;

=head1 NAME

C<App::sdview::Style> - store formatting style information for C<App::sdview>

=head1 DESCRIPTION

This module stores formatting style information for L<App::sdview> text output
formatters, such a L<App::sdview::Output::Plain> or
L<App::sdview::Output::Terminal>.

=head2 Config File

Style information can be overridden by the user, supplying a
L<Config::Tiny>-style file at F<$HOME/.sdviewrc>. Formatting for each kind of
paragraph is provided in a section called C<Para $NAME>, and each individual
key gives formatting values.

   [Para head1]
   bold = 0|1
   italic = 0|1
   monospace = 0|1
   blank_after = 0|1
   under = NUM
   margin = NUM

   [Para head2]
   ...

The value for keys that set colours should be a string suitable for
L<< Convert::Color->new >>:

   [Para head1]
   fg = vga:red
   bg = xterm:184

=cut

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
   head2    => { fg => Convert::Color->new( "vga:cyan" ), bold => 1, margin => 2 },
   head3    => { fg => Convert::Color->new( "vga:green" ), bold => 1, margin => 4 },
   head4    => { fg => Convert::Color->new( "xterm:217" ), under => 1, margin => 5 },
   plain    => { margin => 6, blank_after => 1 },
   verbatim => { margin => 8, blank_after => 1, $FORMATSTYLES{C}->%* },
   list     => { margin => 6 },
   item     => { blank_after => 1 },
   leader   => { bold => 1 },
   table    => { margin => 8 },
   "table-heading" => { bold => 1 },
);

sub load_config ( $pkg, $path )
{
   require Config::Tiny;

   # For unit testing, also accept a globref
   my $config = ( ref $path ) ? Config::Tiny->read_string( do { local $/; <$path> } )
                              : Config::Tiny->read( $path );

   foreach my $section ( sort keys %$config ) {
      if( $section =~ m/^Para (.*)$/ ) {
         my $para = $1;

         unless( $PARASTYLES{$para} ) {
            warn "Unrecognised [Para $para] style in $path\n";
            next;
         }

         foreach my $stylekey ( sort keys $config->{$section}->%* ) {
            my $val = $config->{$section}{$stylekey};
            if( $stylekey =~ m/^(fg|bg)$/ ) {
               $val = Convert::Color->new( $val );
            }
            elsif( $stylekey =~ m/^(bold|italic|monospace|blank_after)$/ ) {
               $val = !!$val;
            }
            elsif( $stylekey =~ m/^(under|margin)$/ ) {
               $val = 0+$val;
            }
            else {
               warn "Unrecognised [Para $para] key $stylekey in $path\n";
               next;
            }

            $PARASTYLES{$para}{$stylekey} = $val;
         }
      }
   }
}

sub para_style ( $pkg, $type )
{
   $PARASTYLES{$type} or
      die "Unrecognised paragraph style for $type";

   return $PARASTYLES{$type};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
