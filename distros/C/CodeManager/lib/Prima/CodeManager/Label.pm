################################################################################
# This is CodeManager
# Copyright 2009-2013 by Waldemar Biernacki
# http://codemanager.sao.pl\n" .
#
# License statement:
#
# This program/library is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#
# Last modified (DMYhms): 13-01-2013 09:42:05.
################################################################################

package Prima::CodeManager::Label;

use strict;
use warnings;

use vars qw(@ISA);
@ISA = qw(Prima::Widget);

use Prima::Const;
use Prima::Classes;

sub profile_default
{
	my $font = $_[ 0]-> get_default_font;
	return {
		%{$_[ 0]-> SUPER::profile_default},
		alignment      => ta::Left,
		autoHeight     => 0,
		autoWidth      => 1,
		focusLink      => undef,
		height         => $font->{height},
		ownerBackColor => 1,
		selectable     => 0,
		showAccelChar  => 0,
		showPartial    => 1,
		tabStop        => 0,
		valignment     => ta::Top,
		widgetClass    => wc::Label,
		wordWrap       => 0,
		lineSpace      => 0,
	}
}

sub profile_check_in
{
	my ( $self, $p, $default) = @_;
	$p-> { autoWidth} = 0 if

		! exists $p->{autoWidth} and (
		exists $p-> {width} ||

		exists $p-> {size} ||

		exists $p-> {rect} ||

		( exists $p-> {left} && exists $p-> {right})
	);
	$p-> {autoHeight} = 0 if

		! exists $p-> {autoHeight} and (
		exists $p-> {height} ||

		exists $p-> {size} ||

		exists $p-> {rect} ||

		( exists $p-> {top} && exists $p-> {bottom})
	);
	$self-> SUPER::profile_check_in( $p, $default);
	my $vertical = exists $p-> {vertical} ?

		$p-> {vertical} :

		$default-> { vertical};

	$self->{lineSpace} = $p->{lineSpace} || 0;
}

sub init
{
	my $self = shift;
	my %profile = $self-> SUPER::init(@_);
	$self-> { alignment}     = $profile{ alignment};
	$self-> { valignment}    = $profile{ valignment};
	$self-> { autoHeight}    = $profile{ autoHeight};
	$self-> { autoWidth}     = $profile{ autoWidth};
	$self-> { wordWrap}      = $profile{ wordWrap};
	$self-> { focusLink}     = $profile{ focusLink};
	$self-> { showAccelChar} = $profile{ showAccelChar};
	$self-> { showPartial}   = $profile{ showPartial};
	$self-> { lineSpace}     = $profile{ lineSpace};
	$self-> check_auto_size;
	return %profile;
}

sub on_paint
{
	my ($self,$canvas) = @_;
	my @size = $canvas-> size;
	my @clr;
	if ( $self-> enabled) {
		if ( $self-> focused) {
			@clr = ($self-> hiliteColor, $self-> hiliteBackColor);
		} else {

			@clr = ($self-> color, $self-> backColor);

		}
	} else {

		@clr = ($self-> disabledColor, $self-> disabledBackColor);

	}

	unless ( $self-> transparent) {
		$canvas-> color( $clr[1]);
		$canvas-> bar(0,0,@size);
	}

	my $fh = $canvas-> font-> height + $self->{lineSpace};
	my $ta = $self-> {alignment};
	my $wx = $self-> {widths};
	my $ws = $self-> {words};
	my ($starty,$ycommon) = (0, scalar @{$ws} * $fh);

	if ( $self-> {valignment} == ta::Top)  {

		$starty = $size[1] - $fh;
	} elsif ( $self-> {valignment} == ta::Bottom) {

		$starty = $ycommon - $fh;
	} else {

		$starty = ( $size[1] + $ycommon)/2 - $fh;

	}

	my $y   = $starty;
	my $tl  = $self-> {tildeLine};
	my $i;
	my $paintLine = !$self-> {showAccelChar} && defined($tl) && $tl < scalar @{$ws};

	unless ( $self-> enabled) {
		$canvas-> color( $self-> light3DColor);
		for ( $i = 0; $i < scalar @{$ws}; $i++) {
			my $x = 0;
			if ( $ta == ta::Center) {

				$x = ( $size[0] - $$wx[$i]) / 2;

			} elsif ( $ta == ta::Right) {

				$x = $size[0] - $$wx[$i];

			}
			$canvas-> text_out( $$ws[$i], $x + 1, $y - 1);
			$y -= $fh;
		}
		$y   = $starty;
		if ( $paintLine) {
			my $x = 0;
			if ( $ta == ta::Center) {

				$x = ( $size[0] - $$wx[$tl]) / 2;

			} elsif ( $ta == ta::Right) {

				$x = $size[0] - $$wx[$tl];

			}
			$canvas-> line(

				$x + $self-> {tildeStart} + 1, $starty - $fh * $tl - 1,
				$x + $self-> {tildeEnd} + 1,   $starty - $fh * $tl - 1
			);
		}
	}

	$canvas-> color( $clr[0]);
	for ( $i = 0; $i < scalar @{$ws}; $i++) {
		my $x = 0;
		if ( $ta == ta::Center) {

			$x = ( $size[0] - $$wx[$i]) / 2;

		} elsif ( $ta == ta::Right) {

			$x = $size[0] - $$wx[$i];

		}
		$canvas-> text_out( $$ws[$i], $x, $y);
		$y -= $fh;
	}
	if ( $paintLine) {
		my $x = 0;
		if ( $ta == ta::Center) { $x = ( $size[0] - $$wx[$tl]) / 2; }
		elsif ( $ta == ta::Right) { $x = $size[0] - $$wx[$tl]; }
		$canvas-> line(

			$x + $self-> {tildeStart}, $starty - $fh * $tl,
			$x + $self-> {tildeEnd},   $starty - $fh * $tl
		);
	}
}

sub text
{
	return $_[0]-> SUPER::text unless $#_;
	my $self = $_[0];
	$self-> SUPER::text( $_[1]);
	$self-> check_auto_size;
	$self-> repaint;
}

sub on_translateaccel
{
	my ( $self, $code, $key, $mod) = @_;
	if (

		!$self-> {showAccelChar} &&

		defined $self-> {accel} &&

		( $key == kb::NoKey) &&

		lc chr $code eq $self-> { accel}
	) {
		$self-> clear_event;
		$self-> notify( 'Click');
	}
}

sub on_click
{
	my ( $self, $f) = ( $_[0], $_[0]-> {focusLink});
	$f-> select if defined $f && $f-> alive && $f-> enabled;
}

sub on_keydown
{
	my ( $self, $code, $key, $mod) = @_;
	if (

		defined $self-> {accel} &&

		( $key == kb::NoKey) &&

		lc chr $code eq $self-> { accel}
	) {
		$self-> notify( 'Click');
		$self-> clear_event;
	}
}

sub on_mousedown
{
	my $self = $_[0];
	$self-> notify( 'Click');
	$self-> clear_event;
}

sub on_fontchanged
{
	$_[0]-> check_auto_size;
}

sub on_size
{
	$_[0]-> reset_lines;
}

sub on_enable { $_[0]-> repaint } sub on_disable { $_[0]-> repaint }

sub set_alignment
{
	$_[0]-> {alignment} = $_[1];
	$_[0]-> repaint;
}

sub set_valignment
{
	$_[0]-> {valignment} = $_[1];
	$_[0]-> repaint;
}

sub reset_lines
{
	my $self = $_[0];

	my @res;
	my $maxLines = int( $self-> height / ($self-> font-> height  + $self->{lineSpace}));
	$maxLines++ if $self-> {showPartial} and (($self-> height % ($self-> font-> height + $self->{lineSpace})) > 0);

	my $opt   = tw::NewLineBreak|tw::ReturnLines|tw::WordBreak|tw::CalcMnemonic|tw::ExpandTabs|tw::CalcTabs;
	my $width = 1000000;
	$opt |= tw::CollapseTilde unless $self-> {showAccelChar};
	$width = $self-> width if $self-> {wordWrap};

	$self-> begin_paint_info;

	my $lines = $self-> text_wrap( $self-> text, $width, $opt);
	my $lastRef = pop @{$lines};

	$self-> {textLines} = scalar @$lines;
	for( qw( tildeStart tildeEnd tildeLine)) {$self-> {$_} = $lastRef-> {$_}}

	$self-> {accel} = defined($self-> {tildeStart}) ? lc( $lastRef-> {tildeChar}) : undef;
	splice( @{$lines}, $maxLines) if scalar @{$lines} > $maxLines;
	$self-> {words} = $lines;

	my @len;
	for ( @{$lines}) { push @len, $self-> get_text_width( $_); }
	$self-> {widths} = [@len];

	$self-> end_paint_info;
}

sub check_auto_size
{
	my $self = $_[0];
	my $cap = $self-> text;
	$cap =~ s/~//s unless $self-> {showAccelChar};
	my %sets;

	if ( $self-> {wordWrap}) {
		$self-> reset_lines;
		if ( $self-> {autoHeight}) {
			$self-> geomHeight( $self-> {textLines} * ($self-> font-> height + $self->{lineSpace}) + 2);
		}
	} else {
		my @lines = split "\n", $cap;
		if ( $self-> {autoWidth}) {
			$self-> begin_paint_info;
			$sets{geomWidth} = 0;
			for my $line ( @lines) {
				my $width = $self-> get_text_width( $line);
				$sets{geomWidth} = $width if

					$sets{geomWidth} < $width;
			}
			$sets{geomWidth} += 6;
			$self-> end_paint_info;
		}
		$sets{ geomHeight} = scalar(@lines) * ($self-> font-> height  + $self->{lineSpace}) + 2

			if $self-> {autoHeight};
		$self-> set( %sets);
		$self-> reset_lines;
	}
}

sub set_auto_width
{
	my ( $self, $aw) = @_;
	return if $self-> {autoWidth} == $aw;
	$self-> {autoWidth} = $aw;
	$self-> check_auto_size;
}

sub set_auto_height
{
	my ( $self, $ah) = @_;
	return if $self-> {autoHeight} == $ah;
	$self-> {autoHeight} = $ah;
	$self-> check_auto_size;
}

sub set_word_wrap
{
	my ( $self, $ww) = @_;
	return if $self-> {wordWrap} == $ww;
	$self-> {wordWrap} = $ww;
	$self-> check_auto_size;
}

sub set_show_accel_char
{
	my ( $self, $sac) = @_;
	return if $self-> {showAccelChar} == $sac;
	$self-> {showAccelChar} = $sac;
	$self-> check_auto_size;
}

sub set_show_partial
{
	my ( $self, $sp) = @_;
	return if $self-> {showPartial} == $sp;
	$self-> {showPartial} = $sp;
	$self-> check_auto_size;
}

sub get_lines
{
	return @{$_[0]-> {words}};
}

sub showAccelChar {($#_)?($_[0]-> set_show_accel_char($_[1])) :return $_[0]-> {showAccelChar}}
sub showPartial   {($#_)?($_[0]-> set_show_partial($_[1]))    :return $_[0]-> {showPartial}}
sub focusLink     {($#_)?($_[0]-> {focusLink}     = $_[1])    :return $_[0]-> {focusLink}    }
sub alignment     {($#_)?($_[0]-> set_alignment(    $_[1]))   :return $_[0]-> {alignment}    }
sub valignment    {($#_)?($_[0]-> set_valignment(    $_[1]))  :return $_[0]-> {valignment}   }
sub autoWidth     {($#_)?($_[0]-> set_auto_width(   $_[1]))   :return $_[0]-> {autoWidth}    }
sub autoHeight    {($#_)?($_[0]-> set_auto_height(  $_[1]))   :return $_[0]-> {autoHeight}   }
sub wordWrap      {($#_)?($_[0]-> set_word_wrap(    $_[1]))   :return $_[0]-> {wordWrap}     }

1;

__END__

=pod

=head1 NAME

Prima::CodeManager::Label - static text widget

=head1 DESCRIPTION

This is intesively modified the original Prima::Label module.
Please see details there: L<Prima::Label>.

=head1 AUTHOR OF MODIFICATIONS

Waldemar Biernacki, E<lt>wb@sao.plE<gt>

=head1 COPYRIGHT AND LICENSE OF THE FILE MODIFICATIONS

Copyright 2009-2012 by Waldemar Biernacki.

L<http://CodeManager.sao.pl>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
