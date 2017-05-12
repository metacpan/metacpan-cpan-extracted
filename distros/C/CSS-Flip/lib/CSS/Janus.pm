#-*- perl -*-
#-*- coding: us-ascii -*-

=encoding us-ascii

=head1 NAME

CSS::Janus - Converts a left-to-right Cascading Style Sheet (CSS) into a right-to-left one

=head1 SYNOPSIS

  use CSS::Janus;
  
  $janus = CSS::Janus->new;
  $css_source_rtl = $janus->transform($css_source);

=head1 DESCRIPTION

As Janus have two faces, horizontal texts can run in two directions:
left to right and right to left.

CSS::Janus replaces "left" directed things in a Cascading Style Sheet (CSS)
file such as float, padding, margin with "right" directed values, and vice
versa.

This module is a Perl port of CSSJanus by Lindsey Simon <elsigh@google.com>.

=cut

use 5.005; # qr{} and $10 are required.

package CSS::Janus;

use strict;
#use warnings;
use Carp qw(carp croak);
use CSS::Janus::Consts;

# To be compatible with Perl 5.5.
use vars qw($VERSION $BASE_REVISION);
$VERSION       = '0.04';
$BASE_REVISION = 'http://cssjanus.googlecode.com/svn/trunk@31';

=head2 Constructor

=over 4

=item new ( [ options... ] )

Creates new CSS::Janus object.
Following options are available.

=over 4

=item swap_left_right_in_url =E<gt> 0|1

Fixes "left"/"right" string within URLs.
Default is C<0>, won't fix.

=item swap_ltr_rtl_in_url =E<gt> 0|1

Fixes "ltr"/"rtl" string within URLs.
Default is C<0>, won't fix.

=item ignore_bad_bgp =E<gt> 0|1

Ignores unmirrorable background-position values.
Default is C<0>, won't ignore and will croak it.

=back

=back

=cut

sub new {
    my $pkg = shift;
    bless {@_} => $pkg;
}

# Substituttion of CSS gradients which cannot be performed only by regexp
# because they can contain nested parentheses.

my $GRADIENT_RE = qr<$IDENT[\.-]gradient\s*\(>i;

sub substituteGradient {
    my $self           = shift;
    my $match_function = shift;
    my $input_string   = shift;

    pos($input_string) = 0;
    my $output = '';
    my ($other, $match, $paren_count);

    while ($input_string =~ m{\G(.*?)($GRADIENT_RE)}cg) {
	($other, $match) = ($1, $2);

	$paren_count = 1;
	while ($paren_count and $input_string =~ m{\G(\(|\)|[^()]+)}cg) {
	    if ($1 eq '(') {
		$paren_count++;
	    } elsif ($1 eq ')') {
		$paren_count--;
	    }
	    $match .= $1;
	}

	# pos() is at last closing parenthesis (or end of text).
	$output .= $other . &$match_function($match);
    }
    return $output . substr($input_string, pos($input_string));
}

# fixBodyDirectionLtrAndRtl ($line)
#
# Replaces ltr with rtl and vice versa ONLY in the body direction:
# 'body { direction:ltr }' => 'body { direction:rtl }'

sub fixBodyDirectionLtrAndRtl {
    my $self = shift;
    my $line = shift;

    $line =~ s{$BODY_DIRECTION_LTR_RE}{$1$2$3~TMP~}g;
    $line =~ s{$BODY_DIRECTION_RTL_RE}{$1$2$3ltr}g;
    $line =~ s{~TMP~}{rtl}g;

    return $line;
}

# fixLeftAndRight ($line)
#
# Replaces left with right and vice versa in line, e,g,:
# 'padding-left: 2px; margin-right: 1px;' =>
# 'padding-right: 2px; margin-left: 1px;'

sub fixLeftAndRight {
    my $self = shift;
    my $line = shift;

    $line =~ s{$LEFT_RE}{$1~TMP~}g;
    $line =~ s{$RIGHT_RE}{$1left}g;
    $line =~ s{~TMP~}{right}g;

    return $line;
}

# fixLeftAndRightInUrl ($line)
#
# Replaces left with right and vice versa within background URLs, e.g.:
# 'background:url(right.png)' => 'background:url(left.png)'

sub fixLeftAndRightInUrl {
    my $self = shift;
    my $line = shift;

    $line =~ s{$LEFT_IN_URL_RE}{~TMP~}g;
    $line =~ s{$RIGHT_IN_URL_RE}{left}g;
    $line =~ s{~TMP~}{right}g;

    return $line;
}

# fixLtrAndRtlInUrl ($line)
#
# Replaces ltr with rtl and vice versa within background URLs, e.g.:
# 'background:url(rtl.png)' => 'background:url(ltr.png)'

sub fixLtrAndRtlInUrl {
    my $self = shift;
    my $line = shift;

    $line =~ s{$LTR_IN_URL_RE}{~TMP~}g;
    $line =~ s{$RTL_IN_URL_RE}{ltr}g;
    $line =~ s{~TMP~}{rtl}g;

    return $line;
}

# fixCursorProperties ($line)
#
# Changes directional CSS cursor properties:
# 'cursor: ne-resize' => 'cursor: nw-resize'

sub fixCursorProperties {
    my $self = shift;
    my $line = shift;

    $line =~ s{$CURSOR_EAST_RE}{$1~TMP~}g;
    $line =~ s{$CURSOR_WEST_RE}{$1e-resize}g;
    $line =~ s{~TMP~}{w-resize}g;

    return $line;
}

# fixBorderRadius ($line)
#
# Changes border-radius and its browser-specific variants, e.g.:
# 'border-radius: 1px 2px 3px 4px / 5px 6px 7px' =>
# 'border-radius: 2px 1px 4px 3px / 6px 5px 6px 7px'

sub fixBorderRadius {
    my $self = shift;
    my $line = shift;

    $line =~ s{$BORDER_RADIUS_RE}{
	reorderBorderRadius($&, $1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    }eg;

    return $line;
}

# fixFourPartNotation ($line)
#
# Fixes the second and fourth positions in four-part CSS notation, e.g.:
# 'padding: 1px 2px 3px 4px' => 'padding: 1px 4px 3px 2px'

sub fixFourPartNotation {
    my $self = shift;
    my $line = shift;

    $line =~ s{$FOUR_NOTATION_QUANTITY_RE}{$1 $4 $3 $2}g;
    $line =~ s{$FOUR_NOTATION_COLOR_RE}{$1$2 $5 $4 $3}g;

    return $line;
}

# fixBackgroundPosition ($line)
#
# METHOD.  Changes horizontal background values in line.
#
# If value is not replaceable, croak it (by default) or carp it (if
# 'ignore_bad_bgp' option is set).

sub fixBackgroundPosition {
    my $self = shift;
    my $line = shift;

    $line =~ s{$BG_HORIZONTAL_PERCENTAGE_RE}{
	calculateNewBackgroundPosition($&, $1, $2, $3, $4, $5)
    }eg;
    $line =~ s{$BG_HORIZONTAL_PERCENTAGE_X_RE}{
	calculateNewBackgroundPositionX($&, $1, $2)
    }eg;
    $line =~ s{$BG_HORIZONTAL_LENGTH_RE}{
	$self->calculateNewBackgroundLengthPosition($&, $1, $2, $3, $4, $5)
    }eg;
    $line =~ s{$BG_HORIZONTAL_LENGTH_X_RE}{
	$self->calculateNewBackgroundLengthPositionX($&, $1, $2)
    }eg;

    return $line;
}

# Takes a list of zero to four border radius parts and returns a string of
# them reordered for bidi mirroring.

sub reorderBorderRadiusPart {
    my @part = @_;

    # Remove any piece which may be 'None'
    @part = grep { defined $_ and length $_ } @part;

    if (scalar @part == 4) {
	return "$part[1] $part[0] $part[3] $part[2]";
    } elsif (scalar @part == 3) {
	return "$part[1] $part[0] $part[1] $part[2]";
    } elsif (scalar @part == 2) {
	return "$part[1] $part[0]";
    } elsif (scalar @part == 1) {
	return $part[0];
    } elsif (scalar @part == 0) {
	return '';
    } else {
	croak "This can't happen!";
    }
}

# Receives a match object for a border-radius element and reorders it pieces.
sub reorderBorderRadius {
    my @m = @_;

    my $first_group  = reorderBorderRadiusPart(@m[3 .. 6]);
    my $second_group = reorderBorderRadiusPart(@m[7 .. $#m]);
    if ($second_group eq '') {
	return sprintf '%sborder-radius%s%s', $_[1], $_[2], $first_group;
    } else {
	return sprintf '%sborder-radius%s%s / %s', $_[1], $_[2],
	    $first_group, $second_group;
    }
}

# calculateNewBackgroundPosition ($&, $1, $2, $3, $4, $5)
#
# Changes horizontal background-position percentages, e.g.:
# 'background-position: 75% 50%' => 'background-position: 25% 50%'

sub calculateNewBackgroundPosition {
    my @m = @_;
    my $new_x;
    my $position_string;

    # The flipped value is the offset from 100%
    $new_x = 100 - int($m[4]);

    # Since m.group(1) may very well be None type and we need a string..
    if ($m[1]) {
	$position_string = $m[1];
    } else {
	$position_string = '';
    }

    return sprintf 'background%s%s%s%s%%%s',
	$position_string, $m[2], $m[3], $new_x, $m[5];
}

# calculateNewBackgroundPositionX ($&, $1, $2)
#
# Fixes percent based background-position-x, e.g.:
# 'background-position-x: 75%' => 'background-position-x: 25%'

sub calculateNewBackgroundPositionX {
    my @m = @_;
    my $new_x;

    # The flipped value is the offset from 100%
    $new_x = 100 - int($m[2]);

    return sprintf 'background-position-x%s%s%%', $m[1], $new_x;
}

my $BACKGROUND_POSITION_ERROR_MESSAGE =
    "Unmirrorable horizonal value \"%s\": %s\n";

sub warnForBackgroundPosition {
    my $self        = shift;
    my $bad_length  = shift;
    my $whole_value = shift;

    my $msg = sprintf $BACKGROUND_POSITION_ERROR_MESSAGE, $bad_length,
	$whole_value;
    if ($self->{'ignore_bad_bgp'}) {
	$@ = $msg;
	carp $msg;
    } else {
	croak $msg;
    }
}

# calculateNewBackgroundLengthPosition ($&, $1, $2, $3, $4, $5)
#
# Changes horizontal background-position lengths, e.g.:
# 'background-position: 0px 10px' => 'background-position: 100% 10px'
#
# If value is not replaceable, croak it (by default) or carp it (if
# 'ignore_bad_bgp' option is set).

sub calculateNewBackgroundLengthPosition {
    my $self = shift;
    my @m    = @_;
    my $position_string;

    # croak if the length is not zero-valued
    unless ($m[4] =~ m{^$ZERO_LENGTH}) {
	$self->warnForBackgroundPosition($m[4], $m[0]);
	return $m[0];
    }

    if (defined $m[1] and length $m[1]) {
	$position_string = $m[1];
    } else {
	$position_string = '';
    }

    return sprintf 'background%s%s%s100%%%s',
	$position_string, $m[2], $m[3], $m[5];
}

# calculateNewBackgroundLengthPositionX ($&, $1, $2)
#
# Fixes background-position-x lengths, e.g.:
# 'background-position-x: 0' => 'background-position-x: 100%'
#
# If value is not replaceable, croak it (by default) or carp it (if
# 'ignore_bad_bgp' option is set).

sub calculateNewBackgroundLengthPositionX {
    my $self = shift;
    my @m    = @_;

    # croak if the length is not zero-valued
    unless ($m[2] =~ m{^$ZERO_LENGTH}) {
	$self->warnForBackgroundPosition($m[2], $m[0]);
	return $m[0];
    }

    return sprintf 'background-position-x%s100%%', $m[1];
}

=head2 Method

=over 4

=item transform ( $lines, [ options... ] )

Runs the fixing functions against CSS source.

$lines is a string.
Following options are available.

=over 4

=item swap_ltr_rtl_in_url =E<gt> 0|1

Overrides this flag if param is set.

=item swap_left_right_in_url =E<gt> 0|1

Overrides this flag if param is set.

=back

Returns same lines directions (left and right) are changed.

=back

=cut

sub transform {
    my $self = shift;
    my $line = shift;
    my %opts = @_;

    return undef unless defined $line;

    # Possibly override flags with params.
    my $swap_ltr_rtl_in_url    = $opts{'swap_ltr_rtl_in_url'};
    my $swap_left_right_in_url = $opts{'swap_left_right_in_url'};
    unless (defined $swap_ltr_rtl_in_url) {
	$swap_ltr_rtl_in_url = $self->{'swap_ltr_rtl_in_url'};
    }
    unless (defined $swap_left_right_in_url) {
	$swap_left_right_in_url = $self->{'swap_left_right_in_url'};
    }

    my @originals = ();

    # Tokenize tokens tokenizer can be confused.
    $line =~ s{(~[A-Z_\d]+~)}{
	push @originals, $1;
	'~X_' . (scalar @originals) . '~'
    }eg;

    # Tokenize any single line rules with the /* noflip */ annotation.
    $line =~ s{$NOFLIP_SINGLE_RE}{
	push @originals, $1;
	'~NOFLIP_SINGLE_' . (scalar @originals) . '~'
    }eg;

    # Tokenize any class rules with the /* noflip */ annotation.
    $line =~ s{$NOFLIP_CLASS_RE}{
	push @originals, $1;
	'~NOFLIP_CLASS_' . (scalar @originals) . '~'
    }eg;

    # Tokenize the comments so we can preserve them through the changes.
    $line =~ s{$COMMENT_RE}{
	push @originals, $1;
	'~C_' . (scalar @originals) . '~'
    }eg;

    # Tokenize gradients since we don't want to mirror the values inside
    $line = $self->substituteGradient(
	sub {
	    push @originals, shift;
	    '~GRADIENT_' . (scalar @originals) . '~';
	},
	$line
    );

    # Here starteth the various left/right direction fixes.
    $line = $self->fixBodyDirectionLtrAndRtl($line);

    if ($swap_left_right_in_url) {
	$line = $self->fixLeftAndRightInUrl($line);
    }

    if ($swap_ltr_rtl_in_url) {
	$line = $self->fixLtrAndRtlInUrl($line);
    }

    $line = $self->fixLeftAndRight($line);
    $line = $self->fixCursorProperties($line);

    $line = $self->fixBorderRadius($line);

    # Since FourPartNotation conflicts with BorderRadius, we tokenize
    # border-radius properties here.
    $line =~ s{$BORDER_RADIUS_TOKENIZER_RE}{
	push @originals, $1;
	'~BORDER_RADIUS_' . (scalar @originals) . '~'
    }eg;
    $line = $self->fixFourPartNotation($line);
    $line =~ s{~BORDER_RADIUS_(\d+)~}{$originals[$1 - 1]}eg;

    $line = $self->fixBackgroundPosition($line);

    # DeTokenize gradients
    $line =~ s{~GRADIENT_(\d+)~}{$originals[$1 - 1]}eg;

    # DeTokenize the single line noflips.
    $line =~ s{~NOFLIP_SINGLE_(\d+)~}{$originals[$1 - 1]}eg;

    # DeTokenize the class-level noflips.
    $line =~ s{~NOFLIP_CLASS_(\d+)~}{$originals[$1 - 1]}eg;

    # DeTokenize the comments.
    $line =~ s{~C_(\d+)~}{$originals[$1 - 1]}eg;

    # Detokenize tokens tokenizer can be confused.
    $line =~ s{~X_(\d+)~}{$originals[$1 - 1]}eg;

    return $line;
}

=head1 VERSION

Consult C<$VERSION> variable.

=head1 SEE ALSO

CSSJanus L<http://cssjanus.commoner.com/>.

A PHP port of CSSJanus L<http://www.mediawiki.org/wiki/Manual:CSSJanus.php>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji <hatuka(at)nezumi.nu>.

=head1 COPYRIGHT

Copyright (C) 2013 Hatuka*nezumi - IKEDA Soji.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
