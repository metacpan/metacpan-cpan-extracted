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
# Last modified (DMYhms): 13-01-2013 09:42:14.
################################################################################

use strict;
use warnings;

use Prima::Const;
use Prima::Classes;
use Prima::IntUtils;

################################################################################

package Prima::CodeManager::TabSet;

use vars qw(@ISA);
@ISA = qw(Prima::Widget Prima::MouseScroller);

{
my %RNT = (
	%{Prima::Widget-> notification_types()},
	DrawTab     => nt::Action,
	MeasureTab  => nt::Action,
);

sub notification_types { return \%RNT; }
}

use constant DefBorderX		=>	10;
use constant DefDeltaX		=>	 3;
use constant DefDeltaY		=>	 3;
use constant DefBookmarkX	=>	30;
use constant DefTabMultiply	=>	1.4;

#-----------------------------------------------------------------------------------

sub profile_default
{
	my $def = $_[ 0]-> SUPER::profile_default;
	my $font = $_[ 0]-> get_default_font;

	my %prf = (
		colored          => 1,
		firstTab         => 0,
		focusedTab       => 0,
#		height           => $font-> { height} > 14 ? int (2.0 * $font-> { height}) : 28,
		height           => int ( DefTabMultiply * $_[0]-> font-> height ),
		ownerBackColor   => 1,
		selectable       => 1,
		selectingButtons => 0,
		tabStop          => 1,
		topMost          => 1,
		tabIndex         => 0,
		tabs             => [],
	);
	@$def{keys %prf} = values %prf;
	return $def;
}

#-----------------------------------------------------------------------------------

sub init
{
	my $self = shift;

	$self-> {tabIndex} = -1;
	for ( qw( colored firstTab focusedTab topMost lastTab arrows)) { $self-> {$_} = 0; }
	$self-> {tabs}     = [];
	$self-> {widths}   = [];
	my %profile = $self-> SUPER::init(@_);
	for ( qw( colored topMost tabs focusedTab firstTab tabIndex)) { $self-> $_( $profile{ $_}); }
	$self-> recalc_widths;
	$self-> reset;

	return %profile;
}

#-----------------------------------------------------------------------------------

sub reset
{
	my $self = $_[0];
	my @size = $self-> size;
	my $w = 0;
	for ( @{$self-> {widths}}) { $w += $_; }
	$self-> {arrows} = (( $w > $size[0]) and ( scalar( @{$self-> {widths}}) > 1));
	if ( $self-> {arrows}) {
		my $ft = $self-> {firstTab};
		$w  = 0;
#		$w += DefArrowX if $ft > 0;
		my $w2 = $w;
		my $la = $ft > 0;
		my $i;
		my $ra = 0;
		my $ww = $self-> {widths};
		for ( $i = $ft; $i < scalar @{$ww}; $i++) {
			$w += $$ww[$i];
			if ( $w >= $size[0]) {
				$ra = 1;
				$i-- if

					$i > $ft &&

#					$w - $$ww[$i] >= $size[0] - DefArrowX;
					$w - $$ww[$i] >= $size[0];
				last;
			}
		}
		$i = scalar @{$self-> {widths}} - 1

			if $i >= scalar @{$self-> {widths}};
		$self-> {lastTab} = $i;
		$self-> {arrows} = ( $la ? 1 : 0) | ( $ra ? 2 : 0);
	} else {
		$self-> {lastTab} = scalar @{$self-> {widths}} - 1;
	}
}

#-----------------------------------------------------------------------------------

sub recalc_widths
{
	my $self = $_[0];

	my @w;
	my $i;
	my ( $notifier, @notifyParms) = $self-> get_notify_sub(q(MeasureTab));
	$self-> begin_paint_info;
	$self-> push_event;

	for ( $i = 0; $i < scalar @{$self-> {tabs}}; $i++) {
		my $iw = 0;
		$notifier-> ( @notifyParms, $i, \$iw);
		push ( @w, $iw);
	}

	$self-> pop_event;
	$self-> end_paint_info;
	$self-> {widths}    = [@w];
}

#-----------------------------------------------------------------------------------

sub on_mousedown
{
	my ( $self, $btn, $mod, $x, $y) = @_;
	return if $self-> {mouseTransaction};

#print "on_mousedown|@_\n";

	$self-> clear_event;
	my ( $a, $ww, $ft, $lt) = (
		$self-> {arrows}, $self-> {widths}, $self-> {firstTab}, $self-> {lastTab}
	);

	if (( $a & 1) and ( $x < 0 )) {
		$self-> firstTab( $self-> firstTab - 1);
		$self-> capture(1);
		$self-> {mouseTransaction} = -1;
		$self-> scroll_timer_start;
		$self-> scroll_timer_semaphore(0);
		return;
	}

	my @size = $self-> size;
	if (( $a & 2) and ( $x >= $size[0] )) {
		$self-> firstTab( $self-> firstTab + 1);
		$self-> capture(1);
		$self-> {mouseTransaction} = 1;
		$self-> scroll_timer_start;
		$self-> scroll_timer_semaphore(0);
		return;
	}

	my $w = 0;
	my $i;
	my $found = undef;
	for ( $i = $ft; $i <= $lt; $i++) {
		$found = $i, last if $x < $w + $$ww[$i];
		$w += $$ww[$i];
	}
	return unless defined $found;

	if ( $found == $self-> {tabIndex}) {
		$self-> focusedTab( $found);
		$self-> focus;
	} else {
		$self-> tabIndex( $found);
	}
}

#-----------------------------------------------------------------------------------

sub on_mousewheel
{
	my ( $self, $mod, $x, $y, $z) = @_;
	$self-> tabIndex( $self-> tabIndex + (( $z < 0) ? -1 : 1));
	$self-> clear_event;
}

#-----------------------------------------------------------------------------------

sub on_mouseup
{
	my ( $self, $btn, $mod, $x, $y) = @_;
	return unless $self-> {mouseTransaction};
#print "on_mouseup|@_\n";

	$self-> capture(0);
	$self-> scroll_timer_stop;
	$self-> {mouseTransaction} = undef;
}

#-----------------------------------------------------------------------------------

sub on_mousemove
{
	my ( $self, $mod, $x, $y) = @_;
	return unless $self-> {mouseTransaction};
	return unless $self-> scroll_timer_semaphore;

	$self-> scroll_timer_semaphore(0);
	my $ft = $self-> firstTab;
	$self-> firstTab( $ft + $self-> {mouseTransaction});
	$self-> notify(q(MouseUp),1,0,0,0) if $ft == $self-> firstTab;
}

#-----------------------------------------------------------------------------------

sub on_mouseclick
{
	my $self = shift;
	$self-> clear_event;
	return unless pop;

#print "on_mouseclick|@_\n";
	$main::project-> file_close if $_[0] == mb::Right;

#	$self-> clear_event unless $self-> notify( "MouseDown", @_);
}

#-----------------------------------------------------------------------------------

sub on_keydown
{
	my ( $self, $code, $key, $mod) = @_;

	if ( $key == kb::Left || $key == kb::Right) {
		$self-> focusedTab( $self-> focusedTab + (( $key == kb::Left) ? -1 : 1));
		$self-> clear_event;
		return;
	}

	if ( $key == kb::PgUp || $key == kb::PgDn) {
		$self-> tabIndex( $self-> tabIndex + (( $key == kb::PgUp) ? -1 : 1));
		$self-> clear_event;
		return;
	}

	if ( $key == kb::Home || $key == kb::End) {
		$self-> tabIndex(( $key == kb::Home) ? 0 : scalar @{$self-> {tabs}});
		$self-> clear_event;
		return;
	}
	if ( $key == kb::Space || $key == kb::Enter) {
		$self-> tabIndex( $self-> focusedTab);
		$self-> clear_event;
		return;
	}
}

#-----------------------------------------------------------------------------------

sub on_paint
{
	my ($self,$canvas) = @_;

	my $DefBorderX	=	DefBorderX - DefDeltaX;

	my @clr  = ( $self-> color, $self-> backColor);
	   @clr  = ( $self-> disabledColor, $self-> disabledBackColor) if ( !$self-> enabled);
	my @c3d  = ( $self-> dark3DColor, $self-> light3DColor);
	my @size = $canvas-> size;

	$canvas-> color( $clr[1]);
	$canvas-> bar( 0, 0, @size );

	my ( $ft, $lt, $a, $ti, $ww, $tm) =
		( $self-> {firstTab}, $self-> {lastTab}, $self-> {arrows}, $self-> {tabIndex},
		$self-> {widths}, $self-> {topMost}
	);
	my ( $notifier, @notifyParms) = $self-> get_notify_sub(q(DrawTab));
	$self-> push_event;

	my $atX = 0;
	my $atXti = undef;
	my $i;
	for ( $i = $ft; $i <= $lt; $i++) {
		$atX += $$ww[$i];
	}

#	$canvas-> clipRect( 0, 0, $size[0], $size[1]) if $a & 2;

# zwykle - niezaznaczone taby:
	my @colorSet = ( @clr, @c3d);
	for ( $i = $lt; $i >= $ft; $i--) {
		$atX -= $$ww[$i];
		$atXti = $atX, next if $i == $ti;

		my @poly = (
			$atX + DefBorderX,								$size[1] - 1 - int (DefTabMultiply * $self-> font-> height),

			$atX + DefBorderX,								$size[1] - 1,
			$atX + DefBorderX + $$ww[$i] - 2 * DefDeltaX,	$size[1] - 1,
			$atX + DefBorderX + $$ww[$i] - 2 * DefDeltaX,	$size[1] - 1 - int (DefTabMultiply * $self-> font-> height)
		);
		$notifier-> ( @notifyParms, $canvas, $i, \@colorSet, \@poly);
	}

	my $swapDraw = ( $ti == $lt) && ( $a & 2);

	goto PaintSelTabBefore if $swapDraw;
PaintEarsThen:
	$canvas-> clipRect( 0, 0, @size) if $a & 2;
	if ( $a & 1) {
		my $x = 0;
		my @poly = (
			$x + DefBorderX,	$size[1] - 1 - int (DefTabMultiply * $self-> font-> height),

			$x + DefBorderX, 	$size[1] - 1,
			$x + DefBorderX,	$size[1] - 1,
			$x + DefBorderX,	$size[1] - 1 - int (DefTabMultiply * $self-> font-> height)
		);
		$notifier-> ( @notifyParms, $canvas, -1, \@colorSet, \@poly);
	}
	if ( $a & 2) {
		my $x = $size[0];
		my @poly = (
			$x + DefBorderX,	$size[1] - 1 - int (DefTabMultiply * $self-> font-> height),

			$x + DefBorderX, 	$size[1] - 1,
			$x + DefBorderX,	$size[1] - 1,
			$x + DefBorderX,	$size[1] - 1 - int (DefTabMultiply * $self-> font-> height)
		);
		$notifier-> ( @notifyParms, $canvas, -2, \@colorSet, \@poly);
	}
	$canvas-> color( $c3d[0]);
	$canvas-> line( $size[0] - 1,	0,	$size[0] - 1,	0 );
	$canvas-> line( $size[0] - 1,	0, 	$size[0] - 1,	int (DefTabMultiply * $self-> font-> height) );

	$canvas-> color( $c3d[1]);
	$canvas-> line( 0, int (DefTabMultiply * $self-> font-> height) - 1,	$size[0] - 1,	int (DefTabMultiply * $self-> font-> height) - 1);
	$canvas-> line( 0, int (DefTabMultiply * $self-> font-> height) - 1,	0, 				int (DefTabMultiply * $self-> font-> height) - 1);
	$canvas-> line( 0, 0, 													0,				int (DefTabMultiply * $self-> font-> height) - 1);

#	$canvas-> color( $clr[1]);
#	$canvas-> bar( 1, 0, $size[0] - 2, $self-> font-> height + 2 - 9);

	$canvas-> color( $clr[0]);

	goto EndOfSwappedPaint if $swapDraw;

PaintSelTabBefore:
	if ( defined $atXti) {
		my @poly = (
			$atXti + DefBorderX,								$size[1] - 2 * int (DefTabMultiply * $self-> font-> height),

			$atXti + DefBorderX,								$size[1] - 1,
			$atXti + DefBorderX + $$ww[$ti] - 2 * DefDeltaX, 	$size[1] - 1,
			$atXti + DefBorderX + $$ww[$ti] - 2 * DefDeltaX, 	$size[1] - 2 * int (DefTabMultiply * $self-> font-> height)
		);

		$notifier-> (

			@notifyParms, $canvas, $ti, \@colorSet, \@poly, undef

		);
	}
	goto PaintEarsThen if $swapDraw;

EndOfSwappedPaint:
	$self-> pop_event;
}

#-----------------------------------------------------------------------------------

sub on_size
{
	my ( $self, $ox, $oy, $x, $y) = @_;

	if ( $x > $ox && (( $self-> {arrows} & 2) == 0)) {
		my $w  = 0;
		my $ww = $self-> {widths};
		my $i;
		my $set = 0;

		for ( $i = scalar @{$ww} - 1; $i >= 0; $i--) {
			$w += $$ww[$i];
			$set = 1, $self-> firstTab( $i + 1), last if $w >= $x;
		}
		$self-> firstTab(0) unless $set;
	}
	$self-> reset;
}

#-----------------------------------------------------------------------------------

sub on_fontchanged { $_[0]-> reset; $_[0]-> recalc_widths; }
sub on_enter       { $_[0]-> repaint; }
sub on_leave       { $_[0]-> repaint; }

#-----------------------------------------------------------------------------------

sub on_measuretab
{
	my ( $self, $index, $sref) = @_;

	my $outtext = $self-> {tabs}-> [$index];
	my $star = '';
	$star    = '*' if $outtext =~ /^\*/;
	$outtext =~  s/^.*?([^\\\/]*)$/$1/;
	$outtext = $star.$outtext;

	$$sref = $self-> get_text_width( $outtext) + 4 *( int ( DefTabMultiply * $self-> font-> height ) - $self-> font-> height);
}

#-----------------------------------------------------------------------------------

# see L<DrawTab> below for more info
sub on_drawtab
{
	my ( $self, $canvas, $i, $clr, $poly, $poly2) = @_;

	my $name  = $self-> {tabs}-> [$i];
	$name =~ s/^\*+(.*)$/$1/;

	my $color = $Prima::CodeManager::info_of_files{$name}->{backColor};

	$canvas-> color(( $self-> {colored} && ( $i >= 0)) ? $color : $$clr[1]);
	$canvas-> fillpoly( $poly);

	$canvas-> color( $$clr[3]);
	$canvas-> polyline([
		$$poly[0], $$poly[1],
		$$poly[2], $$poly[3],
		$$poly[4], $$poly[5],
	]);

	$canvas-> color( $$clr[2]);
	$canvas-> polyline([
		$$poly[0] + 1,	$$poly[1],
		$$poly[6],		$$poly[7],
		$$poly[4],		$$poly[5],
	]);

	$canvas-> color( $$clr[0]);
	if ( $i >= 0) {

		my  @tx = (
			$$poly[0] + ( $$poly[6] - $$poly[0] - $self-> {widths}-> [$i]) / 2 + 2 * ( int ( DefTabMultiply * $self-> font-> height ) - $self-> font-> height ),
			$$poly[1] + ( $$poly[3] - $$poly[1] - $self-> font-> height ) / 2 + 1
		);
		my $outtext = $self-> {tabs}-> [$i];
		my $star = '';
		$star    = '*' if $outtext =~ /^\*/;
		$outtext =~  s/^.*?([^\\\/]*)$/$1/;
		$outtext = $star.$outtext;
		$canvas-> text_out( $outtext, @tx);
	}
}

#-----------------------------------------------------------------------------------

sub get_item_width
{
	return $_[0]-> {widths}-> [$_[1]];
}

#-----------------------------------------------------------------------------------

sub tab2firstTab
{
	my ( $self, $ti) = @_;
return;#wb
	if (
		( $ti >= $self-> {lastTab}) and

		( $self-> {arrows} & 2) and

		( $ti != $self-> {firstTab})
	) {
		my $w = 0;
#		$w += DefArrowX if $self-> {arrows} & 1;
		my $i;
		my $W = $self-> width;
		my $ww = $self-> {widths};
		my $moreThanOne = ( $ti - $self-> {firstTab}) > 0;

		for ( $i = $self-> {firstTab}; $i <= $ti; $i++) {
			$w += $$ww[$i];
		}

#		my $lim = $W - DefArrowX;
		my $lim = $W;
		if ( $w >= $lim) {
			my $leftw = 0; #DefArrowX;
#			$leftw += DefArrowX if $self-> {arrows} & 1;
			$leftw = $W - $leftw;
			$leftw -= $$ww[$ti] if $moreThanOne;
			$w = 0;
			for ( $i = $ti; $i >= 0; $i--) {
				$w += $$ww[$i];
				last if $w > $leftw;
			}
			return $i + 1;
		}
	} elsif ( $ti < $self-> {firstTab}) {
		return $ti;
	}
	return undef;
}

#-----------------------------------------------------------------------------------

sub set_tab_index
{
	my ( $self, $ti) = @_;

	$ti = 0 if $ti < 0;
	my $mx = scalar @{$self-> {tabs}} - 1;
	$ti = $mx if $ti > $mx;
	return if $ti == $self-> {tabIndex};

	$self-> {tabIndex} = $ti;
	$self-> {focusedTab} = $ti;
	my $newFirstTab = $self-> tab2firstTab( $ti);

	defined $newFirstTab ?
		$self-> firstTab( $newFirstTab) :
		$self-> repaint;
	$self-> notify(q(Change));
}

#-----------------------------------------------------------------------------------

sub set_first_tab
{
	my ( $self, $ft) = @_;
return;#wb
	$ft = 0 if $ft < 0;
	unless ( $self-> {arrows}) {
		$ft = 0;
	} else {
		my $w = 0;
#		$w += DefArrowX if $ft > 0;
		my $haveRight = 0;
		my $i;
		my @size = $self-> size;
		for ( $i = $ft; $i < scalar @{$self-> {widths}}; $i++) {
			$w += $self-> {widths}-> [$i];
			$haveRight = 1, last if $w >= $size[0];
		}
		unless ( $haveRight) {
			$w += 0;
			for ( $i = $ft - 1; $i >= 0; $i--) {
				$w += $self-> {widths}-> [$i];
				if ( $w >= $size[0]) {
					$i++;
					$ft = $i if $ft > $i;
					last;
				}
			}
		}
	}
	return if $self-> {firstTab} == $ft;
	$self-> {firstTab} = $ft;
	$self-> reset;
	$self-> repaint;
}

#-----------------------------------------------------------------------------------

sub set_focused_tab
{
	my ( $self, $ft) = @_;
	$ft = 0 if $ft < 0;
	my $mx = scalar @{$self-> {tabs}} - 1;
	$ft = $mx if $ft > $mx;
	$self-> {focusedTab} = $ft;

	my $newFirstTab = $self-> tab2firstTab( $ft);
	defined $newFirstTab ?
		$self-> firstTab( $newFirstTab) :
		( $self-> focused ? $self-> repaint : 0);
}

#-----------------------------------------------------------------------------------

sub set_tabs
{
	my $self = shift;
	my @tabs = ( scalar @_ == 1 && ref( $_[0]) eq q(ARRAY)) ? @{$_[0]} : @_;
	$self-> {tabs} = \@tabs;
	$self-> recalc_widths;
	$self-> reset;
	$self-> lock;
	$self-> firstTab( $self-> firstTab);
	$self-> tabIndex( $self-> tabIndex);
	$self-> unlock;
	$self-> update_view;
}

#-----------------------------------------------------------------------------------

sub set_top_most
{
	my ( $self, $tm) = @_;
	return if $tm == $self-> {topMost};
	$self-> {topMost} = $tm;
	$self-> repaint;
}

#-----------------------------------------------------------------------------------

sub colored      {($#_)?($_[0]-> {colored}=$_[1],$_[0]-> repaint)        :return $_[0]-> {colored}}
sub focusedTab   {($#_)?($_[0]-> set_focused_tab(    $_[1]))             :return $_[0]-> {focusedTab}}
sub firstTab     {($#_)?($_[0]-> set_first_tab(    $_[1]))               :return $_[0]-> {firstTab}}
sub tabIndex     {($#_)?($_[0]-> set_tab_index(    $_[1]))               :return $_[0]-> {tabIndex}}
sub topMost      {($#_)?($_[0]-> set_top_most (    $_[1]))               :return $_[0]-> {topMost}}
sub tabs         {($#_)?(shift-> set_tabs     (    @_   ))               :return $_[0]-> {tabs}}

################################################################################

package Prima::CodeManager::Notebook;
use vars qw(@ISA);
@ISA = qw(Prima::Widget);

sub profile_default
{
	my $def = $_[ 0]-> SUPER::profile_default;
	my %prf = (
		defaultInsertPage => undef,
		pageCount         => 0,
		pageIndex         => 0,
		tabStop           => 0,
		ownerBackColor    => 1,
	);
	@$def{keys %prf} = values %prf;
	return $def;
}

#-----------------------------------------------------------------------------------

sub init
{
	my $self = shift;
	$self-> {pageIndex} = -1;
	$self-> {pageCount} = 0;

	my %profile = $self-> SUPER::init(@_);

	$self-> {pageCount} = $profile{pageCount};
	$self-> {pageCount} = 0 if $self-> {pageCount} < 0;
	my $j = $profile{pageCount};
	push (@{$self-> {widgets}},[]) while $j--;
	for ( qw( pageIndex defaultInsertPage)) { $self-> $_( $profile{ $_}); }
	return %profile;
}

#-----------------------------------------------------------------------------------

sub set_page_index
{
	my ( $self, $pi) = @_;
	$pi = 0 if $pi < 0;
	$pi = $self-> {pageCount} - 1 if $pi > $self-> {pageCount} - 1;
	my $sel = $self-> selected;
	return if $pi == $self-> {pageIndex};

	$self-> lock;

	my $cp = $self-> {widgets}-> [$self-> {pageIndex}];
	if ( defined $cp) {
		for ( @$cp) {
			$$_[1] = $$_[0]-> enabled;
			$$_[2] = $$_[0]-> visible;
			$$_[3] = $$_[0]-> current;
			$$_[4] = $$_[0]-> geometry;
			$$_[0]-> visible(0);
			$$_[0]-> enabled(0);
			$$_[0]-> geometry(gt::Default);
		}
	}

	$cp = $self-> {widgets}-> [$pi];
	if ( defined $cp) {
		my $hasSel;
		for ( @$cp) {
			$$_[0]-> geometry($$_[4]);
			$$_[0]-> enabled($$_[1]);
			$$_[0]-> visible($$_[2]);
			if ( !defined $hasSel && $$_[3]) {
				$hasSel = 1;
				$$_[0]-> select if $sel;
			}
			$$_[0]-> current($$_[3]);
		}
	}

	my $i = $self-> {pageIndex};
	$self-> {pageIndex} = $pi;
	$self-> notify(q(Change), $i, $pi);
	$self-> unlock;
	$self-> update_view;
}

#-----------------------------------------------------------------------------------

sub insert_page
{
	my ( $self, $at) = @_;

	$at = -1 unless defined $at;
	$self-> {pageCount} = 0 unless $self-> {pageCount};
	$at = $self-> {pageCount} if $at < 0 || $at > $self-> {pageCount};

	splice( @{$self-> {widgets}}, $at, 0, []);
	$self-> {pageCount}++;
	$self-> pageIndex(0) if $self-> {pageCount} == 1;
}

#-----------------------------------------------------------------------------------

sub delete_page
{
	my ( $self, $at, $removeChildren) = @_;

	$removeChildren = 1 unless defined $removeChildren;
	$at = -1 unless defined $at;
	$at = $self-> {pageCount} - 1 if $at < 0 || $at >= $self-> {pageCount};

	my @r = splice( @{$self-> {widgets}}, $at, 1);

	$self-> {pageCount}--;
	$self-> pageIndex( $self-> pageIndex);

	if ( $removeChildren) {
		$$_[0]-> destroy for @{$r[0]};
	}
}

#-----------------------------------------------------------------------------------

sub attach_to_page
{
	my $self  = shift;
	my $page  = shift;

	$self-> insert_page if $self-> {pageCount} == 0;
	$page = $self-> {pageCount} - 1 if $page > $self-> {pageCount} - 1 || $page < 0;
	my $cp = $self-> {widgets}-> [$page];

	for ( @_) {
		next unless $_-> isa('Prima::Widget');
		# $_->add_notification( Enable  => \&_enable  => $self);
		# $_->add_notification( Disable => \&_disable => $self);
		# $_->add_notification( Show    => \&_show    => $self);
		# $_->add_notification( Hide    => \&_hide    => $self);
		my @rec = ( $_, $_-> enabled, $_-> visible, $_-> current, $_-> geometry);
		push( @{$cp}, [@rec]);
		next if $page == $self-> {pageIndex};
		$_-> visible(0);
		$_-> autoEnableChildren(0);
		$_-> enabled(0);
		$_-> geometry(gt::Default);
	}
}

#-----------------------------------------------------------------------------------

sub insert
{
	my $self = shift;
	my $page = defined $self-> {defaultInsertPage} ?

		$self-> {defaultInsertPage} :

		$self-> pageIndex;

	return $self-> insert_to_page( $page, @_);
}

#-----------------------------------------------------------------------------------

sub insert_to_page
{
	my $self  = shift;
	my $page  = shift;
	my $sel   = $self-> selected;
	$page = $self-> {pageCount} - 1 if $page > $self-> {pageCount} - 1 || $page < 0;

	$self-> lock;
	my @ctrls = $self-> SUPER::insert( @_);

	$self-> attach_to_page( $page, @ctrls);
	$ctrls[0]-> select if $sel && scalar @ctrls && $page == $self-> {pageIndex} &&

		$ctrls[0]-> isa('Prima::Widget');
	$self-> unlock;

	return wantarray ? @ctrls : $ctrls[0];
}

#-----------------------------------------------------------------------------------

sub insert_transparent
{
	shift-> SUPER::insert( @_);
}

#-----------------------------------------------------------------------------------

sub contains_widget
{
	my ( $self, $ctrl) = @_;
	my $i;
	my $j;
	my $cptr = $self-> {widgets};

	for ( $i = 0; $i < $self-> {pageCount}; $i++) {
		my $cp = $$cptr[$i];
		my $j = 0;
		for ( @$cp) {
			return ( $i, $j) if $$_[0] == $ctrl;
			$j++;
		}
	}
	return;
}

#-----------------------------------------------------------------------------------

sub widgets_from_page
{
	my ( $self, $page) = @_;
	return if $page < 0 or $page >= $self-> {pageCount};

	my @r;
	push( @r, $$_[0]) for @{$self-> {widgets}-> [$page]};
	return @r;
}

#-----------------------------------------------------------------------------------

sub on_childleave
{
	my ( $self, $widget) = @_;
	$self-> detach_from_page( $widget);
}

#-----------------------------------------------------------------------------------

sub detach_from_page
{
	my ( $self, $ctrl)   = @_;
	my ( $page, $number) = $self-> contains_widget( $ctrl);
	return unless defined $page;
	splice( @{$self-> {widgets}-> [$page]}, $number, 1);
}

#-----------------------------------------------------------------------------------

sub delete_widget
{
	my ( $self, $ctrl)   = @_;
	my ( $page, $number) = $self-> contains_widget( $ctrl);
	return unless defined $page;
	$ctrl-> destroy;
}

#-----------------------------------------------------------------------------------

sub move_widget
{
	my ( $self, $widget, $newPage) = @_;
	my ( $page, $number) = $self-> contains_widget( $widget);
	return unless defined $page;

	my @prev_widgets = @{$self-> {widgets}-> [$newPage]};

	@{$self-> {widgets}-> [$newPage]} = ( @prev_widgets, splice( @{$self-> {widgets}-> [$page]}, $number, 1));

#	@{$self-> {widgets}-> [$newPage]} = splice( @{$self-> {widgets}-> [$page]}, $number, 1);
	$self-> repaint if $self-> {pageIndex} == $page || $self-> {pageIndex} == $newPage;
}

#-----------------------------------------------------------------------------------

sub replace_pages
{
	my ( $self, $oldPage, $newPage) = @_;
	$oldPage = 0 unless $oldPage; $oldPage = $self-> {pageCount} - 1 if $oldPage >= $self-> {pageCount};

	$newPage = 0 unless $newPage; $newPage = $self-> {pageCount} - 1 if $newPage >= $self-> {pageCount};

	return if $oldPage == $newPage;

	if ( $oldPage > $newPage ) { my $tmp = $newPage; $newPage = $oldPage; $oldPage = $tmp; }

	my @r = splice( @{$self-> {widgets}}, $oldPage, 1, $self-> {widgets}-> [$newPage]);

#	$self-> delete_widget ( $_ ) for $self-> widgets_from_page($oldPage);
#	$self-> move_widget ( $_,$oldPage ) for $self-> widgets_from_page($newPage);

#	my @tmp_widgets = @{$self-> {widgets}-> [$oldPage]};
#	@{$self-> {widgets}-> [$oldPage]} = @{$self-> {widgets}-> [$newPage]};
#	@{$self-> {widgets}-> [$newPage]} = @tmp_widgets;

#	$self-> delete_widget ( $_ ) for $self-> widgets_from_page($newPage);
#	for ( my $i = 0; $i < scalar @tmp_widgets; $i++ ) {
#		${$self-> {widgets}-> [$newPage]}[0] = $tmp_widgets[$i];
#	}

#	for ( $self-> widgets_from_page( $oldPage ) ) {
#		$self-> widget_set ( $_, visible => 1, autoEnableChildren => 1, enabled => 1, geometry => gt::Default, );
#	}
#	for ( $self-> widgets_from_page( $newPage ) ) {
#		$self-> widget_set ( $_, visible => 1, autoEnableChildren => 1, enabled => 1, geometry => gt::Default, );
#	}

	$self-> repaint if $self-> {pageIndex} == $oldPage || $self-> {pageIndex} == $newPage;
}

#-----------------------------------------------------------------------------------

sub set_page_count
{
	my ( $self, $pageCount) = @_;
	$pageCount = 0 if $pageCount < 0;
	return if $pageCount == $self-> {pageCount};

	if ( $pageCount < $self-> {pageCount}) {
		splice(@{$self-> {widgets}}, $pageCount);
		$self-> {pageCount} = $pageCount;
		$self-> pageIndex($pageCount - 1) if $self-> {pageIndex} < $pageCount - 1;
	} else {
		my $i = $pageCount - $self-> {pageCount};
		push (@{$self-> {widgets}},[]) while $i--;
		$self-> {pageCount} = $pageCount;
		$self-> pageIndex(0) if $self-> {pageIndex} < 0;
	}
}

#-----------------------------------------------------------------------------------

my %virtual_properties = (
	enabled => 1,
	visible => 2,
	current => 3,
	geometry => 4,
);

#-----------------------------------------------------------------------------------

sub widget_get
{
	my ( $self, $widget, $property) = @_;
	return $widget-> $property() if ! $virtual_properties{$property};

	my ( $page, $number) = $self-> contains_widget( $widget);
	return $widget-> $property()

		if ! defined $page || $page == $self-> {pageIndex};

	return $self-> {widgets}-> [$page]-> [$number]-> [$virtual_properties{$property}];
}

#-----------------------------------------------------------------------------------

sub widget_set
{
	my ( $self, $widget) = ( shift, shift );
	my ( $page, $number) = $self-> contains_widget( $widget);

	if ( ! defined $page || $page == $self-> {pageIndex} ) {
		$widget-> set( @_ );
		return;
	}
	$number = $self-> {widgets}-> [$page]-> [$number];
	my %profile;
	my $clear_current_flag = 0;

	while ( @_ ) {
		my ( $property, $value) = ( shift, shift );
		if ( $virtual_properties{$property} ) {
			$number-> [ $virtual_properties{ $property } ] = ( $value ? 1 : 0 );
			$clear_current_flag = 1 if $property eq 'current' && $value;
		} else {
			$profile{$property} = $value;
		}
	}

	if ( $clear_current_flag) {
		for ( @{$self-> {widgets}-> [$page]} ) {
			$$_[3] = 0 if $$_[0] != $widget;
		}
	}
	$widget-> set( %profile ) if scalar keys %profile;
}

#-----------------------------------------------------------------------------------

sub defaultInsertPage
{
	$_[0]-> {defaultInsertPage} = $_[1];
}

#-----------------------------------------------------------------------------------

sub pageIndex     {($#_)?($_[0]-> set_page_index   ( $_[1]))    :return $_[0]-> {pageIndex}}
sub pageCount     {($#_)?($_[0]-> set_page_count   ( $_[1]))    :return $_[0]-> {pageCount}}

################################################################################
# TabbedNotebook styles
package tns;
use constant Simple   => 0;
use constant Standard => 1;

################################################################################
# TabbedNotebook orientations
package tno;
use constant Top    => 0;
use constant Bottom => 1;

################################################################################
package Prima::CodeManager::TabbedNotebook;
use vars qw(@ISA %notebookProps);
@ISA = qw(Prima::Widget Prima::CodeManager::Notebook);

use constant DefBorderX		=>	10;
use constant DefBookmarkX	=>	30;
use constant DefTabMultiply	=>	1.4;

%notebookProps = (
	pageCount      => 1, defaultInsertPage=> 1,
	attach_to_page => 1, insert_to_page   => 1, insert         => 1, insert_transparent => 1,
	delete_widget  => 1, detach_from_page => 1, move_widget    => 1, contains_widget    => 1,
	widget_get     => 1, widget_set       => 1, widgets_from_page => 1,
);

for ( keys %notebookProps) {
	eval <<GENPROC;
   sub $_ { return shift-> {notebook}-> $_(\@_); }
GENPROC
}

#-----------------------------------------------------------------------------------

sub profile_default
{
	return {
		%{Prima::CodeManager::Notebook-> profile_default},
		%{$_[ 0]-> SUPER::profile_default},
#		ownerBackColor      => 0,
		ownerBackColor      => 1,
		tabs                => [],
		tabIndex            => 0,
		style               => tns::Standard,
		orientation         => tno::Top,
		tabsetClass         => 'Prima::CodeManager::TabSet',
		tabsetProfile       => {},
		tabsetDelegations   => ['Change'],
		notebookClass       => 'Prima::CodeManager::Notebook',
		notebookProfile     => {},
		notebookDelegations => ['Change'],
	}
}

#-----------------------------------------------------------------------------------

sub init
{
	my $self = shift;
	my %profile = @_;

	my $visible       = $profile{visible};
	my $scaleChildren = $profile{scaleChildren};
	$profile{visible} = 0;
	$self-> {style}    = tns::Standard;
	$self-> {orientation} = tno::Top;
	$self-> {tabs}     = [];

	%profile = $self-> SUPER::init(%profile);

	my @size = $self-> size;
	my $maxh = $self-> font-> height * 2;

	$self-> {tabSet} = $profile{tabsetClass}-> create(
		owner     => $self,
		name      => 'TabSet',
		left      => 0,
		width     => $size[0],
		top       => $size[1],
		growMode  => gm::Ceiling,
		height    => 2 * int (DefTabMultiply * $self-> font-> height),
		buffered  => 1,
#		backColor=>0xff0000,
		designScale => undef,
		delegations => $profile{tabsetDelegations},
		%{$profile{tabsetProfile}},
	);

	$self-> {notebook} = $profile{notebookClass}-> create(
		owner      => $self,
		name       => 'Notebook',
		origin     => [ DefBorderX + 1, DefBorderX + 1],
		size       => [
			$size[0] - DefBorderX * 2 - 1,
			$size[1] - DefBorderX * 2 - $self-> {tabSet}-> height - DefBookmarkX - 4
		],
		growMode   => gm::Client,
#		backColor=>0xff0000,
		scaleChildren => $scaleChildren,
		(map { $_  => $profile{$_}} keys %notebookProps),
		designScale => undef,
		pageCount  => scalar @{$profile{tabs}},
		delegations => $profile{notebookDelegations},
		%{$profile{notebookProfile}},
	);
	$self-> {notebook}-> designScale( $self-> designScale); # propagate designScale
	$self-> tabs( $profile{tabs});
	$self-> pageIndex( $profile{pageIndex});
	$self-> style($profile{style});
	$self-> orientation($profile{orientation});
	$self-> visible( $visible);

	return %profile;
}

#-----------------------------------------------------------------------------------

sub Notebook_Change
{
	my ( $self, $book) = @_;
	return if $self-> {changeLock};
	$self-> pageIndex( $book-> pageIndex);
}

#-----------------------------------------------------------------------------------

sub on_paint
{
	my ($self,$canvas)	=	@_;

	my @clr  = ( $self-> color, $self-> backColor);
	   @clr  = ( $self-> disabledColor, $self-> disabledBackColor) if ( !$self-> enabled);
	my @c3d  = ( $self-> dark3DColor, $self-> light3DColor);
	my @size = $canvas-> size;
	my $on_top = ($self-> {orientation} == tno::Top);
	$canvas-> color( $clr[1]);
	$canvas-> bar( 0, 0, @size);

	if ($self-> {style} == tns::Standard) {

		$size[1] -= $self-> {tabSet}-> height;

		$canvas-> rect3d(
			0,				0,
			$size[0] - 1,	$size[1],
			1,
			reverse @c3d
		);
		$canvas-> rect3d(
			DefBorderX,					DefBorderX,
			$size[0] - 1 - DefBorderX,	$size[1] - 1 - DefBorderX,
			1,
			@c3d
		);

		my $y = $size[1] - DefBorderX;
		my $x = $size[0] - DefBorderX - DefBookmarkX;
		return if $y < DefBorderX * 2 + DefBookmarkX;

		$canvas-> color( $c3d[0]);

		$canvas-> line( DefBorderX+1, $y - DefBookmarkX - 3, $size[0] - 2 - DefBorderX, $y - DefBookmarkX - 3 );

		my $fh = 24;
		my $a  = 0;
		my ($pi, $mpi) = (
			$self-> {notebook}-> pageIndex,
			$self-> {notebook}-> pageCount - 1
		);

		$a |= 1 if $pi > 0;
		$a |= 2 if $pi < $mpi;

		my $t = $self-> {tabs};
		if ( scalar @{$t}) {

			my $tx = $self-> {tabSet}-> tabIndex;
			my $t1 = $$t[ $tx * 2];
			my $yh = $y - $fh * 0.8 - $self-> font-> height / 2;
#			$canvas-> clipRect( DefBorderX + 1, $y - $fh * 1.6 + 1, $x - 4 + 10, $y - 2);

			$canvas-> color( $clr[0]);
			$canvas-> set( font => { size   => 1.2 * $self-> font->size });
			$canvas-> text_out( ' '.$t1, DefBorderX + 4, $yh );

			if ( $$t[ $tx * 2 + 1] > 0 ) {
				$t1 = sprintf( "Page %d of %d ", $self-> pageIndex + 1, $self-> pageCount );
				my $tl1 = $size[0] - DefBorderX - 3 - DefBookmarkX - $self-> get_text_width( $t1);
				$canvas-> text_out( $t1, $tl1, $yh ) if $tl1 > 4 + DefBorderX + $fh * 3;
			}
		}

#--------------
		$canvas-> color ($c3d[0]);
		my $dx = DefBookmarkX / 2;
		my ( $x1, $y1) = ( $x + $dx, $y - $dx);

		if ( $a & 1 ) {
			$canvas-> polyline([
				$x - 1,					$y - 4,
				$x - 1,					$y - DefBookmarkX,
				$x - 5 + DefBookmarkX,	$y - DefBookmarkX,
				$x - 1,					$y - 4,
			]);
			$canvas-> polyline([
				$x +  3, $y - DefBookmarkX +  7,
				$x + 13, $y - DefBookmarkX +  7,
				$x + 13, $y - DefBookmarkX +  9,
				$x +  3, $y - DefBookmarkX +  9,
				$x +  3, $y - DefBookmarkX +  7,
			]);
		}

		if ( $a & 2 ) {
			$canvas-> polyline([
				$x - 5 + DefBookmarkX,	$y - DefBookmarkX,
				$x - 1,					$y - 4,
				$x - 5 + DefBookmarkX,	$y - 4,
				$x - 5 + DefBookmarkX,	$y - DefBookmarkX,
			]);
			$canvas-> polyline([
				$x1 - 2, $y1 + 3,

				$x1 - 2, $y1 + 5,
				$x1 + 2, $y1 + 5,

				$x1 + 2, $y1 + 9,

				$x1 + 4, $y1 + 9,
				$x1 + 4, $y1 + 5,
				$x1 + 8, $y1 + 5,
				$x1 + 8, $y1 + 3,
				$x1 + 4, $y1 + 3,
				$x1 + 4, $y1 - 1,
				$x1 + 2, $y1 - 1,
				$x1 + 2, $y1 + 3,
				$x1 - 2, $y1 + 3,
			]);
		}

	} else {

		# tns::Simple
#		$canvas-> rect3d(0, 0, $size[0]-1, $size[1]-1, 1, reverse @c3d);
	}
}

#-----------------------------------------------------------------------------------

sub event_in_page_flipper
{
	my ( $self, $x, $y) = @_;
	return if $self-> {style} != tns::Standard;
#return;

	my @size = $self-> size;
#	my $th = ($self-> {orientation} == tno::Top) ? $self-> {tabSet}-> height : 5;
	my $th = $self-> {tabSet}-> height;

	$x -= $size[0] - DefBorderX - DefBookmarkX - 1 - 8;
	$y -= $size[1] - DefBorderX - $th - DefBookmarkX + 4 - 10;
#	$y -= $size[1] - DefBorderX - 4;

	return if $x < 0 || $x > DefBookmarkX || $y < 0 || $y > DefBookmarkX;

	return ( $x, $y);
}

#-----------------------------------------------------------------------------------

sub on_mousedown
{
	my ( $self, $btn, $mod, $x, $y) = @_;
	$self-> clear_event;
	return unless ( $x, $y) = $self-> event_in_page_flipper( $x, $y);
	$self-> pageIndex( $self-> pageIndex + (( -$x + DefBookmarkX < $y) ? 1 : -1));
}

#-----------------------------------------------------------------------------------

sub on_mousewheel
{
	my ( $self, $mod, $x, $y, $z) = @_;
	$self-> clear_event;
	return unless ( $x, $y) = $self-> event_in_page_flipper( $x, $y);
	$self-> pageIndex( $self-> pageIndex + (( $z < 0) ? -1 : 1));
}

#-----------------------------------------------------------------------------------

sub on_mouseclick
{
	my $self = shift;
	$self-> clear_event;
	return unless pop;
	$self-> clear_event unless $self-> notify( "MouseDown", @_);
}

#-----------------------------------------------------------------------------------

sub page2tab
{
	my ( $self, $index) = @_;
	my $t = $self-> {tabs};
	return 0 unless scalar @$t;
	my $i = $$t[1] - 1;
	my $j = 0;
	while( $i < $index) {
		$j++;
		$i += $$t[ $j*2 + 1];
	}
	return $j;
}

#-----------------------------------------------------------------------------------

sub tab2page
{
	my ( $self, $index) = @_;
	my $t = $self-> {tabs};
	my $i;
	my $j = 0;
	for ( $i = 0; $i < $index; $i++) { $j += $$t[ $i * 2 + 1]; }
	return $j;
}

#-----------------------------------------------------------------------------------

sub TabSet_Change
{
	my ( $self, $tabset) = @_;
	return if $self-> {changeLock};
	$self-> pageIndex( $self-> tab2page( $tabset-> tabIndex));
}

#-----------------------------------------------------------------------------------

sub set_tabs
{
	my $self = shift;
	my @tabs = ( scalar @_ == 1 && ref( $_[0]) eq q(ARRAY)) ? @{$_[0]} : @_;
	my @nTabs;
	my @loc;
	my $prev  = undef;
	for ( @tabs) {
		if ( defined $prev && $_ eq $prev) {
			$loc[-1]++;
		} else {
			push( @loc,   $_);
			push( @loc,   1);
			push( @nTabs, $_);
		}
		$prev = $_;
	}
	my $pages = $self-> {notebook}-> pageCount;
	$self-> {tabs} = \@loc;
	$self-> {tabSet}-> tabs( \@nTabs);
	my $i;
	if ( $pages > scalar @tabs) {
		for ( $i = scalar @tabs; $i < $pages; $i++) {
			$self-> {notebook}-> delete_page( $i);
		}
	} elsif ( $pages < scalar @tabs) {
		for ( $i = $pages; $i < scalar @tabs; $i++) {
			$self-> {notebook}-> insert_page;
		}
	}
}

#-----------------------------------------------------------------------------------

sub get_tabs
{
	my $self = $_[0];
	my $i;
	my $t = $self-> {tabs};
	my @ret;
	for ( $i = 0; $i < scalar @{$t} / 2; $i++) {
		my $j;
		for ( $j = 0; $j < $$t[$i*2+1]; $j++) { push( @ret, $$t[$i*2]); }
	}
	return \@ret;
}

#-----------------------------------------------------------------------------------

sub set_page_index
{
	my ( $self, $pi) = @_;

	my ($pix, $mpi) = ( $self-> {notebook}-> pageIndex, $self-> {notebook}-> pageCount - 1);
	$self-> {changeLock} = 1;
	$self-> {notebook}-> pageIndex( $pi);
	$self-> {tabSet}-> tabIndex( $self-> page2tab( $self-> {notebook}-> pageIndex));
	delete $self-> {changeLock};

	my @size = $self-> size;
	my $th   = $self-> {tabSet}-> height;
	my $a  = 0;
	$a |= 1 if $pix > 0;
	$a |= 2 if $pix < $mpi;
	my $newA = 0;
	$pi = $self-> {notebook}-> pageIndex;
	$newA |= 1 if $pi > 0;
	$newA |= 2 if $pi < $mpi;

	$self-> invalidate_rect (
		DefBorderX + 1,

		$size[1] - DefBorderX - $th - DefBookmarkX - 1,
		$size[0] - DefBorderX - (( $a == $newA) ? DefBookmarkX + 2 : 0),
		$size[1] - DefBorderX - $th + 3
	);

	$self-> notify(q(Change), $pix, $pi);
}

#-----------------------------------------------------------------------------------

sub orientation

{
	my ($self, $tno) = @_;
	return $self-> {orientation} unless (defined $tno);

	$self-> {orientation} = $tno;
	$self-> {tabSet}-> topMost($tno == tno::Top);
	$self-> {tabSet}-> growMode(($tno == tno::Top) ? gm::Ceiling : gm::Floor);
	$self-> adjust_widgets;

	return $tno;
}

#-----------------------------------------------------------------------------------

sub style

{
	my ($self, $style) = @_;
	return $self-> {style} unless (defined $style);

	$self-> {style} = $style;
	$self-> adjust_widgets;

	return $style;
}

#-----------------------------------------------------------------------------------

sub adjust_widgets

{
	my ($self) = @_;
	my $nb = $self-> {notebook};
	my $ts = $self-> {tabSet};

	my @size = $self-> size;
	my @pos = (0,0);

	$size[1] -= $ts-> height;
	if ($self-> {style} == tns::Standard) {

		$size[0] -= 2 * DefBorderX + 2;
		$size[1] -= 2 * DefBorderX + DefBookmarkX + 4;
		$pos[0] += DefBorderX + 1;
		$pos[1] += DefBorderX + 1;

	} else {

		$size[0] -= 2;
		$size[1] -= 2;
		$pos[0]++;
		$pos[1]++;
	}

	if ($self-> {orientation} == tno::Top) {

		$ts-> top($self-> height);

	} else {

		$ts-> bottom(0);
		$pos[1] += $ts-> height - 5;
	}

	$nb-> size(@size);
	$nb-> origin(@pos);

	$self-> repaint;
}

#-----------------------------------------------------------------------------------

sub tabIndex     {($#_)?($_[0]-> {tabSet}-> tabIndex( $_[1]))  :return $_[0]-> {tabSet}-> tabIndex}
sub pageIndex    {($#_)?($_[0]-> set_page_index   ( $_[1]))    :return $_[0]-> {notebook}-> pageIndex}
sub tabs         {($#_)?(shift-> set_tabs     (    @_   ))     :return $_[0]-> get_tabs}

################################################################################
package Prima::CodeManager::ScrollNotebook::Client;
use vars qw(@ISA);
@ISA = qw(Prima::CodeManager::Notebook);

sub profile_default
{
	my $def = $_[0]-> SUPER::profile_default;
	my %prf = (
		geometry  => gt::Pack,
		packInfo  => { expand => 1, fill => 'both'},
	);
	@$def{keys %prf} = values %prf;

	return $def;
}

#-----------------------------------------------------------------------------------

sub geomSize
{
	return $_[0]-> SUPER::geomSize unless $#_;

	my $self = shift;
	$self-> SUPER::geomSize( @_);
	$self-> owner-> owner-> ClientWindow_geomSize( $self, @_);
}

################################################################################
package Prima::CodeManager::ScrollNotebook;
use vars qw(@ISA);
@ISA = qw(Prima::ScrollGroup);

for ( qw(pageIndex insert_page delete_page),

		keys %Prima::CodeManager::TabbedNotebook::notebookProps) {
		eval <<GENPROC;
	sub $_ { return shift-> {client}-> $_(\@_); }
GENPROC
}

sub profile_default
{
	return {
		%{Prima::CodeManager::Notebook-> profile_default},
		%{$_[ 0]-> SUPER::profile_default},
		clientClass  => 'Prima::CodeManager::ScrollNotebook::Client',
	}
}

################################################################################
package Prima::CodeManager::TabbedScrollNotebook::Client;
use vars qw(@ISA);
@ISA = qw(Prima::CodeManager::ScrollNotebook);

sub update_geom_size
{
	my ( $self, $x, $y) = @_;
	my $owner = $self-> owner;
	return unless $owner-> packPropagate;
	my @o = $owner-> size;
	my @s = $self-> get_virtual_size;
	$owner-> geomSize( $o[0] - $s[0] + $x, $o[1] - $s[1] + $y);
}

################################################################################
package Prima::CodeManager::TabbedScrollNotebook;
use vars qw(@ISA);
@ISA = qw(Prima::CodeManager::TabbedNotebook);

sub profile_default
{
	return {
		%{$_[ 0]-> SUPER::profile_default},

		notebookClass => 'Prima::CodeManager::TabbedScrollNotebook::Client',
		clientProfile => {},
		clientDelegations => [],
		clientSize    => [ 100, 100],
	}
}

#-----------------------------------------------------------------------------------

sub profile_check_in
{
	my ( $self, $p, $default) = @_;
	$self-> SUPER::profile_check_in( $p, $default);
	$p-> {notebookProfile}-> {clientSize} = $p-> {clientSize}
		if exists $p-> {clientSize} and not exists $p-> {notebookProfile}-> {clientSize};
	if ( exists $p-> {clientProfile}) {
		%{$p-> {notebookProfile}-> {clientProfile}} = (
			($default-> {notebookProfile}-> {clientProfile} ?
				%{$default-> {notebookProfile}-> {clientProfile}} : ()),
			%{$p-> {clientProfile}},
		);
	}
	if ( exists $p-> {clientDelegations}) {
		@{$p-> {notebookProfile}-> {clientDelegations}} = (
			( $default-> {notebookProfile}-> {clientDelegations} ?
				@{$default-> {notebookProfile}-> {clientDelegations}} : ()),
			@{$p-> {clientDelegations}},
		);
	}
}

#-----------------------------------------------------------------------------------

sub client { shift-> {notebook}-> client }

#-----------------------------------------------------------------------------------

sub packPropagate
{
	return shift-> SUPER::packPropagate unless $#_;
	my ( $self, $pack_propagate) = @_;
	$self-> SUPER::packPropagate( $pack_propagate);
	$self-> propagate_size if $pack_propagate;
}

#-----------------------------------------------------------------------------------

sub propagate_size
{
	my $self = $_[0];
	$self-> {notebook}-> propagate_size
		if $self-> {notebook};
}

#-----------------------------------------------------------------------------------

sub clientSize
{
	return $_[0]-> {notebook}-> clientSize unless $#_;
	shift-> {notebook}-> clientSize(@_);
}

#-----------------------------------------------------------------------------------

sub use_current_size
{
	$_[0]-> {notebook}-> use_current_size;
}

#-----------------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Prima::CodeManager::Notebooks - multipage widgets

=head1 DESCRIPTION

This is intesively modified the original Prima::Notebooks module.
Please see details there: L<Prima::Notebooks>.

=head1 AUTHOR OF MODIFICATIONS

Waldemar Biernacki, E<lt>wb@sao.plE<gt>

=head1 COPYRIGHT AND LICENSE OF THE FILE MODIFICATIONS

Copyright 2009-2012 by Waldemar Biernacki.

L<http://CodeManager.sao.pl>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
