package Acme::AsciiArt2HtmlTable;

use warnings;
use strict;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
        'all' => [ qw(aa2ht) ],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(aa2ht);

=head1 NAME

Acme::AsciiArt2HtmlTable - Converts Ascii art to an HTML table

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Acme::AsciiArt2HtmlTable;

    my $table = "ggggggggrrrrrrrrrrrrrr\n" .
                "ggggggggrrrrrrrrrrrrrr\n" .
                "ggggggggrrrrrrrrrrrrrr\n" .
                "ggggggggrrrrrrrrrrrrrr\n" .
                "ggggggyyyyrrrrrrrrrrrr\n" .
                "ggggggyyyyrrrrrrrrrrrr\n" .
                "gggggyyyyyyrrrrrrrrrrr\n" .
                "gggggyyyyyyrrrrrrrrrrr\n" .
                "ggggggyyyyrrrrrrrrrrrr\n" .
                "ggggggyyyyrrrrrrrrrrrr\n" .
                "ggggggggrrrrrrrrrrrrrr\n" .
                "ggggggggrrrrrrrrrrrrrr\n" .
                "ggggggggrrrrrrrrrrrrrr\n" .
                "ggggggggrrrrrrrrrrrrrr\n" ;

    my $html = aa2ht( { td => { width => 3 , height => 3 } } , $table);

    # $html now holds a table with a color representation of your
    # ascii art. In this case, the Portuguese flag.

=cut

our %default_configuration;

=head1 FUNCTIONS

=head2 aa2ht

Gets ascii text and converts it to an HTML table. This is how it works:

=over 4

=item * each line is a C<tr> element

=item * each letter is a C<td> element

=item * each C<td> has background of a specific color, which is
defined by the letter that created it

=back

=cut

sub aa2ht {

  # default configuration
  my %config = _clone_hash( \%default_configuration );

=head3 OPTIONS

You can pass a reference to a hash before the text you want to
convert.

=cut

  if ( ref($_[0]) eq 'HASH' ) {
    my $new_config = shift;

=head4 id

In order to save space in the output, C<td> and C<tr> elements'
attributes are not in each element, but rather in a C<style> element.

This causes a problem if you want to put two different outputs with
different attributes on the same page.

To solve this problem: C<id>.

When creating a table, use the parameter C<id> to make sure it doesn't
end up mixed up with something else.

  my $html = aa2ht( { 'id' => 'special' } $ascii );

The result will be something like this:

  <style>
  .special td { width:1; height:1; }
  .special tr {  }
  </style>
  <table class="special" cellspacing="0" cellpadding="0" border="0">

=cut

    if (defined $new_config->{'id'}) { $config{'id'} = $new_config->{'id'} }

=head4 use-default-colors

If set to a false value, no default mappings are used.

  my $html = aa2ht( { 'use-default-colors' => 0 }, $ascii);

Behind the curtains, there is still a mapping: the default mapping to
white.

=cut

    if ( defined $new_config->{'use-default-colors'} ) {
      if ( not $new_config->{'use-default-colors'}) {
        $config{'colors'} = { 'default' => 'ffffff' } # everything is now white
      }
    }

=head4 colors

You can override color definitions or specify your own.

  my $html = aa2ht( { 'colors' => { '@' => 'ffddee',
                                    'g' => '00ffff' } }, $ascii);

=cut

    if ( ref($new_config->{'colors'}) eq 'HASH' ) {
      for (keys %{$new_config->{'colors'}}) {
        $config{'colors'}{$_} = $new_config->{'colors'}{$_};
      }
    }

=head4 randomize-new-colors

If set to a true value, letters with no mappings are assigned a
random one.

  my $html = aa2ht( { 'randomize-new-colors' => 1 }, $ascii);

You might want to remove the default mappings if you're really
interested in a completely random effect:

  my $html = aa2ht( { 'use-default-colors' => 0,
                      'randomize-new-colors' => 1 }, $ascii);

You might also want to keep the white space as a white block:

  my $html = aa2ht( { 'use-default-colors' => 0,
                      'colors' => { ' ' => 'ffffff'},
                      'randomize-new-colors' => 1 }, $ascii);

=cut

    if ( defined $new_config->{'randomize-new-colors'} ) {
      $config{'randomize-new-colors'} = $new_config->{'randomize-new-colors'}
    }

=head4 table

With the parameter C<table> you can specify specific values for fields
like C<border>, C<cellpadding> and C<cellspacing> (all these have
value "0" by default).

  my $html = aa2ht( { 'table' => { 'border' => '1' } }, $ascii );

These attributes go directly into the C<table> tag.

=head4 tr

With the C<tr> parameter you can specify specific values for C<tr>'s
attributes.

These attributes go into a C<style> tag. The table class uses that
style.

=head4 td

With the C<td> parameter you can specify specific values for C<td>'s
attributes, like C<width> or C<height>.

  my $html = aa2ht( { 'td' => { 'width' => '2px',
                                'height' => '2px' } }, $ascii);

These attributes go into a C<style> tag. The table class uses that
style.

=cut

    for my $elem ( qw/table tr td/ ) {
      defined $new_config->{$elem}            or next;
      ref    ($new_config->{$elem}) eq 'HASH' or next;

      for ( keys %{$new_config->{$elem}} ) {
        $config{$elem}{$_} = $new_config->{$elem}{$_};
      }
    }

    if (defined $new_config->{'optimization'}) {
      $config{'optimization'} = $new_config->{'optimization'};
    }

  }

##############

  # prepare the table, tr and td attributes
  my $table = join ' ', map { "$_=\"$config{'table'}{$_}\"" } sort keys %{$config{'table'}};

  my $tr    = join ' ', map { "$_:$config{'tr'}{$_};"       } sort keys %{$config{'tr'   }};
  my $td    = join ' ', map { "$_:$config{'td'}{$_};"       } sort keys %{$config{'td'   }};

  # our ascii text
  my $text = shift;

  # where we'll store our html
  my $html = '';

  # style (td and tr elements' attributes)
  $html .= "<style>\n" .
           ".$config{'id'} td { $td }\n.$config{'id'} tr { $tr }" .
           "\n</style>\n";

  # table header
  $html .= "<table class=\"$config{'id'}\" $table>\n";

  # prepare the cells
  my @lines = map { [ split //, $_ ] } split /\n/, $text;

  # just to make sure an optimized table has the same width as the normal one
  my $opt_fix = '';
  if ( $config{'optimization'} ) {
    my $width = 0;
    for my $l ( 0 .. $#lines ) {
      if ( $width < $#{$lines[$l]} ) {
        $width = $#{$lines[$l]};
      }
    }
    $opt_fix = '<tr>' . ( '<td></td>' x $width ) . '</tr>';
  }

  for my $line ( 0 .. $#lines ) {
    for my $cell ( 0 .. $#{$lines[$line]} ) {
      next if $lines[$line]->[$cell] eq '';

      # randomizing new colors
      if ( $config{'randomize-new-colors'} ) {
        if ( not defined $config{'colors'}{ $lines[$line]->[$cell] } ) {
          $config{'colors'}{ $lines[$line]->[$cell] } = _random_color();
        }
      }

      # optimization
      my $optimization = '';

      # debugging messages were kept for future reference

      # remember that lines and cells are not the exact values, as
      # arrays start at index 0 and both lines and cells start at
      # position 1

      #my $debug = "line $line, cell $cell, ";

      if ( $config{'optimization'} ) {

        #$debug .= "\nthis is line $line, cell $cell";
	# check how many cells we could have on each line from the line we're
	# in to the last one
        my %we_could_have;
        for ( $line .. $#lines ) {
          $we_could_have{$_} = _count_in_the_beginning(
                                        $lines[$line]->[$cell],
                                        @{$lines[$_]}[$cell .. $#{$lines[$_]}]
                                      );
          #$debug .= "\nwe could have $we_could_have{$_} on line $_";
        }

        # check, for each line, how many cells an area up to that line would have
        my %area;
        my %area_width;
        for ( $line .. $#lines ) {
          my $min = _min( @we_could_have{$line .. $_} );
          $area{$_} = (1 + $_ - $line) * $min;
          $area_width{$_} = $min;
          #$debug .="\nwe could make an area of $area{$_} up to line $_, with a maximum of $area_width{$_} cells per line";
        }

        # check which is the line that maximizes optimization
        my $max_area = _max(values %area);
        my $best_line = _max(grep { $area{$_} == $max_area } keys %area);
        #$debug .= "\nour best choice seem to be using line $best_line";

        # check the are width
        my $width = $cell + $area_width{$best_line} - 1;

        # clean everything in the area we're about to optimize
        #$debug .= "\nwe want to clean everything from lines $line to $best_line and cells $cell to $width";
        for my $l ( $line .. $best_line ) {
          for my $c ( $cell .. $width ) {
            next if ( $l == $line and $c == $cell );
            $lines[$l]->[$c] = '';
          }
        }

        # optimize
        my $rowspan = $best_line - $line + 1;
        my $colspan = $area_width{$best_line};

        if ( $rowspan > 1 ) { $optimization .= " rowspan=\"$rowspan\"" }
        if ( $colspan > 1 ) { $optimization .= " colspan=\"$colspan\"" }

        #$debug .= "\n";
      }

      $lines[$line]->[$cell] = "<td$optimization bgcolor=\"" .
                               ( $config{'colors'}{ $lines[$line]->[$cell] } ||
                                 $config{'colors'}{'default'} ) .
                               "\"></td>";

    }

    $lines[$line] = join "\n", grep /./, @{$lines[$line]};

    if ($config{'optimization'}) {
      # this is so empty rows aren't ignored by the browser
      $lines[$line] .= "\n<td></td>";
    }

  }

  # the table
  $html .= join "\n", map { "<tr>\n$_\n</tr>" } @lines;

  if ($config{'optimization'}) {
    # this is so empty columns aren't ignored by the browser
    $html .= "$opt_fix";
  }

  # table footer
  $html .= "\n</table>\n";

  # return the table
  return $html;
}

=head3 SPECIALS

=head4 optimization

Table optimization, which is disabled by default, uses the C<rowspan>
and C<colspan> C<td> attributes to save up space.

  my $html = aa2ht( { 'optimization' => 1 }, $ascii );

When the optimization algorithm sees a chance of turning some cells
into a big one, it does so. It always chooses the biggest area
possible for optimizing.

If two different areas suitable for optimization starting from a given
cell are available and both present the same area size, the algorithm
picks the one that maximizes width.

=head4 default color

By default, an unmapped character is mapped to the default color,
which is black.

You can override this color by assigning a different mapping to
"default" with the C<colors> option.

  my $html = aa2ht( { 'colors' => { 'default' => 'ffffff' } }, $ascii);

This, for instance, makes the default color be white, thus making only
the recognized characters show up colored on the table.

=head1 MAPPINGS ( LETTER -> COLOR )

The following letters are mapped to colors in the following way:

   l          000000   # black
   b          0000ff   # blue
   o          a52a2a   # brown
   g          00ff00   # green
   a          bebebe   # gray
   e          bebebe   # grey
   m          ff00ff   # magenta
   o          ffa500   # orange
   p          ffc0cb   # pink
   u          a020f0   # purple
   r          ff0000   # red
   w          ffffff   # white
   y          ffff00   # yellow

   L          000000   # light black
   B          add8e6   # lighe blue
   O          a52a2a   # light brown
   G          90ee90   # light green
   A          d3d3d3   # light gray
   E          d3d3d3   # light grey
   M          ff00ff   # light magenta
   O          ffa500   # light orange
   P          ffb6c1   # light pink
   U          9370db   # light purple
   R          cd5c5c   # light red
   W          ffffff   # light white
   Y          ffffe0   # light yellow

Spaces are mapped to white:

              ffffff   # white

By default, everything else is mapped to black

  default     000000   # black

=cut

BEGIN {

  # default configuration
  %default_configuration = (
            id    =>    'default',
            table => {
                        'border'      => 0,
                        'cellpadding' => 0,
                        'cellspacing' => 0,
                     },
            tr    => {
                     },
            td    => {
                        'width'       => '1px',
                        'height'      => '1px',
                     },
            colors=> { 
                        ' ' => 'ffffff',     # white

                        'l' => '000000',     # black
                        'b' => '0000ff',     # blue
                        'o' => 'a52a2a',     # brown
                        'g' => '00ff00',     # green
                        'a' => 'bebebe',     # gray
                        'e' => 'bebebe',     # grey
                        'm' => 'ff00ff',     # magenta
                        'o' => 'ffa500',     # orange
                        'p' => 'ffc0cb',     # pink
                        'u' => 'a020f0',     # purple
                        'r' => 'ff0000',     # red
                        'w' => 'ffffff',     # white
                        'y' => 'ffff00',     # yellow

                        'L' => '000000',     # light black
                        'B' => 'add8e6',     # light blue
                        'O' => 'a52a2a',     # light brown
                        'G' => '90ee90',     # light green
                        'A' => 'd3d3d3',     # light gray
                        'E' => 'd3d3d3',     # light grey
                        'M' => 'ff00ff',     # light magenta
                        'O' => 'ffa500',     # light orange
                        'P' => 'ffb6c1',     # light pink
                        'U' => '9370db',     # light purple
                        'R' => 'cd5c5c',     # light red
                        'W' => 'ffffff',     # light white
                        'Y' => 'ffffe0',     # light yellow

                        default => '000000', # black
                     },
            'randomize-new-colors' => 0,
            'optimization'         => 0,
          );

}

# subroutines

sub _random_color {
  my $color = '';

  for (1 .. 6) {
    $color .= qw/1 2 3 4 5 6 7 8 9 0 a b c d e f/[int rand 16];
  }

  return $color;
}

sub _clone_hash {
  my %hash = %{+shift};

  my %new_hash;

  for (keys %hash) {
    if (ref($hash{$_})) { 
      $new_hash{$_} = { _clone_hash ( $hash{$_} ) };
    }
    else {
      $new_hash{$_} = $hash{$_};
    }
  }

  return %new_hash;
}

sub _count_in_the_beginning {
  my ($cell, @elems) = @_;
  my $t = 0;
  for (@elems) {
    if ($cell eq $_) {
      $t++;
    }
    else {
      last;
    }
  }
  return $t;
}

sub _min {
  my $min = shift;

  for (@_) {
    if ( $min > $_ ) { $min = $_ }
  }

  return $min;
}

sub _max {
  my $max = shift;

  for (@_) {
    if ( $max < $_ ) { $max = $_ }
  }

  return $max;
}

=head1 SEE ALSO

The examples/ directory.

=head1 AUTHOR

Jose Castro, C<< <cog@cpan.org> >>

=head1 CAVEATS

If you specify the C<rowspan> or C<colspan> for C<td> elements and you
also ask for optimization... I don't even want to imagine what will
happen...

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-tablethis@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::AsciiArt2HtmlTable
