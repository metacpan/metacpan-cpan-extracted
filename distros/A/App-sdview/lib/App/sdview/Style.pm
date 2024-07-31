#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use experimental 'signatures';

package App::sdview::Style 0.18;

use Convert::Color;
use Convert::Color::XTerm 0.06;

=head1 NAME

C<App::sdview::Style> - store formatting style information for C<App::sdview>

=head1 DESCRIPTION

This module stores formatting style information for L<App::sdview> text output
formatters, such a L<App::sdview::Output::Plain> or
L<App::sdview::Output::Terminal>.

=head2 Config File

=for highlighter

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

Specifying the special value C<~> deletes the default value for that key
without providing a replacement.

The value for keys that set colours should be a string suitable for
L<< Convert::Color->new >>:

   [Para head1]
   fg = vga:red
   bg = xterm:184

Formatting for each kind of inline format is provided in a section called
C<Inline $NAME>, using the same key names as paragraphs.

   [Inline monospace]
   fg = xterm:rgb(5,2,0)

Note that the C<[Inline monospace]> style is automatically inherited by
C<[Para verbatim]>.

Style information for syntax highlighting can be supplied in sections called
C<[Highlight $NAME]>, where each name is the F<tree-sitter> query capture name
for the highlight group.

   [Highlight comment]
   bg = xterm:232

=cut

sub _fixup_colour_keys ( $style )
{
   $style->{$_} and
      $style->{$_} = Convert::Color->new( $style->{$_} ) for qw( fg bg );
}

my %FORMATSTYLES = (
   bold          => { bold => 1 },
   italic        => { italic => 1 },
   monospace     => { monospace => 1, bg => "xterm:235" },
   underline     => { under => 1 },
   strikethrough => { strike => 1 },

   file => { italic => 1, under => 1 },
   link => { under => 1, fg => "xterm:rgb(3,3,5)" }, # light blue
);
_fixup_colour_keys $_ for values %FORMATSTYLES;

sub inline_style ( $pkg, $type )
{
   $FORMATSTYLES{$type} or
      die "Unrecognised inline style for $type";

   my %style = $FORMATSTYLES{$type}->%*;
   defined $style{$_} or delete $style{$_} for keys %style;

   return \%style;
}

sub convert_str ( $pkg, $s )
{
   return $s->clone(
      convert_tags => {
         ( map {
            my $k = $_;
            if( $k eq "link" ) {
               $k => sub ($, $v) { link => $v, $FORMATSTYLES{$k}->%* };
            }
            else {
               $k => sub { $FORMATSTYLES{$k}->%* };
            }
         } keys %FORMATSTYLES ),
      },
   );
}

my %PARASTYLES = (
   head1    => { fg => "vga:yellow", bold => 1 },
   head2    => { fg => "vga:cyan",   bold => 1, margin => 2 },
   head3    => { fg => "vga:green",  bold => 1, margin => 4 },
   head4    => { fg => "xterm:217",  under => 1, margin => 5 },
   plain    => { margin => 6, blank_after => 1 },
   verbatim => { margin => 8, blank_after => 1, inherit => "monospace" },
   list     => { margin => 6 },
   item     => { blank_after => 1 },
   leader   => { bold => 1 },
   table    => { margin => 8 },
   "table-heading" => { bold => 1 },
);
_fixup_colour_keys $_ for values %PARASTYLES;

sub para_style ( $pkg, $type )
{
   $PARASTYLES{$type} or
      die "Unrecognised paragraph style for $type";

   my %style = $PARASTYLES{$type}->%*;
   %style = ( %style, $FORMATSTYLES{delete $style{inherit}}->%* ) if defined $style{inherit};
   defined $style{$_} or delete $style{$_} for keys %style;

   return \%style;
}

my %HIGHLIGHTSTYLES = (
   # Names stolen from tree-sitter's highlight theme
   attribute  => { fg => "vga:cyan", italic => 1 },
   character  => { fg => "vga:magenta" },
   comment    => { fg => "xterm:15", bg => "xterm:54", italic => 1 },
   decorator  => { fg => "xterm:140", italic => 1 },
   function   => { fg => "xterm:147", },
   keyword    => { fg => "vga:yellow", bold => 1 },
   module     => { fg => "vga:green", bold => 1 },
   number     => { fg => "vga:magenta" },
   operator   => { fg => "vga:yellow" },
   string     => { fg => "vga:magenta" },
   type       => { fg => "vga:green" },
   variable   => { fg => "vga:cyan" },

   'string.special' => { fg => "vga:red" },
   'function.builtin' => { fg => "xterm:147", bold => 1 },
);
$HIGHLIGHTSTYLES{$_} = { fallback => "keyword"  } for qw( include repeat conditional exception );
$HIGHLIGHTSTYLES{$_} = { fallback => "function" } for qw( method );
_fixup_colour_keys $_ for values %HIGHLIGHTSTYLES;

sub highlight_style ( $pkg, $key )
{
   my @nameparts = split m/\./, $key;
   while( @nameparts ) {
      my $style = $HIGHLIGHTSTYLES{ join ".", @nameparts } or
         pop( @nameparts ), next;

      if( keys( $style->%* ) == 1 and defined( my $fbkey = $style->{fallback} ) ) {
         return $pkg->highlight_style( $fbkey );
      }

      return $style;
   }

   return undef;
}

my %VALID_STYLE_KEYS = map { $_ => 1 } qw(
   fg bg
   bold italic monospace blank_after
   under margin
);

sub _convert_val ( $stylekey, $val )
{
   return undef if !defined $val or $val eq "~";

   if( $stylekey =~ m/^(fg|bg)$/ ) {
      return Convert::Color->new( $val );
   }
   elsif( $stylekey =~ m/^(bold|italic|monospace|blank_after)$/ ) {
      return !!$val;
   }
   elsif( $stylekey =~ m/^(under|margin)$/ ) {
      return 0+$val;
   }
   else {
      return undef;
   }
}

sub load_config ( $pkg, $path )
{
   require Config::Tiny;

   # For unit testing, also accept a globref
   my $config = ( ref $path ) ? Config::Tiny->read_string( do { local $/; <$path> } )
                              : Config::Tiny->read( $path );

   foreach my $section ( sort keys %$config ) {
      my $configdata = $config->{$section};

      if( $section =~ m/^Inline (.*)$/ ) {
         my $format = $1;

         unless( $FORMATSTYLES{$format} ) {
            warn "Unrecognised $section format in $path\n";
            next;
         }

         foreach my $stylekey ( sort keys $configdata->%* ) {
            $VALID_STYLE_KEYS{$stylekey} or
               warn( "Unrecognised $section key $stylekey in $path\n" ), next;

            $FORMATSTYLES{$format}{$stylekey} = _convert_val( $stylekey, $configdata->{$stylekey} );
         }
      }
      elsif( $section =~ m/^Para (.*)$/ ) {
         my $para = $1;

         unless( $PARASTYLES{$para} ) {
            warn "Unrecognised $section style in $path\n";
            next;
         }

         foreach my $stylekey ( sort keys $configdata->%* ) {
            $VALID_STYLE_KEYS{$stylekey} or
               warn( "Unrecognised $section key $stylekey in $path\n" ), next;

            $PARASTYLES{$para}{$stylekey} = _convert_val( $stylekey, $configdata->{$stylekey} );
         }
      }
      elsif( $section =~ m/^Highlight (.*)$/ ) {
         my $keyname = $1;
         my $highlight = $HIGHLIGHTSTYLES{$keyname} //= {};

         foreach my $stylekey ( sort keys $configdata->%* ) {
            $VALID_STYLE_KEYS{$stylekey} or
               warn( "Unrecognised $section key $stylekey in $path\n" ), next;

            $highlight->{$stylekey} = _convert_val( $stylekey, $configdata->{$stylekey} );
         }

         defined $highlight->{$_} or delete $highlight->{$_} for keys %$highlight;

         if( keys( %$highlight ) > 1 ) {
            delete $highlight->{fallback};
         }
      }
      else {
         warn "Unrecognised section $section in $path\n";
      }
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
