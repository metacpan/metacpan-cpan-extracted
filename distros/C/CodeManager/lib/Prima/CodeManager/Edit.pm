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
# Last modified (DMYhms): 14-01-2013 07:15:21.
################################################################################

use strict;
use warnings;

package bt;
use constant CUA          =>  0;
use constant Vertical     =>  1;
use constant Horizontal   =>  2;

package Prima::CodeManager::Edit;
use vars qw(@ISA);
@ISA = qw(Prima::Widget Prima::MouseScroller Prima::GroupScroller);

use Prima::Const;
use Prima::Classes;
use Prima::ScrollBar;
use Prima::IntUtils;

{
	my %RNT = (
		%{Prima::Widget-> notification_types()},
		ParseSyntax   => nt::Action,
	);

	sub notification_types { return \%RNT; }
}

#-------------------------------------------------------------------------------

sub profile_default
{
	my %def = %{$_[ 0]-> SUPER::profile_default};
	my $font = $_[ 0]-> get_default_font;

	return {
		%def,
		accelItems => [
# navigation
			[ CursorDown   => 0, 0, kb::Down                , sub{$_[0]-> cursor_down}],
			[ CursorUp     => 0, 0, kb::Up                  , sub{$_[0]-> cursor_up}],
			[ CursorLeft   => 0, 0, kb::Left                , sub{$_[0]-> cursor_left}],
			[ CursorRight  => 0, 0, kb::Right               , sub{$_[0]-> cursor_right}],
			[ PageUp       => 0, 0, kb::PgUp                , sub{$_[0]-> cursor_pgup}],
			[ PageDown     => 0, 0, kb::PgDn                , sub{$_[0]-> cursor_pgdn}],
			[ Home         => 0, 0, kb::Home                , sub{$_[0]-> cursor_home}],
			[ End          => 0, 0, kb::End                 , sub{$_[0]-> cursor_end}],
			[ CtrlPageUp   => 0, 0, kb::PgUp|km::Ctrl       , sub{$_[0]-> cursor_cpgup}],
			[ CtrlPageDown => 0, 0, kb::PgDn|km::Ctrl       , sub{$_[0]-> cursor_cpgdn}],
			[ CtrlHome     => 0, 0, kb::Home|km::Ctrl       , sub{$_[0]-> cursor_chome}],
			[ CtrlEnd      => 0, 0, kb::End |km::Ctrl       , sub{$_[0]-> cursor_cend}],
			[ WordLeft     => 0, 0, kb::Left |km::Ctrl      , sub{$_[0]-> word_left}],
			[ WordRight    => 0, 0, kb::Right|km::Ctrl      , sub{$_[0]-> word_right}],
			[ ShiftCursorDown   => 0, 0, km::Shift|kb::Down                , q(cursor_shift_key)],
			[ ShiftCursorUp     => 0, 0, km::Shift|kb::Up                  , q(cursor_shift_key)],
			[ ShiftCursorLeft   => 0, 0, km::Shift|kb::Left                , q(cursor_shift_key)],
			[ ShiftCursorRight  => 0, 0, km::Shift|kb::Right               , q(cursor_shift_key)],
			[ ShiftPageUp       => 0, 0, km::Shift|kb::PgUp                , q(cursor_shift_key)],
			[ ShiftPageDown     => 0, 0, km::Shift|kb::PgDn                , q(cursor_shift_key)],
			[ ShiftHome         => 0, 0, km::Shift|kb::Home                , q(cursor_shift_key)],
			[ ShiftEnd          => 0, 0, km::Shift|kb::End                 , q(cursor_shift_key)],
			[ ShiftCtrlPageUp   => 0, 0, km::Shift|kb::PgUp|km::Ctrl       , q(cursor_shift_key)],
			[ ShiftCtrlPageDown => 0, 0, km::Shift|kb::PgDn|km::Ctrl       , q(cursor_shift_key)],
			[ ShiftCtrlHome     => 0, 0, km::Shift|kb::Home|km::Ctrl       , q(cursor_shift_key)],
			[ ShiftCtrlEnd      => 0, 0, km::Shift|kb::End |km::Ctrl       , q(cursor_shift_key)],
			[ ShiftWordLeft     => 0, 0, km::Shift|kb::Left |km::Ctrl      , q(cursor_shift_key)],
			[ ShiftWordRight    => 0, 0, km::Shift|kb::Right|km::Ctrl      , q(cursor_shift_key)],
			[ Insert         => 0, 0, kb::Insert , sub {$_[0]-> insertMode(!$_[0]-> insertMode)}],
# edit keys
			[ Delete         => 0, 0, kb::Delete,    sub {
				return if $_[0]-> {readOnly};
				$_[0]-> has_selection ? $_[0]-> delete_block : $_[0]-> delete_char;
			}],
			[ Backspace      => 0, 0, kb::Backspace, sub {$_[0]-> back_char unless $_[0]-> {readOnly}}],
			[ DeleteChunk    => 0, 0, '^Y',          sub {$_[0]-> delete_current_chunk unless $_[0]-> {readOnly}}],
			[ DeleteToEnd    => 0, 0, '^E',          sub {$_[0]-> delete_to_end unless $_[0]-> {readOnly}}],
			[ DupLine        => 0, 0, '^K',          sub {$_[0]-> insert_line($_[0]-> cursorY, $_[0]-> get_line($_[0]-> cursorY)) unless $_[0]-> {readOnly}}],
			[ DeleteBlock    => 0, 0, '@D',          sub {$_[0]-> delete_block unless $_[0]-> {readOnly}}],
			[ SplitLine      => 0, 0, kb::Enter,     sub {$_[0]-> split_line if !$_[0]-> {readOnly} && $_[0]-> {wantReturns}}],
			[ SplitLine2     => 0, 0, km::Ctrl|kb::Enter,sub {$_[0]-> split_line if !$_[0]-> {readOnly} && !$_[0]-> {wantReturns}}],
# block keys
			[ CancelBlock    => 0, 0, '@U',          q(cancel_block)],
			[ MarkVertical   => 0, 0, '@B',          q(mark_vertical)],
			[ MarkHorizontal => 0, 0, '@L',          q(mark_horizontal)],
			[ CopyBlock      => 0, 0, '@C',          q(copy_block)],
			[ OvertypeBlock  => 0, 0, '@O',          q(overtype_block)],
# clipboard keys
			[ Cut            => 0, 0, km::Shift|kb::Delete, q(cut)],
			[ Copy           => 0, 0, km::Ctrl |kb::Insert, q(copy)],
			[ Paste          => 0, 0, km::Shift|kb::Insert, q(paste)],
			[ CutMS          => 0, 0, '^X', q(cut)],
			[ CopyMS         => 0, 0, '^C', q(copy)],
			[ PasteMS        => 0, 0, '^V', q(paste)],
# undo
			[ Undo            => 0, 0, '^Z', q(undo)],
			[ Undo            => 0, 0, km::Alt|kb::Backspace, q(undo)],
#			[ Redo            => 0, 0, '^R', q(redo)],
		],
		autoIndent        => 1,
		autoHScroll       => 1,
		autoVScroll       => 1,
		blockType         => bt::CUA,
		borderWidth       => 1,
		cursorSize        => [ $::application-> get_default_cursor_width, $font-> { height}],
		cursorVisible     => 1,
		cursorX           => 0,
		cursorY           => 0,
		cursorWrap        => 0,
		insertMode        => 0,
		hiliteNumbers     => cl::Green,
		hiliteQStrings    => cl::LightBlue,
		hiliteQQStrings   => cl::LightBlue,
		hiliteIDs         => [[qw(
abs accept alarm atan2 bind binmode bless caller chdir chmod chomp chop chown
chr chroot close closedir connect continue cos crypt defined
delete die do dump each endgrent endhostent endnetent endprotoent endpwent
endservent eof eval exec exists exit exp fcntl fileno flock for fork format
formline getc getgrent getgrgid getgrnam gethostbyaddr gethostbyname gethostent
getlogin getnetbyaddr getnetbyname getnetent getpeername getpgrp getppid
getpriority getprotobyname getprotobynumber getprotoent getpwent getpwnam
getpwuid getservbyname getservbyport getservent getsockname getsockopt glob
gmtime goto grep hex if import index int ioctl join keys kill last lc lcfirst
length link listen local localtime log lstat m map mkdir msgctl msgget msgrcv
msgsnd my next no oct open opendir ord our pack package pipe pop pos print
printf prototype push q qq qr quotemeta qw qx rand read readdir readline
readlink readpipe recv redo ref rename require reset return reverse rewinddir
rindex rmdir s scalar seek seekdir select semctl semget semop send setgrent
sethostent setnetent setpgrp setpriority setprotoent setpwent setservent
setsockopt shift shmctl shmget shmread shmwrite shutdown sin sleep socket
socketpair sort splice split sprintf sqrt srand stat study sub substr symlink
syscall sysopen sysread sysseek system syswrite tell telldir tie tied time
times tr truncate uc ucfirst umask undef unless unlink unpack unshift untie use
utime values vec wait waitpid wantarray warn while write y
		)], cl::Blue, cl::White],
		hiliteChars       => ['~!@#$%^&*()+-=[]{};:\'"\\|?.,<>/`', cl::Blue, cl::White],
		hiliteREs         => [ '(#.*)$', {color => cl::Gray},],
		hiliteCase        => 0,
		hiliteStyl        => 0,
		hiliteBlok        => [],
		hScroll           => 0,
		markers           => [],
		modified          => 0,
		offset            => 0,
		pointerType       => cr::Text,
		persistentBlock   => 0,
		readOnly          => 0,
		selection         => [0, 0, 0, 0],
		selStart          => [0, 0],
		selEnd            => [0, 0],
		selectable        => 1,
		syntaxHilite      => 0,
		tabIndent         => 4,
		textRef           => undef,
		topLine           => 0,
		vScroll           => 0,
		undoLimit         => 1000,
		wantTabs          => 1,
		wantReturns       => 1,
		widgetClass       => wc::Edit,
		wordDelimiters    => ".()\"'\`,$@!%^&*{}[]?/|;:<>-= \xff\t#",
		wordWrap          => 0,

		lineSpace         => 0,
		wheelRows         => 1,
		exportHTML        => 0,
	}
}

#-------------------------------------------------------------------------------

sub profile_check_in
{
	my ( $self, $p, $default) = @_;
	$self-> SUPER::profile_check_in( $p, $default);

	$self->{hiliteCase} = $p->{hiliteCase}; $self->{hiliteCase} += 0;	$self->{hiliteCase} = 0 unless $self->{hiliteCase};
	$self->{hiliteStyl} = $p->{hiliteStyl}; $self->{hiliteStyl} += 0;	$self->{hiliteStyl} = 0 unless $self->{hiliteStyl};
	$self->{hiliteBlok} = $p->{hiliteBlok};	$self->{hiliteBlok}  = [] unless $self->{hiliteBlok};

	$self->{lineSpace}  = $p->{lineSpace} || 0;
	$self->{wheelRows}  = $p->{wheelRows} || 1;
	$self->{exportHTML} = $p->{exportHTML}|| 0;

	if ( exists( $p-> { selection}))
	{
		my $s = $p-> {selection};
		$p-> {selStart} = [$$s[0], $$s[1]];
		$p-> {selEnd  } = [$$s[2], $$s[3]];
	}
	$p-> { text} = '' if exists( $p-> {textRef});
	$p-> {autoHScroll} = 0 if exists $p-> {hScroll};
	$p-> {autoVScroll} = 0 if exists $p-> {vScroll};
}

#-------------------------------------------------------------------------------

sub init
{
	my $self = shift;

	for ( qw( autoIndent topLine  offset resetDisabled blockType persistentBlock
		tabIndent readOnly wantReturns wantTabs
	))
		{ $self-> {$_} = 1; }
	for ( qw( wordWrap hScroll vScroll rows maxLineCount maxLineLength maxLineWidth
		scrollTransaction maxLine maxChunk capLen cursorY cursorX cursorWrap
		cursorXl cursorYl syntaxHilite hiliteNumbers hiliteQStrings hiliteQQStrings
		notifyChangeLock modified borderWidth autoHScroll autoVScroll blockShiftMark
	))
		{ $self-> {$_} = 0;}
	$self-> { insertMode}   = $::application-> insertMode;
	for ( qw( markers lines chunkMap hiliteIDs hiliteChars hiliteREs)) { $self-> {$_} = []}
	for ( qw( selStart selEnd selStartl selEndl)) { $self-> {$_} = [0,0]}
	$self-> {defcw} = $::application-> get_default_cursor_width;
	my %profile = $self-> SUPER::init(@_);
	$self-> setup_indents;
	$self-> {undo} = [];
	$self-> {redo} = [];
	$profile{selection} = [@{$profile{selStart}}, @{$profile{selEnd}}];
	for ( qw( hiliteNumbers hiliteQStrings hiliteQQStrings hiliteIDs hiliteChars hiliteREs
		autoHScroll autoVScroll
		textRef syntaxHilite autoIndent persistentBlock blockType hScroll vScroll borderWidth
		topLine  tabIndent readOnly offset wordDelimiters wantTabs wantReturns
		wordWrap cursorWrap markers undoLimit))
		{ $self-> $_( $profile{ $_}); }
	delete $self-> {resetDisabled};
	$self-> {uChange} = 0;
	$self-> reset;
	$self-> selection( @{$profile{selection}});
	for ( qw( cursorX cursorY))
	{ $self-> $_( $profile{ $_}); }
	$self-> reset_scrolls;
	$self-> {modified} = 0;

	$self-> {hiliteBlok_modified} = 0;
	$self-> area;

	return %profile;
}

#-------------------------------------------------------------------------------

sub area
{
	my ( $self, $it0, $rows ) = ( shift, shift, shift );

	return unless @{$self->{hiliteBlok}};

	$it0  ||= 0;
	$rows ||= scalar @{$self-> {lines}};

	$self->{hiliteBlok_modified} = 0 if $it0 == 0 && $rows == scalar @{$self-> {lines}};

#print "area( $it0 , $rows )\n";

	my $lev = 0;
	$lev = $self->{hiliteBlok_value}->[$it0] if $it0 > 0;

	splice(@{$self->{hiliteBlok_value}},$it0) if $self->{hiliteBlok_value} && @{$self->{hiliteBlok_value}} > $it0;
    my $con = \$self->text;

	my $blok_beg = $self->{hiliteBlok}->[0];
	my $blok_end = $self->{hiliteBlok}->[1];

	for (my $ite = $it0 ; $ite < $it0 + $rows + 2 ; $ite++ ) { #  $$con =~ m/^(.*)$/mg ) {
		my $row = $self-> {lines}->[$ite] || '';
		if ( $row =~ /($blok_beg|$blok_end)/ || $lev ) {
			$lev = 1;
			$self->{hiliteBlok_value}->[$ite] = 1;
		}
		$lev = 0 if $row =~ /$blok_end/;
	}
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

sub reset
{
	my $self = $_[0];
	return if $self-> {resetDisabled};
	my @a    = ( $self-> {indents}-> [0], $self-> {indents}-> [1]);
	my @size = $self-> get_active_area(2);
	my $cw   = $self-> {defcw};
	my $ti   = $self-> {tabIndent};
	my $uC   = $self-> {uChange};
	my $mw;
	$size[0] -= $cw;
	if ( $uC < 2) {
		$self-> {fixed} = $self-> font-> pitch == fp::Fixed;
		$self-> {averageWidth} = $self-> font-> width;
		$mw                    = $self-> {averageWidth};
		$self-> {maxFixedLength} = int( $size[0] / $mw);
		$self-> {tabs} = ' 'x$ti;
	}

# changes that apply to string output must issue recalculation here.
#
# Calculating wrap chunks ( if necessary) and build chunkMap.
# chunkMap is actual only in wordWrap = 1 mode; it maps lines to real lines.
# it's structure is: [ subline offset, subline length, line index].

	if ( $self-> {wordWrap}) {
		if ( $uC < 2) {
			my $twOpts  = tw::WordBreak|tw::CalcTabs|tw::NewLineBreak|tw::ReturnChunks;
			my @chunkMap;
			$self-> begin_paint_info;
			$#chunkMap = scalar @{$self-> {lines}} * 2;
			@chunkMap = ();
			my $j = 0;
			for ( @{$self-> {lines}})
			{
				my $i;
				my $breaks = $self-> text_wrap( $_, $size[0], $twOpts, $ti);
				for ( $i = 0; $i < scalar @{$breaks} / 2; $i++)
				{
				#  push( @chunkMap, $$breaks[$i * 2]);
				#  push( @chunkMap, $$breaks[$i * 2 + 1]);
				#  push( @chunkMap, $j);
					push( @chunkMap, $$breaks[$i * 2], $$breaks[$i * 2 + 1], $j);
				}
				$j++;
			}
			$self-> end_paint_info;
			$self-> {chunkMap}      = \@chunkMap;
			$self-> {maxLineWidth} = $size[0];
		}
	} else {

# fast ( but not exact) calculation of maximal line width.
		if ( $uC == 0) {
			my $max = 0;
			my $maxLinesCount = 0;
			for ( @{$self-> {lines}}) {
				my $l = length( $_);
				$max  = $l, $maxLinesCount = 0 if $max < $l;
				$maxLinesCount++ if $l == $max;
			}
			$self-> {maxLineLength} = $max;
			$self-> {maxLineCount}  = $maxLinesCount;
		}
		if ( $uC < 2) {
			$self-> {maxLineWidth}  = $self-> {maxLineLength} * $mw;
		}
	}
	my $fh    = $self-> font-> height + $self->{lineSpace};
	$self-> {rows}  = int($size[1] / $fh);
	my $yTail = $size[1] - $self-> {rows} * $fh;

	if ( $uC < 2) {
		$self-> {maxLine}  = scalar @{$self-> {lines}} - 1;
		$self-> {maxChunk} = $self-> {wordWrap} ? (scalar @{$self-> {chunkMap}}/3-1) : $self-> {maxLine};
		$self-> {yTail} = ( $yTail > 0) ? 1 : 0;
# updating selections
		$self-> selection( @{$self-> {selStart}}, @{$self-> {selEnd}});
# updating cursor
		$self-> cursor( $self-> cursor);
		my $chunk = $self-> get_chunk( $self-> {cursorYl});
		my $x     = $self-> {cursorXl};
		$self-> {cursorAtX}      = $self-> get_chunk_width( $chunk, 0, $x);
		$self-> {cursorInsWidth} = $self-> get_chunk_width( $chunk, $x, 1);
	}
# positioning cursor
	my $cx  = $a[0] + $self-> {cursorAtX} - $self-> {offset};
	my $cy  = $a[1] + $yTail + ($self-> {rows} - $self-> {cursorYl} + $self-> {topLine } - 1) * $fh;
	my $xcw = $self-> {insertMode} ? $cw : $self-> {cursorInsWidth};
	my $ycw = $fh;
	$ycw -= $a[1] - $cy, $cy = $a[1] if $cy < $a[1];
	$xcw = $size[0] + $a[0] - $cx - 1 if $cx + $xcw >= $size[0] + $a[0];
	$self-> cursorVisible( $xcw > 0);
	if ( $xcw > 0) {
		$self-> cursorPos( $cx, $cy);
		$self-> cursorSize( $xcw, $ycw);
	}
	$self-> {uChange} = 0;

}

#-------------------------------------------------------------------------------

sub reset_cursor
{
	my $self = $_[0];
	$self-> {uChange} = 2;
	$self-> reset;
	$self-> {uChange} = 0;
}

#-------------------------------------------------------------------------------

sub reset_render
{
	my $self = $_[0];
	$self-> {uChange} = 1;
	$self-> reset;
	$self-> {uChange} = 0;
}

#-------------------------------------------------------------------------------

sub reset_scrolls
{
	my $self = $_[0];
	return if $self-> {resetDisabled};
	if ( $self-> {scrollTransaction} != 1) {
		$self-> vScroll( $self-> {maxChunk} >= $self-> {rows}) if $self-> {autoVScroll};
		$self-> {vScrollBar}-> set(
			max      => $self-> {maxChunk} - $self-> {rows} + 1,
			pageStep => $self-> {rows},
			whole    => $self-> {maxChunk} + 1,
			partial  => $self-> {rows},
			value    => $self-> {topLine },
		) if $self-> {vScroll};
	}
	if ( $self-> {scrollTransaction} != 2) {
		my $w = $self-> width - $self-> {indents}-> [0] - $self-> {indents}-> [2];
		my $lw = $self-> {maxLineWidth};
		if ( $self-> {autoHScroll}) {
			my $hs = ( $lw > $w) ? 1 : 0;
			if ( $hs != $self-> {hScroll}) {
				$self-> hScroll( $hs);
				$w = $self-> width - $self-> {indents}-> [0] - $self-> {indents}-> [2];
			}
		}
		$self-> {hScrollBar}-> set(
			max      => $self-> {wordWrap} ? 0 : $lw - $w,
			whole    => $lw < $w ? $w : $lw,
			value    => $self-> {offset},
			partial  => $w,
			pageStep => $lw / 5,
			step     => $self-> font-> width,
		) if $self-> {hScroll};
	}
}

#-------------------------------------------------------------------------------

sub VScroll_Change
{
	my ( $self, $scr) = @_;
	return if $self-> {scrollTransaction};
	$self-> {scrollTransaction} = 1;
	$self-> topLine ( $scr-> value);
	$self-> {scrollTransaction} = 0;

#print "scroll\n" if $self-> {hiliteBlok_modified};
	$self-> area if $self-> {hiliteBlok_modified};

}

#-------------------------------------------------------------------------------

sub HScroll_Change
{
	my ( $self, $scr) = @_;
	return if $self-> {scrollTransaction};
	$self-> {scrollTransaction} = 2;
	$self-> offset( $scr-> value);
	$self-> {scrollTransaction} = 0;
}

#-------------------------------------------------------------------------------

sub reset_syntax
{
	my $self = $_[0];
	if ( $self-> {syntaxHilite}) {
		my ( $notifier, @notifyParms) = $self-> get_notify_sub(q(ParseSyntax));
		my @syntax;
		$#syntax = $self-> {maxLine};
		@syntax = ();
		my $i = 0;
		$self-> push_event;
		for ( @{$self-> {lines}}) {
			my $sref = undef;
			$notifier-> ( @notifyParms, $_, $sref);
			push( @syntax, $sref);
			last if $i++ > 50; # test speed...
		}
		$self-> pop_event;
		$self-> {syntax} = \@syntax;
	} else {
		$self-> {syntax} = undef;
	}
}

#-------------------------------------------------------------------------------

sub reset_syntaxer
{
	my $self = $_[0];
	unless ( $self-> {hiliteREs} ) {
		$self-> {syntaxer} = sub {$_[2]=[];};
	} else {
		my $ic = $self->{hiliteCase} ? 'i' : '';
		my @doers;
		my $rest = 'push @a, $l, cl::Fore if $l; $l = 0;';
		if ($self-> {hiliteREs}) {
			my $i;

			for ($i = 0; $i < scalar @{$self-> {hiliteREs}} - 1; $i+=2) {
				next unless ref $self-> {hiliteREs}-> [$i+1] eq 'HASH';
				my $re = $self-> {hiliteREs}-> [$i];
				push @doers, "/\\G$re/gc$ic && do { " .
					$rest . 'push @a, length($1), ' .
					$self-> {hiliteREs}-> [$i+1]-> {color} ."; redo; };\n";
			}
		}

		$self-> {syntaxer} = eval(<<SYNTAXER);
		sub {
			my ( \$self, \$line) = \@_;
			my \@a;
			my \$l = 0;
			\$_ = \$line; study;
			{
				@doers
				/\\G(.)/gc && do { \$l++; redo; };
			}
			$rest
			\$_[2] = \\\@a;
		};
SYNTAXER
	}
}

#-------------------------------------------------------------------------------

sub wstaw_tab_15 {
	my ( $line, $from, $len, $tab, $pos ) = @_;
	$line = '' unless defined $line;
	$from = 0  unless $from;
	$len  = 0  unless $len;
	my $chunk = substr($line.(' 'x($len+$from)),$from,$len);
	my $sm = '';
	$chunk = '' unless defined $chunk;

	$line  = substr($line,0,$from);
	while ( $line =~ /^([^\t]*)\t/g ) {
		$tab = ' 'x(4-(length($1)%4));
		$line =~  s/\t/$tab/;
	}
	my $fl = length($line);
	while ( $chunk =~ /^([^\t]*)\t/g ) {
		$tab = ' 'x(3-(($fl+length($1))%4));
		$chunk =~  s/\t/\.$tab/;
		$sm = '.';
	}
	return ( $chunk, $sm );
}

#-------------------------------------------------------------------------------

sub wstaw_tab {
	my ( $row, $pos ) = @_;
	while($row =~ /^([^\t]*)\t/g ) {
		my $tab = ' 'x(4-(length($1)%4));
		$row =~ s/\t/$tab/;
	}
	return $row;
}

#-------------------------------------------------------------------------------
my $_HTML_FILE = undef;
my $_HTML_LAST_COLOR = 0;
my %_HTML_COLOR;
#-------------------------------------------------------------------------------


sub draw_colorchunk
{
	my ( $self, $canvas, $chunk, $i, $x, $y, $clr, $which_color ) = @_;

#print "draw_colorchunk=$self\n";

	my $sd = $self-> {syntax}-> [$i];
	unless ( defined $sd) {
		$self-> notify(q(ParseSyntax), $chunk, $sd);
		$self-> {syntax}-> [$i] = $sd;
	}
#return;

	my $backColor = 0;
	my $fontColor = 0;
	my $fontStyle = 0;
	my $fontSize  = 0;

	my $ofs = 0;
	my $cc;

	for ( my $j = 0; $j < scalar @{$sd} - 1; $j += 2 ) {
		my $xd = $self-> get_chunk_width ( $chunk, $ofs, $$sd[$j], \$cc);
		( $cc, undef ) = wstaw_tab_15 ( $chunk, $ofs, $$sd[$j], $self->{tabs}, 1 );
		for ( my $f = 0 ; $f < scalar @{$self-> {hiliteREs}}; $f += 2 ) {
			next unless ref $self-> {hiliteREs}->[$f+1] eq 'HASH';
			my $wzor = $self-> {hiliteREs}-> [$f];
			if ( $cc =~ /$wzor/ ) {

				if ( $self-> {hiliteREs}-> [$f+1]-> {backColor} ) {
					$canvas-> color ( $self-> {hiliteREs}-> [$f+1]-> {backColor} );
					$canvas-> bar (
						$x,			$y												- int( 0.5 * $self->{lineSpace} ),
						$x + $xd,	$y + $self-> font-> height + $self->{lineSpace} - int( 0.5 * $self->{lineSpace} )   );
					$backColor = 1;
				}

				if ( $self->{hiliteREs}-> [$f+1]-> {style} ) {
					$canvas-> set ( font => { style => $self-> {hiliteREs}-> [$f+1]-> {style} } );
					$fontStyle = 1;
				}

				if ( $self->{hiliteREs}->[$f+1]->{size} ) {
					$canvas-> set ( font => { size  => $self-> {hiliteREs}->[$f+1]->{size} });
					$fontSize = 1;
				}
			}
			last if $backColor && $self-> {hiliteREs}-> [$f+1]-> {last};
		}

		my $tekscik = $cc;
		my $kolorek = $$sd[$j+1];

		if ( $self->{hiliteBlok_value}->[$i] ) {
			if ( $self->{hiliteBlok}->[3] ) {
				$canvas-> color ( $self->{hiliteBlok}->[3] );
				$canvas-> bar (
					$x,			$y												- int( 0.5 * $self->{lineSpace} ),
					$x + $xd,	$y + $self-> font-> height + $self->{lineSpace} - int( 0.5 * $self->{lineSpace} ),
				);
				$backColor = 1;
			}
			$canvas-> color ( $self->{hiliteBlok}->[2] );
			$kolorek = $self->{hiliteBlok}->[2];

		} else {
			$canvas-> color (( $$sd[$j+1] == cl::Fore) ? $clr : $$sd[$j+1] );
			$kolorek = $$sd[$j+1] == cl::Fore ? $clr : $$sd[$j+1];
		}

		if ( $_HTML_FILE ) {
			$tekscik =~ s/>/gt;/g;
			$tekscik =~ s/</lt;/g;
			my $html_kolor = substr('000000'.sprintf("%x",$kolorek),-6);
			if ( $html_kolor eq '000000' ) {
				print $_HTML_FILE $cc;
			} else {
				print $_HTML_FILE '<span style="color:#'.$html_kolor.'">'.$cc.'</span>';
			}
		}
		$canvas-> text_out( $cc, $x, $y);
		$canvas-> set( font => { style => fs::Normal }) if $fontStyle;
		$canvas-> backColor( cl::Normal ) if $backColor;
		$canvas-> color( cl::Fore );
		$x += $xd;
		$ofs += $$sd[$j];
	}

}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

sub on_paint
{
# local variables definition area
	my ( $self, $canvas) = @_;

#print "on_paint\n";

	my @size   = $canvas-> size;
	my @clr    = $self-> enabled ?
	( $self-> color, $self-> backColor) :
	( $self-> disabledColor, $self-> disabledBackColor);
	my @sclr   = ( $self-> hiliteColor, $self-> hiliteBackColor);

	my ( $bw, $fh, $tl, $lc, $rc, $ofs, $yt, $tabs, $cw, $bt, $issel, $sh, $sx) =
		( $self-> {borderWidth}, $self-> font-> height + $self->{lineSpace},
		$self-> {topLine}, $self-> {maxChunk}+1, $self-> {rows}, $self-> {offset},
		$self-> {yTail}, $self-> {tabs},  $self-> {defcw}, $self-> {blockType},
		$self-> has_selection, $self-> {syntaxHilite}, $self-> {syntax},
	);
	my @a = $self-> get_active_area( 0, @size);

	my $numer = $Prima::CodeManager::developer{notes} ? $Prima::CodeManager::developer{notes}->pageIndex : 0;

	if ( $Prima::CodeManager::developer{notes} && $Prima::CodeManager::developer{"notes_$numer"} && $self eq $Prima::CodeManager::developer{"notes_$numer"} ) {
		if ( $Prima::CodeManager::developer{ "numer_$numer" } ) {
			my $numbers = '';
			for ( $self->{topLine} + 1 .. $self->{topLine} + $self->{rows} + 2 ) {
				$numbers .= "$_\n";

#				if ( $self->{hiliteBlok_value}->[$_-1] ) {
#					$numbers .= $_.':'.$self->{hiliteBlok_value}->[$_-1]."\n";
#				} else {
#					$numbers .= "$_  \n";
#				}

			}
			$Prima::CodeManager::developer{ "numer_$numer"}->set( text => $numbers );
		}
	}

	if ( $self->{exportHTML} > 0 ) {
		open ( $_HTML_FILE, ">CodeManager.html" );

		print $_HTML_FILE '<pre style="font-family:Courier New;font-size:9pt;">'."\n";
		print $_HTML_FILE '<a href="http://sao.pl" style="color:#cccccc;" target="NewWindow">Coloured by CodeManager</a>'."\n\n";
	}

###	$self->{hiliteBlokColorIndex} = -1;


#	if ( scalar @{$self->{hiliteBlok}} ) {
#		my $tresc = '';
#		my $row   = $self-> {topLine} - 1;
#		while ( $row >= 0 ) {
#			$tresc = @{$self-> {lines}}[$row];
#			my $nr = 0;
###			while ( $self->{hiliteBgCo}->[ 4 * $nr ] ) {
#				if ( $tresc =~ /$self->{hiliteBlok}->[4*$nr]/ ) {
#					$self->{hiliteBlokColorIndex} = $nr;
#					last;
#				}
#				if ( $tresc =~ /$self->{hiliteBlok}->[4*$nr+1]/ ) {
#					$self->{hiliteBlokColorIndex} = -1;
#					last;
#				}
###				$nr++;
###			}
#			$row--;
#		}
#	}


# drawing sheet
	my @clipRect = $self-> clipRect;
	if (
		$clipRect[0] > $a[0] &&
		$clipRect[1] > $a[1] &&
		$clipRect[2] < $a[2] &&
		$clipRect[3] < $a[3]
	) {
		$canvas-> color( $clr[ 1]);
		$canvas-> clipRect( $a[0], $a[1], $a[2] - 1, $a[3] - 1);

		$canvas-> bar( 0, 0, @size);
	} else {
		$self-> draw_border( $canvas, $clr[1], @size);
		$canvas-> clipRect( $a[0], $a[1], $a[2] - 1, $a[3] - 1);
	}
	$canvas-> color( $clr[0]);
	my $i;
	my $y = $a[3] - $fh;
	my $lim = int(( $a[3] - $clipRect[1]) / $fh) + $tl + 1;
	{
		my $fx = int(( $a[3] - $clipRect[3]) / $fh) + $tl;
		$fx = $tl if $fx < $tl;
		$y -= ( $fx - $tl) * $fh;
		$tl = $fx;
	}
	$lim = $lc if $lim > $lc;
	my $x    = $a[0] - $ofs;

# painting selection
	my @sel;
	my @cuaXs;
	if ( $issel) {
		@sel  = (@{$self-> {selStartl}}, @{$self-> {selEndl}});
		if ( $bt == bt::CUA) {
			@cuaXs   = (
				$a[0] - $ofs + $self-> get_chunk_width(
					$self-> get_chunk( $sel[1]), 0, $sel[0]
				),
				$a[0] - $ofs + $self-> get_chunk_width(
					$self-> get_chunk( $sel[3]), 0, $sel[2]
				)
			);
			my $cSet = 0;
			if ( $sel[1] == $sel[3]) {
				if ( $sel[1] >= $tl && $sel[ 1] < $lim) {
					$cSet = 1;
					$canvas-> color( $sclr[ 1]);
					$canvas-> bar(
						$cuaXs[0], $y - $fh * ( $sel[1] - $tl - 1) - 1,
						$cuaXs[1]-1, $y - $fh * ( $sel[1] - $tl)
					);
				}
			} else {
				if ( $sel[1] >= $tl && $sel[ 1] < $lim) {
					$cSet = 1;
					$canvas-> color( $sclr[ 1]);
					$canvas-> bar(
						$cuaXs[0], $y - $fh * ( $sel[1] - $tl - 1) - 1,
						$size[0], $y - $fh * ( $sel[1] - $tl)
					);
				}
				if ( $sel[3] >= $tl && $sel[ 3] < $lim) {
					$canvas-> color( $sclr[ 1]) unless $cSet;
					$cSet = 1;
					$canvas-> bar(
						0, $y - $fh * ( $sel[3] - $tl - 1) - 1,
						$cuaXs[1]-1, $y - $fh * ( $sel[3] - $tl)
					);
				}
				if (
					$sel[3] -1 > $sel[1] &&
					( $sel[1] + 1 < $lim || $sel[ 3] - 1 >= $tl)
				) {
					$canvas-> color( $sclr[ 1]) unless $cSet;
					$cSet = 1;
					$canvas-> bar(
						0, $y - $fh * ( $sel[1] - $tl) - 1,
						$size[0], $y - $fh * ( $sel[3] - $tl - 1)
					);
				}
			}
			$canvas-> color( $clr[0]) if $cSet;
		} elsif ( $bt == bt::Horizontal) {
			if ( $sel[1] < $lim || $sel[ 3] >= $tl) {
				$canvas-> color( $sclr[ 1]);
				$canvas-> bar( 0, $y - $fh * ( $sel[1] - $tl - 1) - 1, $size[0], $y - $fh * ( $sel[3] - $tl));
				# painting horizontal block lines, if available
				$canvas-> color( $sclr[0]);
				my ($from, $to) = (
					( $tl > $sel[1]) ?  $tl : $sel[1],
					( $lim < ($sel[3]+1)) ? $lim : ( $sel[3] + 1)
				);
				my $horz_y = $y - ( $from - $tl) * $fh;
				for ( $i = $from; $i < $to; $i++)
				{
					my $c = $self-> get_chunk( $i);
#					$c =~ s/\t/$tabs/g;
					$c = wstaw_tab ( $c, 2 );
					$canvas-> text_out( $c, $x, $horz_y);
					$horz_y -= $fh;
				}
				$canvas-> color( $clr[0]);
			}
		}
	}
	my $cSet = 0;

	my $which_color = 0;

# painting lines

	my $l_beg = $tl;
	my $l_end = $lim;
	if ( $self->{exportHTML} > 0 ) {
		$l_beg = 0;
		$l_end = $lc;
	}

	for ( $i = $l_beg; $i < $l_end; $i++)
	{
		my $c = $self-> get_chunk( $i);

		if ( $issel && $i >= $sel[1] && $i <= $sel[3])
		{
# painting selected lines
			if ( $bt == bt::CUA) {
				if ( $sel[1] == $sel[3])
				{
					my $cl = $sel[2] - length( $c);
					$c .= ' 'x$cl if $cl > 0;
					my $lc;
					if ( $sh) {

						$self-> draw_colorchunk(
							$canvas, $c, $i,
							$x, $y, $clr[0],
							$which_color
						);

					} else {
						$lc = substr( $c, 0, $sel[0]);

#						$lc =~ s/\t/$tabs/g;
						$lc = wstaw_tab ( $lc, 3 );
						$canvas-> text_out( $lc, $x, $y);

						$lc = substr( $c, $sel[2], length($c));

#						$lc =~ s/\t/$tabs/g;
						$lc = wstaw_tab ( $lc, 4 );
						$canvas-> text_out( $lc, $cuaXs[1], $y);
					}
					$lc = substr( $c, $sel[0], $sel[2] - $sel[0]);

#					$lc =~ s/\t/$tabs/g;
					$lc = wstaw_tab ( $lc, 5 );
					$canvas-> color( $sclr[0]);
					$canvas-> text_out( $lc, $cuaXs[0], $y);
					$canvas-> color( $clr[0]);
				} elsif ( $i == $sel[1]) {
					my $cl = $sel[0] - length( $c);
					$c .= ' 'x$cl if $cl > 0;
					my $lc;
					if ( $sh) {

						$self-> draw_colorchunk(
							$canvas, $c, $i,
							$x, $y, $clr[0],
							$which_color
						);
					} else {
						$lc = substr( $c, 0, $sel[0]);

#						$lc =~ s/\t/$tabs/g;
						$lc = wstaw_tab ( $lc, 6 );
						$canvas-> text_out( $lc, $x, $y);
					}
					$canvas-> color( $sclr[0]);
					$lc = substr( $c, $sel[0], length( $c));

#					$lc =~ s/\t/$tabs/g;
					$lc = wstaw_tab ( $lc, 7 );
					$canvas-> text_out( $lc, $cuaXs[0], $y);
					$cSet = 1;
				} elsif ( $i == $sel[3]) {
					my $cl = $sel[2] - length( $c);
					$c .= ' 'x$cl if $cl > 0;
					if ( $sh) {

						$self-> draw_colorchunk(
							$canvas, $c, $i,
							$x, $y, $clr[0],
							$which_color
						);

					} else {
						$canvas-> color( $clr[0]);
						$lc = substr( $c, $sel[2], length( $c));

#						$lc =~ s/\t/$tabs/g;
						$lc = wstaw_tab ( $lc, 8 );
						$canvas-> text_out( $lc, $cuaXs[1], $y);
					}
					$canvas-> color( $sclr[0]);
					my $lc = substr( $c, 0, $sel[2]);

#					$lc =~ s/\t/$tabs/g;
					$lc = wstaw_tab ( $lc, 9 );
					$canvas-> text_out( $lc, $x, $y);
					$canvas-> color( $clr[0]);
				} else {
#					$c =~ s/\t/$tabs/g;
					$c = wstaw_tab ( $c, 10 );
					$canvas-> color( $sclr[0]) unless $cSet;
					$cSet = 1;
					$canvas-> text_out( $c, $x, $y);
				}
			} elsif ( $bt == bt::Vertical) {
				my @vXs = (
					$self-> get_chunk_width( $c, 0, $sel[0]) - $ofs + $a[0],
					$self-> get_chunk_width( $c, 0, $sel[2]) - $ofs + $a[0]
				);
				$canvas-> color( $sclr[1]);
				$canvas-> bar( $vXs[0], $y, $vXs[1]-1, $y + $fh - 1);
				$canvas-> color( $clr[0]);
				my $cl = $sel[2] - length( $c);
				$c .= ' 'x$cl if $cl > 0;
				my $lc;
				if ( $sh) {

					$self-> draw_colorchunk(
						$canvas, $c, $i,
						$x, $y, $clr[0],
						$which_color
					);
				} else {
					$lc = substr( $c, 0, $sel[0]);

#					$lc =~ s/\t/$tabs/g;
					$lc = wstaw_tab ( $lc, 11 );
					$canvas-> text_out( $lc, $x, $y);
					$lc = substr( $c, $sel[2], length($c));

#					$lc =~ s/\t/$tabs/g;
					$lc = wstaw_tab ( $lc, 12 );
					$canvas-> text_out( $lc, $vXs[1], $y);
				}
				$lc = substr( $c, $sel[0], $sel[2] - $sel[0]);

#				$lc =~ s/\t/$tabs/g;
				$lc = wstaw_tab ( $lc, 13 );
				$canvas-> color( $sclr[0]);
				$canvas-> text_out( $lc, $vXs[0], $y);
				$canvas-> color( $clr[0]);
			}
		} else {
		# painting syntaxed lines
			if ( $sh) {
				$self-> draw_colorchunk( $canvas, $c, $i, $x, $y, $clr[0], $which_color );
			} else {
		# painting normal lines
#				$c =~ s/\t/$tabs/g;
				$c = wstaw_tab ( $c, 14 );
				$canvas-> color( $clr[0]);
				$canvas-> text_out( $c, $x, $y);
			}
		}
#print "$fh\n";
		$y -= $fh;
		print $_HTML_FILE "\n" if $self->{exportHTML} > 0;
	}

	if ( $self->{exportHTML} > 0 ) {
		print $_HTML_FILE "</pre>\n";
		close ( $_HTML_FILE );

		undef   $_HTML_FILE;
	}

	$self-> {exportHTML} =  0 	if $self->{exportHTML} < 0;
	$self-> {exportHTML} = -1 	if $self->{exportHTML} > 0;

	$self-> on_paint( $canvas ) if $self->{exportHTML} < 0;

}

#-----------------------------------------------------------------------

sub point2xy
{
	my ( $self, $x, $y) = @_;
	my ( $fh, $ofs, $avg, @a) = (
		$self-> font-> height + $self->{lineSpace}, $self-> {offset},

		$self-> {averageWidth}, $self-> get_active_area
	);
	my ( $rx, $ry, $inBounds);
	$inBounds = !( $x <= $a[0] || $x > $a[2] || $y < $a[1] || $y > $a[3]);
	$x -= $a[0];
	$y -= $a[1];
	my ( $w, $h) = ( $a[2] - $a[0], $a[3] - $a[1]);

	$y  = $h + $fh if $y > $h;
	$y  = -$fh if $y < 0;
	$x  = $w + $avg * 2 if $x > $w + $avg * 2;
	$x  = - $avg * 2 if $x < - $avg * 2;
	$ry = int(( $h - $y) / $fh) + $self-> {topLine };
	$ry = 0 if $ry < 0;
	$ry = $self-> {maxChunk} if $ry > $self-> {maxChunk};
	$rx = 0;

	my $chunk  = $self-> get_chunk( $ry);
	my $cl     = ( $w + $ofs) / ($self-> get_text_width(' ')||1);
	$chunk    .= ' 'x$cl;
	if ( $ofs + $x > 0)
	{
		my $ofsx = $ofs + $x;
		$ofsx = $self-> {maxLineWidth} if $ofsx > $self-> {maxLineWidth};
		$rx = $self-> text_wrap( $chunk, $ofsx,

			tw::CalcTabs|tw::BreakSingle|tw::ReturnFirstLineLength, $self-> {tabIndent});
	}
	return $self-> make_physical( $rx, $ry), $inBounds;
}

#------------------------------------------------------------------------------

sub on_mousedown
{
	my ( $self, $btn, $mod, $x, $y) = @_;
	return if $self-> {mouseTransaction};
	return if $btn != mb::Left && $btn != mb::Middle;
	my @xy = $self-> point2xy( $x, $y);
	return unless $xy[2];
	$self-> cursor( @xy);

	if ( $btn == mb::Middle) {
		my $cp = $::application-> bring('Primary');
		return if !$cp || $self-> {readOnly};
		$self-> insert_text( $cp-> text, 0);
		$self-> clear_event;
		return;
	}

	$self-> {mouseTransaction} = 1;
	if ( $self-> {persistentBlock} && $self-> has_selection) {
		$self-> {mouseTransaction} = 2;
	} else {
		$self-> start_block unless exists $self-> {anchor};
	}
	$self-> capture(1);
	$self-> clear_event;
}

#------------------------------------------------------------------------------

sub on_mouseup
{
	my ( $self, $btn, $mod, $x, $y) = @_;
	return unless $self-> {mouseTransaction};
	return if $btn != mb::Left;
	$self-> capture(0);
	$self-> end_block unless $self-> {mouseTransaction} == 2;
	$self-> {mouseTransaction} = undef;
	$self-> clear_event;

	return if $self-> {writeOnly} || !$self-> has_selection;
	my $cp = $::application-> bring('Primary');
	$cp-> text( $self-> get_selected_text) if $cp;
}

sub on_mousemove
{
	my ( $self, $mod, $x, $y) = @_;
	return unless $self-> {mouseTransaction};
	my @xy = $self-> point2xy( $x, $y);
	$self-> clear_event;
	if ( $xy[2])
	{
		$self-> scroll_timer_stop;
	} else {
		$self-> scroll_timer_start unless $self-> scroll_timer_active;
		return unless $self-> scroll_timer_semaphore;
		$self-> scroll_timer_semaphore(0);
	}
	$self-> {delayPanning} = 1;
	$self-> blockShiftMark(1);
	$self-> cursor( @xy);
	$self-> blockShiftMark(0);
	$self-> update_block unless $self-> {mouseTransaction} == 2;
	$self-> realize_panning;
}

sub on_mousewheel
{
	my ( $self, $mod, $x, $y, $z) = @_;
#	$z = int( $z/120);
	$self-> {wheelRows} += 0;
	$self-> {wheelRows} = 1 unless $self-> {wheelRows};
	$self-> {wheelRows} = 1 if $self-> {wheelRows} < 1;

	$z = int( $self-> {wheelRows} * $z/ 120 );
	$z *= $self-> {rows} if $mod & km::Ctrl;
	my $newTop = $self-> topLine  - $z;
	my $maxTop = $self-> {maxChunk} - $self-> {rows} + 1;
	$self-> topLine ( $newTop > $maxTop ? $maxTop : $newTop);
	$self-> clear_event;
#	$self-> repaint;
}

sub on_mouseclick
{
	my ( $self, $btn, $mod, $x, $y, $dbl) = @_;

	return if $self-> {mouseTransaction};
	return if $btn != mb::Left;
	my @xy = $self-> point2xy( $x, $y);
	return unless $xy[2];
	my $s = $self-> get_line( $xy[1]);
	$self-> clear_event;

	if ( !$dbl) {
		if ( $self-> {doubleclickTimer}) {
			$self-> {doubleclickTimer}-> destroy;
			delete $self-> {doubleclickTimer};
			$self-> selection( 0, $xy[1], length $s, $xy[1]);
		}
		return;
	}

	$self-> cancel_block;
	$self-> cursor( @xy);

	my $p = $xy[0];
	my $sl = length $s;
	my ($l,$r);

	return unless $sl;

	$p = $sl-1 if $p >= $sl;
	my $word = quotemeta($self-> {wordDelimiters});
	my $nonword = "[$word]";
	$word = "[^$word]";
	if ( substr($s,$p,1) =~ /$word/) {
		substr($s,0,$p) =~ /($word*)$/;
		$l = $p - length $1;
		substr($s,$p) =~ /^($word*)/;
		$r = $p + length $1;
	} else {
		substr($s,0,$p) =~ /($nonword*)$/;
		$l = $p - length $1;
		substr($s,$p) =~ /^($nonword*)/;
		$r = $p + length $1;
	}

	$self-> selection( $l, $xy[1], $r, $xy[1]);
	$self-> {doubleclickTimer} = Prima::Timer-> create( onTick => sub{
		$self-> {doubleclickTimer}-> destroy;
		delete $self-> {doubleclickTimer};
	}) unless $self-> {doubleclickTimer};
	$self-> {doubleclickTimer}-> timeout(

		Prima::Application-> get_system_value( sv::DblClickDelay)
	);
	$self-> {doubleclickTimer}-> start;
}

##########################################################################

sub on_keydown
{
	my ( $self, $code, $key, $mod, $repeat) = @_;

#	$self->{hiliteBlok_modified} = 1;

#	my @cs = $self-> cursor;
#	my $curr_row  = $self->{topLine} + $cs[1];
#	my $blok_beg  = $self->{hiliteBlok}->[0];
#	my $blok_end  = $self->{hiliteBlok}->[1];

#	my ( $prev_type, $next_type ) = ( 0, 0 );
#	$prev_type =  1 if $self-> get_line( $cs[1] ) =~  /($blok_beg|blok_end)/;

#	my $modify = 0;
#	for (my $i = $cs[1] ; $i < $cs[1] + $self->{rows} ; $i++ ) {
#		$modify = 1 if $self-> get_line( $i ) && (
#			$self-> get_line( $i ) =~  /($blok_beg|blok_end)/ || $self->{hiliteBlok_value}->[ $i ]
#		);
#		last if $modify
#	}

	if ($key == kb::Enter	|| $key == kb::Backspace	|| $key == kb::Return ||
		$key == kb::Tab		|| $key == kb::Delete
	) {
		$self-> area( $self->{topLine}, $self->{rows} ) ;
#		if ( $modify ) {
#			$self->{hiliteBlok_modified} = 1;
#		}
	}

	return if $self-> {readOnly};
	return if $mod & km::DeadKey;

	$mod &= ( km::Shift|km::Ctrl|km::Alt);
	$self-> notify(q(MouseUp),0,0,0) if $self-> {mouseTransaction};
	if ( $key == kb::Tab && !$self-> {wantTabs}) {
		return unless $mod & km::Ctrl;
		$mod &= ~km::Ctrl;
	}


	if  (
		( $code >= ord(' ') || ( $code == ord("\t"))) &&
		(( $mod  & (km::Alt | km::Ctrl)) == 0) &&
		(( $key == kb::NoKey) || ( $key == kb::Space) || ( $key == kb::Tab))
	) {

		{	#wb:
			$self-> delete_block if $self-> has_selection;
		}

		my @cs = $self-> cursor;
		my $c  = $self-> get_line( $cs[1] );
		my $l = 0;

		$self-> begin_undo_group;
		if ( $self-> insertMode) {
			$l = $cs[0] - length( $c), $c .= ' ' x $l if length( $c) < $cs[ 0];
			substr( $c, $cs[0], 0) = chr($code) x $repeat;
			$self-> set_line( $cs[1], $c, q(add), $cs[0], $l + $repeat);

		} else {
			$l = $cs[0] - length( $c) + $repeat, $c .= ' ' x $l
				if length( $c) < $cs[ 0] + $repeat;

			substr( $c, $cs[0], $repeat) = chr($code) x $repeat;
			$self-> set_line( $cs[1], $c, q(overtype));
		}

#		$next_type =  1 if $self-> get_line( $cs[1] ) =~  /($blok_beg|blok_end)/;
#		$self-> area;

		$self-> cursor( $cs[0] + $repeat, $cs[1]);
		$self-> end_undo_group;
		$self-> clear_event;
	}
}

sub on_fontchanged
{
	my $self = $_[0];
	$self-> reset_render;
	$self-> reset_scrolls;
}

sub on_size
{
	my $self = $_[0];
	$self-> reset_render;
	$self-> reset_scrolls;
}

sub on_enable  { $_[0]-> repaint; }
sub on_disable { $_[0]-> repaint; }

sub on_enter
{
	my $self = $_[0];
	$self-> insertMode( $::application-> insertMode);
}

#----------------------------------------------------------------------------------------

sub on_change
{
	my ( $self ) = @_;

	$self-> {modified} = 1;
	$self-> {hiliteBlok_modified} = 1;

	if ( $Prima::CodeManager::developer{notes} ) {
		my $nr = $Prima::CodeManager::developer{notes}->pageIndex;

		$Prima::CodeManager::list_of_files[ $nr ] = '*'.$Prima::CodeManager::list_of_files[ $nr ] if $Prima::CodeManager::list_of_files[ $nr ] !~ /^\*/;
		$Prima::CodeManager::developer{notes}->set_tabs( @Prima::CodeManager::list_of_files );
	}

#print "on_change\n";

#	if ( $self->{hiliteBlok_modified} ) {
#		$self-> area;
#		on_paint ( $self, $self );
#	}
#	$self->{hiliteBlok_modified} = 0;

	if ( $self-> {hiliteBlok_modified} && @{$self->{hiliteBlok}} ) {
		$self-> area( $self->{topLine}, $self->{rows} ) ;
#		on_paint ( $self, $self );
	}

#	on_paint ( $self, $self ) if scalar @{$self->{hiliteBlok}};
}

#----------------------------------------------------------------------------------------

sub on_parsesyntax {
	$_[2] = [] unless $_[2];
	$_[0]-> {syntaxer}-> (@_);
}

sub set_block_type
{
	my ( $self, $bt) = @_;
	return if $bt == $self-> {blockType};
	$self-> push_group_undo_action( 'blockType', $self-> {blockType});
	$self-> {blockType} = $bt;
	return unless $self-> has_selection;
	$self-> reset_render;
	$self-> repaint;
}

#----------------------------------------------------------------------------------------

sub set_text_ref
{
	my ( $self, $ref) = @_;
	return unless defined $ref;
	$self-> {capLen} = length( $$ref);
	$#{$self-> {lines}} = $self-> {capLen} / 40;
	@{$self-> {lines}} = ();
	@{$self-> {lines}} = split( "\n", $$ref." ");
	$self-> {maxLine} = scalar @{$self-> {lines}}-1;

	$self-> reset_syntax;
	$self-> reset_scrolls;
	if ( !$self-> {resetDisabled}) {
		$self-> lock;
		$self-> selection(0,0,0,0);
		$self-> reset;
		$self-> cursor($self-> {cursorX}, $self-> {cursorY});
		$self-> unlock;
		$self-> notify(q(Change));
		$self-> reset_scrolls;
	}
}

sub text
{
	unless ($#_) {
		my $hugeScalarRef = $_[0]-> textRef;
		return $$hugeScalarRef;
	} else {
		$_[0]-> textRef( \$_[1]);
	}
}

sub get_text_ref
{
	my $self = $_[0];
	my $hugeScalar = join( "\n", @{$self-> {lines}});
	return \$hugeScalar;
}

sub get_chunk
{
	my ( $self, $index) = @_;
	my $ck = $self-> {lines};
	return '' if $self->{maxLine} < 0;
	Carp::confess($index) if $index > $self-> {maxChunk};
	if ( $self-> {wordWrap}) {
		my $cm = $self-> {chunkMap};
		return substr( $$ck[ $$cm[ $index * 3 + 2]], $$cm[ $index * 3], $$cm[ $index * 3 + 1]);
	} else {
		return $$ck[ $index];
	}
}

sub get_line
{
	my ( $self, $index) = @_;
	return $self-> {maxLine} >= 0 ? $self-> {lines}-> [$index] : '';
}

sub get_line_ext
{
	my ( $self, $index) = @_;
	return '' if $self-> {maxLine} < 0;
	return $self-> {lines}-> [ $self-> {wordWrap} ?

		( $self-> {chunkMap}-> [ $index * 3 + 2]) :

		$index
	];
}

sub get_line_dimension
{
	my ( $self, $y) = @_;
	return $y, 1 unless $self-> {wordWrap};
	( undef, $y) = $self-> make_logical( 0, $y);
	my ($ret, $ix, $cm) = ( 0, $y * 3 + 2, $self-> {chunkMap});
	$ret++, $ix += 3 while $$cm[ $ix] == $y;
	return $y, $ret;
}

sub get_chunk_org
{
	my ( $self, $index) = @_;
	return $index unless $self-> {wordWrap};
	my $cm = $self-> {chunkMap};
	my $y = $$cm[ $index * 3 + 2];
	$index-- while $y == $$cm[ $index * 3 + 2];
	return $index + 1;
}

sub get_chunk_end
{
	my ( $self, $index) = @_;
	return $index unless $self-> {wordWrap};
	my $cm = $self-> {chunkMap};
	my $y = $$cm[ $index * 3 + 2];
	my $maxY = $self-> {maxChunk};
	return -1 if $maxY < 0;
	$index++ while $index <= $maxY && $y == $$cm[ $index * 3 + 2];
	return $index - 1;
}

sub get_chunk_width
{
	my ( $self, $chunk, $from, $len, $retC) = @_;
	my $line = $chunk;
	my $cl;
	$cl = $from + $len - length( $chunk) + 1;
	$chunk .= ' 'x$cl if $cl >= 0;
	$chunk  = substr( $chunk, $from, $len);
#	$chunk  =~ s/\t/$self->{tabs}/g;
#	$chunk = wstaw_tab ( $chunk, 15 );
	my $sm = '';
	( $chunk, $sm ) = wstaw_tab_15 ( $line, $from, $len, $self->{tabs}, 15 );
	$$retC = $chunk if $retC;
	return $self-> {fixed} ?

		( length( $chunk) * $self-> {averageWidth}) :

		$self-> get_text_width( $chunk);
}

sub has_selection
{
	my @s  = $_[0]-> selection;
	return !(($s[0] == $s[2]) && ( $s[1] == $s[3]));
}

sub realize_panning
{
	delete $_[0]-> {delayPanning};
	for ( qw( topLine  offset)) {
		my $c = 'delay_' . $_;
		next unless defined $_[0]-> {$c};
		$_[0]-> $_( $_[0]-> {$c});
		delete $_[0]-> {$c};
	}
}

sub set_cursor
{
	my ( $self, $x, $y) = @_;
	my ( $ox, $oy) = ($self-> {cursorX}, $self-> {cursorY});
	my $maxY = $self-> {maxLine};
	$y = $maxY if $y < 0 || $y > $maxY;
	$y = 0 if $y < 0; # ??
	my $line = $self-> get_line( $y);
	$x = length( $line) if $x < 0;
	my ( $lx, $ly) = $self-> make_logical( $x, $y);
	my ( $olx, $oly) = ( $self-> {cursorXl}, $self-> {cursorYl});
	$self-> {cursorXl} = $lx;
	$self-> {cursorYl} = $ly;
	return if $y == $oy and $x == $ox and $lx == $olx and $ly == $oly;
	my ( $tl, $r, $yt) = ( $self-> {topLine }, $self-> {rows}, $self-> {yTail});
	if ( $ly < $tl) {
		$self-> topLine ( $ly);
	} elsif ( $ly >= $tl + $r) {
		my $nfc = $ly - $r + 1;
		$self-> topLine ( $nfc);
	}
	my $chunk  = $self-> get_chunk( $ly);
	my $atX    = $self-> get_chunk_width( $chunk, 0, $lx);
	my $deltaX = $self-> get_chunk_width( $chunk, $lx, 1);
	my $actualWidth = $self-> width -

		$self-> {indents}-> [0] -

		$self-> {indents}-> [2] -

		$self-> {defcw};
	my $ofs = $self-> {offset};
	my $avg = $self-> {averageWidth};
	if ( $atX < $ofs) {
		my $nofs = $atX;
		$self-> offset( $nofs - $avg);
	} elsif ( $atX >= $ofs + $actualWidth - $deltaX) {
		my $nofs = $atX - $actualWidth + $deltaX;
		$nofs = $ofs + $avg if $nofs - $ofs < $avg;
		$self-> offset( $nofs);
	}

	# check if last undo record contains cursor movements only, so these movements
	# can be grouped

	my $undo = 1;
	if ( !$self-> {undo_in_action} && @{$self-> {undo}} && @{$self-> {undo}-> [-1]}) {
		my $ok = 1;

		for ( @{$self-> {undo}-> [-1]}) {
			$ok = 0, last if $$_[0] ne 'cursor';
		}
		$undo = 0 if $ok;
	}

	$self-> push_undo_action( 'cursor', $self-> {cursorX}, $self-> {cursorY}) if $undo;
	$self-> {cursorX}        = $x;
	$self-> {cursorY}        = $y;
	$self-> {cursorAtX}      = $atX;
	$self-> {cursorInsWidth} = $deltaX;

	$self-> reset_cursor;
	$self-> cancel_block

		if !$self-> {blockShiftMark} && !$self-> {persistentBlock};

}

sub set_top_line
{
	my ( $self, $tl) = @_;
	$tl = $self-> {maxChunk} if $tl >= $self-> {maxChunk};
	$tl = 0 if $tl < 0;
	return if $self-> {topLine } == $tl;
	if ( $self-> {delayPanning}) {
		$self-> {delay_topLine } = $tl;
		return;
	}
	my $dt = $tl - $self-> {topLine };
	$self-> push_group_undo_action( 'topLine', $self-> {topLine});
	$self-> {topLine } = $tl;
	if ( $self-> {vScroll} && $self-> {scrollTransaction} != 1) {
		$self-> {scrollTransaction} = 1;
		$self-> {vScrollBar}-> value( $tl);
		$self-> {scrollTransaction} = 0;
	}
	$self-> reset_cursor;
	$self-> scroll( 0, $dt * ($self-> font-> height + $self->{lineSpace}),
		clipRect => [ $self-> get_active_area]);
}

sub reset_indents
{
	my ( $self) = @_;
	$self-> reset_render;
	$self-> reset_scrolls;
		$self-> repaint;
}

sub set_hilite_numbers
{
	my $self = $_[0];
	$self-> {hiliteNumbers} = $_[1];
	if ( $self-> {syntaxHilite}) {
		$self-> reset_syntaxer;
		$self-> repaint;
	}
}

sub set_hilite_q_strings
{
	my $self = $_[0];
	$self-> {hiliteQStrings} = $_[1];
	if ( $self-> {syntaxHilite}) {
		$self-> reset_syntaxer;
		$self-> repaint;
	}
}

#-------------------------------------------------------------------------------

sub set_hilite_qq_strings
{
	my $self = $_[0];
	$self-> {hiliteQQStrings} = $_[1];
	if ( $self-> {syntaxHilite}) {
		$self-> reset_syntaxer;
		$self-> repaint;
	}
}

#-------------------------------------------------------------------------------

sub set_hilite_ids
{
	my ($self, $hi) = @_;
	if ( $hi) {
		push @{$hi}, cl::Fore if scalar @{$hi} / 2 != 0;
		$hi = [@{$hi}];
	}
	$self-> {hiliteIDs} = $hi;
	if ( $self-> {syntaxHilite}) {
		$self-> reset_syntaxer;
		$self-> repaint;
	}
}

#-------------------------------------------------------------------------------

sub set_hilite_chars
{
	my ($self, $hi) = @_;
	if ( $hi) {
		push @{$hi}, cl::Fore if scalar @{$hi} / 2 != 0;
		$hi = [@{$hi}];
	}
	$self-> {hiliteChars} = $hi;
	if ( $self-> {syntaxHilite}) {
		$self-> reset_syntaxer;
		$self-> repaint;
	}
}

#-------------------------------------------------------------------------------

sub set_hilite_res
{
	my ($self, $hi) = @_;
	if ( $hi) {
		push @{$hi}, cl::Fore if scalar @{$hi} / 2 != 0;
		$hi = [@{$hi}];
	}
	$self-> {hiliteREs} = $hi;
	if ( $self-> {syntaxHilite}) {
		$self-> reset_syntaxer;
		$self-> repaint;
	}
}

sub set_insert_mode
{
	my ( $self, $insert) = @_;
	my $oi = $self-> {insertMode};
	$self-> {insertMode} = $insert;
	$self-> reset_cursor if $oi != $insert;
	$::application-> insertMode( $insert);
	$self-> push_group_undo_action( 'insertMode', $oi) if $oi != $insert;
}

#-------------------------------------------------------------------------------

sub set_offset
{
	my ( $self, $offset) = @_;
	$offset = 0 if $offset < 0;
	$offset = 0 if $self-> {wordWrap};
	return if $self-> {offset} == $offset;
	if ( $self-> {delayPanning}) {
		$self-> {delay_offset} = $offset;
		return;
	}
	my $dt = $offset - $self-> {offset};
	$self-> push_group_undo_action( 'offset', $self-> {offset});
	$self-> {offset} = $offset;
	if ( $self-> {hScroll} && $self-> {scrollTransaction} != 2) {
		$self-> {scrollTransaction} = 2;
		$self-> {hScrollBar}-> value( $offset);
		$self-> {scrollTransaction} = 0;
	}
	$self-> reset_cursor;
	$self-> scroll( -$dt, 0,
		clipRect => [ $self-> get_active_area]);
}

#-------------------------------------------------------------------------------

sub set_selection
{
	my ( $self, $sx, $sy, $ex, $ey) = @_;
	my $maxY = $self-> {maxLine};
	my ( $osx, $osy, $oex, $oey) = $self-> selection;
	my $onsel = ( $osx == $oex && $osy == $oey);
	if ( $maxY < 0) {
		$self-> {selStart}  = [0,0];
		$self-> {selEnd}    = [0,0];
		$self-> {selStartl} = [0,0];
		$self-> {selEndl  } = [0,0];
		$self-> repaint unless $onsel;
		return;
	}
	$sy  = $maxY if $sy < 0 || $sy > $maxY;
	$ey  = $maxY if $ey < 0 || $ey > $maxY;
	( $sy, $ey, $sx, $ex) = ( $ey, $sy, $ex, $sx) if $sy > $ey;
	$osx = $oex = $sx,  $osy = $oey = $ey  if $onsel;
	if ( $sx == $ex && $sy == $ey) {
		$osy  = $maxY if $osy < 0 || $osy > $maxY;
		$oey  = $maxY if $oey < 0 || $oey > $maxY;
		$sx  = $ex  = $osx;
		$sy  = $ey  = $osy;
	}
	my ($firstChunk, $lastChunk) = ( $self-> get_line( $sy), $self-> get_line( $ey));
	my ($fcl, $lcl) = ( length( $firstChunk), length( $lastChunk));
	my $bt = $self-> {blockType};
	$sx = $fcl if ( $bt != bt::Vertical && $sx > $fcl) || ( $sx < 0);
	$ex = $lcl if ( $bt != bt::Vertical && $ex > $lcl) || ( $ex < 0);
	( $sx, $ex) = ( $ex, $sx) if $sx > $ex && (( $sy == $ey && $bt == bt::CUA) || ( $bt == bt::Vertical));
	my ( $lsx, $lsy) = $self-> make_logical( $sx, $sy);
	my ( $lex, $ley) = $self-> make_logical( $ex, $ey);
	( $lsx, $lex) = ( $lex, $lsx) if $lsx > $lex && (( $lsy == $ley && $bt == bt::CUA) || ( $bt == bt::Vertical));
	$sy = $ey if $sx == $ex and $bt == bt::Vertical;
	my ( $_osx, $_osy) = @{$self-> {selStartl}};
	my ( $_oex, $_oey) = @{$self-> {selEndl}};
	$self-> {selStart}  = [ $sx, $sy];
	$self-> {selStartl} = [ $lsx, $lsy];
	$self-> {selEnd}    = [ $ex, $ey];
	$self-> {selEndl}   = [ $lex, $ley];
	return if $sx == $osx && $ex == $oex && $sy == $osy && $ey == $oey;
	return if $sx == $ex && $sy == $ey && $onsel;
	$self-> push_group_undo_action('selection', $osx, $osy, $oex, $oey);
	( $osx, $osy, $oex, $oey) = ( $_osx, $_osy, $_oex, $_oey);
	( $sx, $sy)   = @{$self-> {selStartl}};
	( $ex, $ey)   = @{$self-> {selEndl}};
	$osx = $oex = $sx,  $osy = $oey = $ey  if $onsel;
	if (( $osy > $ey && $oey > $ey) || ( $oey < $sy && $oey < $sy))
	{
		$self-> repaint;
		return;
	}
	# connective selection
	my ( $start, $end);
	if ( $bt == bt::CUA || ( $sx == $osx && $ex == $oex)) {
		if ( $sy == $osy) {
			if ( $ey == $oey) {
				if ( $sx == $osx) {
					$start = $end = $ey;
				} elsif ( $ex == $oex) {
					$start = $end = $sy;
				} else {
					($start, $end) = ( $sy, $ey);
				}
			} else {
				( $start, $end) = ( $ey < $oey) ? ( $ey, $oey) : ( $oey, $ey);
			}
		} elsif ( $ey == $oey) {
			( $start, $end) = ( $sy < $osy) ? ( $sy, $osy) : ( $osy, $sy);
		} else {
			$start = ( $sy < $osy) ? $sy : $osy;
			$end   = ( $ey > $oey) ? $ey : $oey;
		}
	} else {
		$start = ( $sy < $osy) ? $sy : $osy;
		$end   = ( $ey > $oey) ? $ey : $oey;
	}
	my ( $ofs, $tl, $fh, $r, $yT) = (
		$self-> {offset}, $self-> {topLine },

		$self-> font-> height + $self->{lineSpace}, $self-> {rows},

		$self-> {yTail}
	);
	my @a = $self-> get_active_area( 0);
	return if $end < $tl || $start >= $tl + $r + $yT;
	if ( $start == $end && $bt == bt::CUA) {
		# single connective line paint
		my $chunk;
		my ( $xstart, $xend);
		if ( $sx == $osx) {
			( $xstart, $xend) = ( $ex < $oex) ? ( $ex, $oex) : ( $oex, $ex);
		} elsif ( $ex == $oex) {
			( $xstart, $xend) = ( $sx < $osx) ? ( $sx, $osx) : ( $osx, $sx);
		} else {
			$xstart = ( $sx < $osx) ? $sx : $osx;
			$xend   = ( $ex > $oex) ? $ex : $oex;
		}
		unless ( $self-> {wordWrap}) {
			if ( $start == $sy) {
				$chunk = $firstChunk;
			} elsif ( $start == $ey) {
				$chunk = $lastChunk;
			} else {
				$chunk = $self-> get_chunk( $start);
			}
		} else {
			$chunk = $self-> get_chunk( $start);
		}
		$self-> invalidate_rect(
			$a[0] - $ofs + $self-> get_chunk_width( $chunk, 0, $xstart) - 1,
			$a[3] - $fh * ( $start - $tl + 1),
			$a[0] - $ofs + $self-> get_chunk_width( $chunk, 0, $xend),
			$a[3] - $fh * ( $start - $tl)
		);
	} else {
		# general connected lines paint
		$self-> invalidate_rect(
			$a[0], $a[3] - $fh * ( $end - $tl + 1),
			$a[2], $a[3] - $fh * ( $start - $tl),
		);
	}
}

#-------------------------------------------------------------------------------

sub set_tab_indent
{
	my ( $self, $ti) = @_;
	$ti = 0 if $ti < 0;
	$ti = 256 if $ti > 256;
	return if $ti == $self-> {tabIndent};
	$self-> {tabIndent} = $ti;
	$self-> reset;
	$self-> repaint;
}

#-------------------------------------------------------------------------------

sub set_syntax_hilite
{
	my ( $self, $sh) = @_;
	$sh = 0 if $self-> {wordWrap};
	return if $sh == $self-> {syntaxHilite};
	$self-> {syntaxHilite} = $sh;
	$self-> reset_syntaxer if $sh;
	$self-> reset_syntax;
	$self-> repaint;
}

#-------------------------------------------------------------------------------

sub set_word_wrap
{
	my ( $self, $ww) = @_;
	return if $ww == $self-> {wordWrap};
	$self-> {wordWrap} = $ww;
	$self-> syntaxHilite(0) if $ww;
	$self-> reset;
	$self-> reset_scrolls;
	$self-> repaint;
}

#-------------------------------------------------------------------------------

sub cut
{
	my $self = $_[0];
	return if $self-> {readOnly};
	$self-> begin_undo_group;
	$self-> copy;
	$self-> delete_block;
	$self-> end_undo_group;

	$self-> area( $self->{topLine}, $self->{rows} ) if @{$self->{hiliteBlok}};
}

#-------------------------------------------------------------------------------

sub copy
{
	my $self = $_[0];
	my $text = $self-> get_selected_text;
	$::application-> Clipboard-> text($text) if defined $text;
}

#-------------------------------------------------------------------------------

sub get_selected_text
{
	my $self = $_[0];
	return undef unless $self-> has_selection;
	my @sel = $self-> selection;
	my $text = '';
	my $bt = $self-> blockType;

	if ( $bt == bt::CUA) {
#print "$sel[1] == $sel[3]\n";
		if ( $sel[1] == $sel[3]) {
			$text = substr( $self-> get_line( $sel[1]), $sel[0], $sel[2] - $sel[0]);
		} else {
			my $c = $self-> get_line( $sel[1]);
			$text = substr( $c, $sel[0], length( $c) - $sel[0])."\n";
			my $i;
			for ( $i = $sel[1] + 1; $i < $sel[3]; $i++) {
				$text .= $self-> get_line( $i)."\n";
			}
			$c = $self-> get_line( $sel[3]);
			$text .= substr( $c, 0, $sel[2]);
		}
	} elsif ( $bt == bt::Horizontal) {
		my $i;
		for ( $i = $sel[1]; $i <= $sel[3]; $i++) {
		$text .= $self-> get_line( $i)."\n";
		}
	} else {
		my $i;
		for ( $i = $sel[1]; $i <= $sel[3]; $i++) {
			my $c = $self-> get_line( $i);
			my $cl = $sel[2] - length( $c);
			$c .= ' 'x$cl if $cl > 0;
			$text .= substr($c, $sel[0], $sel[2] - $sel[0])."\n";
		}
		chomp( $text);
	}
#print "|$text|\n";
	return $text;
}

#-------------------------------------------------------------------------------

sub lock_change
{
	my ( $self, $lock) = @_;
	$lock = $lock ? 1 : -1;
	$self-> {notifyChangeLock} += $lock;
	$self-> {notifyChangeLock} = 0 if $lock > 0 && $self-> {notifyChangeLock} < 0;
	$self-> notify(q(Change)) if $self-> {notifyChangeLock} == 0 && $lock < 0;
}

#-------------------------------------------------------------------------------

sub change_locked
{
	my $self = $_[0];
	return $self-> {notifyChangeLock} != 0;
}

#-------------------------------------------------------------------------------

sub insert_text
{
	my ( $self, $s, $hilite) = @_;

#print "$s\n";

	return if $self-> {readOnly};
	return if !defined($s) or length( $s) == 0;

	$self-> begin_undo_group;
	$self-> cancel_block unless $self-> {blockType} == bt::CUA;
	my @cs = $self-> cursor;
	my @xy = @cs;

	my @ln = split( "\n", $s, -1);
#	my $zzz = join '|', @ln;
#print "<|$zzz|>$cs[1]\n";
#	pop @ln unless length $ln[-1];
	$s = $self-> get_line( $cs[1]);

#cursor position shift to end of the line if is greater than it:
	$cs[0] = length( $s) if $cs[0] > length( $s);

	my $cl = $cs[0] - length( $s);
#	$s .= ' 'x$cl if $cl > 0;
#	$cl = 0 if $cl < 0;
	$self-> lock_change(1);

	if ( scalar @ln == 1) {
		substr( $s, $cs[0], 0) = $ln[0];
		$self-> set_line( $cs[1], $s, q(add), $cs[0], $cl + length( $ln[0]));
		$self-> selection( $cs[0], $cs[1], $cs[0] + length( $ln[0]), $cs[1])
			if $hilite && $self-> {blockType} == bt::CUA;
		@xy = ( $xy[0] + length($ln[0]) ,$xy[1] );

	} else {
		my $spl0 = substr( $s, 0, $cs[0]);
		my $spl1 = substr( $s, $cs[0] );
#		substr( $s, $cs[0], length( $s) - $cs[0] ) = $ln[0];
#		substr( $s, $cs[0], 0 ) = $ln[0];
		$self-> lock;
		$self-> set_line( $cs[1], $spl0.$ln[0] );
		shift @ln;
#		$self-> insert_line( $cs[1] + 1, (@ln, $spl));
		$self-> insert_line( $cs[1] + 1, @ln);
		$self-> set_line( $cs[1] + scalar @ln, $ln[(scalar @ln) -1 ].$spl1 );
		$self-> selection( $cs[0], $cs[1], length( $ln[-1]), $cs[1]+scalar(@ln))
			if $hilite && $self-> {blockType} == bt::CUA;
		$self-> unlock;
		@xy = ( length( $ln[(scalar @ln) -1 ] ), $cs[1] + scalar @ln );
	}
	$self-> lock_change(0);
	$self-> end_undo_group;

	$self-> area( $self->{topLine}, $self->{rows} ) if @{$self->{hiliteBlok}};

	$self-> cursor( @xy );
}

sub insert_text_orig
{
	my ( $self, $s, $hilite) = @_;
	return if !defined($s) or length( $s) == 0;
	$self-> begin_undo_group;
	$self-> cancel_block unless $self-> {blockType} == bt::CUA;
	my @cs = $self-> cursor;
	my @ln = split( "\n", $s, -1);
	pop @ln unless length $ln[-1];
	$s = $self-> get_line( $cs[1]);
	my $cl = $cs[0] - length( $s);
	$s .= ' 'x$cl if $cl > 0;
	$cl = 0 if $cl < 0;
	$self-> lock_change(1);
	if ( scalar @ln == 1) {
		substr( $s, $cs[0], 0) = $ln[0];
		$self-> set_line( $cs[1], $s, q(add), $cs[0], $cl + length( $ln[0]));
		$self-> selection( $cs[0], $cs[1], $cs[0] + length( $ln[0]), $cs[1])
			if $hilite && $self-> {blockType} == bt::CUA;
	} else {
		my $spl = substr( $s, $cs[0], length( $s) - $cs[0]);
		substr( $s, $cs[0], length( $s) - $cs[0]) = $ln[0];
		$self-> lock;
		$self-> set_line( $cs[1], $s);
		shift @ln;
		$self-> insert_line( $cs[1] + 1, (@ln, $spl));
		$self-> selection( $cs[0], $cs[1], length( $ln[-1]), $cs[1]+scalar(@ln))
			if $hilite && $self-> {blockType} == bt::CUA;
		$self-> unlock;
	}
	$self-> lock_change(0);
	$self-> end_undo_group;
}

sub paste
{
	my $self = $_[0];
	return if $self-> {readOnly};

	#print "|".$::application-> Clipboard-> text."|\n";
	{	#wb:
		$self-> delete_block if $self-> has_selection;
	}

	$self-> insert_text( $::application-> Clipboard-> text, 1);

	$self-> area( $self->{topLine}, $self->{rows} ) if @{$self->{hiliteBlok}};

}

sub make_logical
{
	my ( $self, $x, $y) = @_;
	return (0,0) if $self-> {maxChunk} < 0;
	return $x, $y unless $self-> {wordWrap};
	my $maxY = $self-> {maxLine};
	$y = $maxY if $y > $maxY || $y < 0;
	$y = 0 if $y < 0;
	my $l = length( $self-> {lines}-> [$y]);
	$x = $l if $x < 0 || $x > $l;
	$x = 0 if $x < 0;
	my $cm = $self-> {chunkMap};
	my $r;
	( $l, $r) = ( 0, $self-> {maxChunk} + 1);
	my $i = int($r / 2);
	my $kk = 0;
	while (1) {
		my $acd = $$cm[$i * 3 + 2];
		last if $acd == $y;
		$acd > $y ? $r : $l   = $i;
		$i = int(( $l + $r) / 2);
		if ( $kk++ > 200) {
#			print "bcs dump to $y\n";
			( $l, $r) = ( 0, $self-> {maxChunk} + 1);
			$i = int($r / 2);
			for ( $kk = 0; $kk < 7; $kk++) {
				my $acd = $$cm[$i * 3 + 2];
#				print "i:$i [$l $r] f() = $acd\n";
				$acd > $y ? $r : $l   = $i;
				$i = int(( $l + $r) / 2);
			}
			die;
			last;
		}
	}
	$y = $i;
	$i*= 3;
	$i-= 3, $y-- while $$cm[ $i] != 0;
	$i+= 3, $y++ while $x > $$cm[ $i] + $$cm[ $i + 1];
	$x -= $$cm[ $i];
	return $x, $y;
}

sub make_physical
{
	my ( $self, $x, $y) = @_;
	return (0,0) if $self-> {maxLine} < 0;
	return $x, $y unless $self-> {wordWrap};
	my $maxY = $self-> {maxChunk};
	$y = $maxY if $y > $maxY || $y < 0;
	$y = 0 if $y < 0;
	my $cm = $self-> {chunkMap};
	my ( $ofs, $l, $nY) = ( $$cm[ $y * 3], $$cm[ $y * 3 + 1], $$cm[ $y * 3 + 2]);
	$x = $l if $x < 0 || $x > $l;
	$x = 0 if $x < 0;
	return $x + $ofs, $nY;
}

sub start_block
{
	my $self = $_[0];
	return if exists $self-> {anchor};
	my $blockType = $_[1] || $self-> {blockType};
	$self-> selection(0,0,0,0);
	$self-> blockType( $blockType);
	$self-> {anchor} = [ $self-> {cursorX}, $self-> {cursorY}];
}

sub update_block
{
	my $self = $_[0];
	return unless exists $self-> {anchor};
	$self-> selection( @{$self-> {anchor}}, $self-> {cursorX}, $self-> {cursorY});
}

sub end_block
{
	my $self = $_[0];
	return unless exists $self-> {anchor};
	my @anchor = @{$self-> {anchor}};
	delete $self-> {anchor};
	$self-> selection( @anchor, $self-> {cursorX}, $self-> {cursorY});
}

sub cancel_block
{
	delete $_[0]-> {anchor};
	$_[0]-> selection(0,0,0,0);
}

sub set_marking
{
	my ( $self, $mark, $blockType) = @_;
	return if $mark == exists $self-> {anchor};
	$mark ? $self-> start_block( $blockType || $self-> {blockType}) : $self-> end_block;
}

#wb
sub kursor_w_dol {
	my ( $line, $vis_len_prev ) = @_;

	$line = '' unless $line;

	return $vis_len_prev unless $line =~ /\t/;

	$line = $line.(' 'x($vis_len_prev));

	my $dlu = 0;
	my $res = 0;
	while ( $line =~ /(.)/g ) {
		last if $dlu >= $vis_len_prev;
		if ( $1 eq "\t" ) {
			$dlu += 3 - ( $dlu % 4 );
		}
		$dlu++;
		$res++;
	}
	return $res;
}

sub cursor_down
{
	my $d = $_[1] || 1;
#print "cursor_down\n";
	my $l1 = $_[0]->get_line( $_[0]-> {cursorYl} );
	my $l2 = $_[0]->get_line( $_[0]-> {cursorYl} + $d );

	($l1,undef) = wstaw_tab_15( $l1, 0, $_[0]-> {cursorX}, '', 0 );
	my $len2 = kursor_w_dol( $l2,length($l1));
	$_[0]-> cursorLog( $len2, $_[0]-> {cursorYl} + $d);

	$_[0]-> area( $_[0]->{topLine}, $_[0]->{rows} ) if $_[0]-> {hiliteBlok_modified} && @{$_[0]->{hiliteBlok}};
}

sub cursor_up
{
#print "cursor_up\n";
	return if $_[0]-> {cursorYl} == 0;

	my $d = $_[1] || 1;

	my $l1 = $_[0]->get_line( $_[0]-> {cursorYl} );
	my $l2 = $_[0]->get_line( $_[0]-> {cursorYl} - $d );
	($l1,undef) = wstaw_tab_15( $l1, 0, $_[0]-> {cursorX}, '', 0 );
	my $len2 = kursor_w_dol( $l2,length($l1));

	my ( $x, $y) = $_[0]-> make_physical( $len2, $_[0]-> {cursorYl} - $d);
#	my ( $x, $y) = $_[0]-> make_physical( $_[0]-> {cursorXl}, $_[0]-> {cursorYl} - $d);
	$y = 0 if $y < 0;
	$_[0]-> cursor( $x, $y);

	$_[0]-> area( $_[0]->{topLine}, $_[0]->{rows} ) if $_[0]-> {hiliteBlok_modified} && @{$_[0]->{hiliteBlok}};
}

sub cursor_left
{
	my $d = $_[1] || 1;
	my $x = $_[0]-> cursorX;
	if ( $x - $d >= 0) {
		$_[0]-> cursorX( $x - $d)
	} elsif ( $_[0]-> {cursorWrap}) {
		if ( $d == 1) {
			my $y = $_[0]-> cursorY - 1;
			$_[0]-> cursor( -1, $y < 0 ? 0 : $y);
		} else {
			$_[0]-> cursor_left( $d - 1);
		}
	} else {
		$_[0]-> cursorX( 0);
	}
}

sub cursor_right
{
	my $d = $_[1] || 1;
	my $x = $_[0]-> cursorX;
	if ( $_[0]-> {cursorWrap} || $_[0]-> {wordWrap}) {
		my $y = $_[0]-> cursorY;
		if ( $x + $d > length( $_[0]-> get_line( $y))) {
			if ( $d == 1) {
				$_[0]-> cursor( 0, $y + 1) if $y < $_[0]-> {maxLine};
			} else {
				$_[0]-> cursor_right( $d - 1);
			}
		} else {
			$_[0]-> cursorX( $x + $d);
		}
	} else {
		$_[0]-> cursorX( $x + $d);
	}
}

sub cursor_home
{
	my ($spaces) = ($_[0]-> get_line( $_[0]-> cursorY) =~ /^([s\t]*)/);
	$_[0]-> begin_undo_group;
	$_[0]-> offset(0);
	$_[0]-> cursorX(0);
	$_[0]-> end_undo_group;
}

sub cursor_end
{
	my ($nonspaces) = ($_[0]-> get_line( $_[0]-> cursorY) =~ /^(.*?)[\s\t]*$/);
	$_[0]-> cursorX( length $nonspaces);

}

sub cursor_cend  {
	$_[0]-> cursor( 0, -1 );
	$_[0]-> cursor_end;
#print "cursor_cend\n";

	$_[0]-> area if $_[0]-> {hiliteBlok_modified} && @{$_[0]->{hiliteBlok}};
}

sub cursor_chome {
	$_[0]-> cursor( 0,  0 );
#print "cursor_chome\n";

	$_[0]-> area if $_[0]-> {hiliteBlok_modified} && @{$_[0]->{hiliteBlok}};
}
#----------------------------------------------
sub cursor_cpgup
{
	my @xy = (0,0);
#print "cursor_cpgup\n";
	if ( $_[0]->{cursorYl} > $_[0]->topLine ) {
		@xy = ( $_[0]-> {cursorXl}, $_[0]->topLine );
	}
	$_[0]-> cursorLog( @xy );

	$_[0]-> area if $_[0]-> {hiliteBlok_modified} && @{$_[0]->{hiliteBlok}};
}
#----------------------------------------------
sub cursor_cpgdn
{
	my @xy = ( 0, -1 );
#print "cursor_cpgdn\n";
	if ( $_[0]->{cursorYl} < $_[0]->topLine + $_[0]->{rows} - 1 ) {
		@xy = ( $_[0]-> {cursorXl}, $_[0]->topLine + $_[0]->{rows} - 1 );
	}
	$_[0]-> cursorLog( @xy );

	$_[0]-> area if $_[0]-> {hiliteBlok_modified} && @{$_[0]->{hiliteBlok}};

#	my $cy = $_[0]->{cursorYl} == $_[0]->topLine + $_[0]->{rows} - 1 ? 0 : $_[0]->topLine + $_[0]->{rows};
#	$_[0]-> cursorLog( $_[0]-> {cursorXl}, $cy - 1 );
}
#----------------------------------------------
sub cursor_pgup
{
	my $d = $_[1] || 1;
	my $i;
	my @xy = $_[0]->cursor;
	for ( $i = 0; $i < $d; $i++) {
		my ( $tl, $r) = ($_[0]-> topLine , $_[0]-> {rows} );

		my $cy = $tl - $r;

		$_[0]-> cursorLog( $_[0]-> {cursorXl}, $cy < 0 ? 0 : $cy);
		$_[0]-> cursorLog( $_[0]-> {cursorXl}, $xy[1] < $r ? 0 : $xy[1] - $r  );

		$_[0]-> area( $_[0]->{topLine}, $_[0]->{rows} ) if $_[0]-> {hiliteBlok_modified} && @{$_[0]->{hiliteBlok}};
	}
}
#----------------------------------------------

sub cursor_pgdn  {
	my $d = $_[1] || 1;
	my $i;
	my @xy = $_[0]->cursor;
	for ( $i = 0; $i < $d; $i++) {
		my ( $tl, $r) = ($_[0]-> topLine , $_[0]-> {rows} - 1);

		my $cy = $tl + 2*$r + 1;

		$_[0]-> cursorLog( $_[0]-> {cursorXl}, $cy);
		$_[0]-> cursorLog( $_[0]-> {cursorXl}, $xy[1] + $r + 1 );

		$_[0]-> area( $_[0]->{topLine}, $_[0]->{rows} ) if $_[0]-> {hiliteBlok_modified} && @{$_[0]->{hiliteBlok}};
	}
}

##############################################
##############################################

sub word_right
{
	my $self = $_[0];
	my $d = $_[1] || 1;
	my $i;
	for ( $i = 0; $i < $d; $i++) {
		my ( $x, $y, $w, $delta, $maxY) = (

			$self-> cursorX, $self-> cursorY,

			$self-> wordDelimiters, 0, $self-> {maxLine}
		);
		my $line  = $self-> get_line( $y);
		my $clen  = length( $line);
		if ($self-> {cursorWrap}) {
			while ( $x >= $clen) {
				$y++;
				return if $y > $maxY;
				$x = 0;
				$line = $self-> get_line( $y);
				$clen = length( $line);
			}
		}
		my $cl = $x - $clen + 1;
		$line .= ' 'x$cl if $cl >= 0;
		unless ($w =~ quotemeta substr $line, $x, 1) {
			$delta++ while ( $w !~ quotemeta substr $line, $x + $delta, 1) &&
				$x + $delta < $clen;
		}
		if ( $x + $delta < $clen) {
			$delta++ while ( $w =~ quotemeta substr $line, $x + $delta, 1) &&
				$x + $delta < $clen;
		}
		$self-> cursor( $x + $delta, $y);
	}
}

sub word_left
{
	my $self = $_[0];
	my $d = $_[1] || 1;
	my $i;
	for ( $i= 0;$i<$d; $i++) {
		my ( $x, $y, $w, $delta) =
			( $self-> cursorX, $self-> cursorY, $self-> wordDelimiters, 0);
		my $line = $self-> get_line( $y);
		my $clen = length( $line);
		if ($self-> {cursorWrap}) {
			while ( $x == 0) {
				$y--;
				$y = 0, last if $y < 0;
				$line = $self-> get_line( $y);
				$x = $clen = length( $line);
			}
		}
		my $cl = $x - $clen + 1;
		$line .= ' 'x$cl if $cl >= 0;
		if ( $w =~ quotemeta( substr( $line, $x - 1, 1)))
		{
			$delta-- while (( $w =~ quotemeta( substr( $line, $x + $delta - 1, 1))) &&
				( $x + $delta > 0))
		}
		if ( $x + $delta > 0)
		{
			$delta-- while (!( $w =~ quotemeta( substr( $line, $x + $delta - 1, 1))) &&
				( $x + $delta > 0))
		}
		$self-> cursor( $x + $delta, $y);
	}
}

sub cursor_shift_key
{
	my ( $self, $menuItem) = @_;
	$self-> begin_undo_group;
	$self-> start_block unless exists $self-> {anchor};
	$menuItem =~ s/Shift//;
	my $action = $self-> accelTable-> action( $menuItem);
	$action = $self-> can( $action, 0) unless ref $action;
	$self-> {delayPanning} = 1;
	$self-> blockShiftMark(1);
	$action-> ( @_);
	$self-> blockShiftMark(0);
	$self-> selection( @{$self-> {anchor}}, $self-> {cursorX}, $self-> {cursorY});
	$self-> realize_panning;
	$self-> end_undo_group;
}

sub blockShiftMark
{
	return $_[0]-> {blockShiftMark} unless $#_;
	my ( $self, $mark) = @_;
	return if $self-> {blockShiftMark} == $mark;
	$self-> push_group_undo_action( 'blockShiftMark', $self-> {blockShiftMark});
	$self-> {blockShiftMark} = $mark;
}

sub mark_vertical
{
	my $self = $_[0];
	if ( exists $self-> {anchor})
	{
		$self-> update_block;
		delete $self-> {restorePersistentBlock}, $self-> persistentBlock(0)

			if $self-> {restorePersistentBlock};
	} else {
		$self-> blockType( bt::Vertical);
		$self-> {restorePersistentBlock} = 1

			unless $self-> persistentBlock;
		$self-> persistentBlock( 1);
		$self-> cursor_shift_key(q(ShiftCursorRight));
	}
}

sub mark_horizontal
{
	my $self = $_[0];
	if ( exists $self-> {anchor})
	{
		$self-> update_block;
		delete $self-> {restorePersistentBlock}, $self-> persistentBlock(0)

			if $self-> {restorePersistentBlock};
	} else {
		$self-> blockType( bt::Horizontal);
		$self-> {restorePersistentBlock} = 1 unless $self-> persistentBlock;
		$self-> persistentBlock( 1);
		$self-> start_block;
		$self-> selection(

			$self-> make_physical( 0, $self-> {cursorYl}),
			$self-> make_physical( -1, $self-> {cursorYl})
		);
	}
}

sub set_line
{
	my ( $self, $y, $line, $operation, $from, $len) = @_;
	my $maxY = $self-> {maxLine};
	$self-> insert_empty_line(0), $y = $maxY = $self-> {maxLine} if $maxY < 0;
	return if $y > $maxY || $y < 0;
	my ( $newDim, $oldDim, $ry) = (0,0,0);
	my ( $fh, $tl, $ofs, @a) = (
		$self-> font-> height + $self-> {lineSpace}, $self-> {topLine }, $self-> {offset}, $self-> get_active_area,
	);
	my @sz = ( $a[2] - $a[0], $a[3] - $a[1]);
	my ( $_from, $_to);
	$self-> begin_undo_group;
	$self-> push_undo_action( 'set_line', $y, $self-> {lines}-> [$y]);
	if ( $self-> {wordWrap}) {
		my $breaks = $self-> text_wrap(

			$line,

			$sz[0] - $self-> {defcw},

			tw::WordBreak|tw::CalcTabs|tw::NewLineBreak|tw::ReturnChunks,

			$self-> {tabIndent}
		);
		my @chunkMap;
		( undef, $ry) = $self-> make_logical( 0, $y);
		my ($ix, $cm) = ( $ry * 3 + 2, $self-> {chunkMap});
		my $max_ix = $self-> {maxChunk} * 3 + 2;
		$oldDim++, $ix += 3 while $ix <= $max_ix && $$cm[ $ix] == $y;
		$newDim = scalar @{$breaks} / 2;
		my $i;
		for ( $i = 0; $i < $newDim; $i++) {
			push( @chunkMap, $$breaks[$i * 2], $$breaks[$i * 2 + 1], $y);
		}
		splice( @{$cm}, $ry * 3, $oldDim * 3, @chunkMap);

		$self-> {lines}-> [$y] = $line;
		$self-> {maxChunk} -= $oldDim - $newDim;
		if ( $oldDim == $newDim) {
			( $_from, $_to) = ( $ry, $ry + $oldDim);
		} else {
			$self-> vScroll( $self-> {maxChunk} >= $self-> {rows})

				if $self-> {autoVScroll};
			$self-> topLine(0) if $self-> {maxChunk} < $self-> {rows};
			$self-> {vScrollBar}-> set(
				max   => $self-> {maxChunk} - $self-> {rows} + 1,
				whole => $self-> {maxChunk} + 1,
			) if $self-> {vScroll};
		}
	} else {
		my ( $oldL, $newL) = ( length( $self-> {lines}-> [$y]), length( $line));
		$self-> {lines}-> [$y] = $line;
		if ( $oldL == $self-> {maxLineLength} || $newL > $self-> {maxLineLength})
		{
			my $needReset = 0;
			if ( $newL != $oldL) {
				if ( $oldL == $self-> {maxLineLength}) {
					$self-> {maxLineCount}--;
					$needReset = $self-> {maxLineCount} <= 0;
				}
				if ( $newL > $self-> {maxLineLength}) {
					$self-> {maxLineLength} = $newL;
					$self-> {maxLineCount}  = 1;
					$self-> {maxLineWidth}  = $newL * $self-> {averageWidth};
					$needReset = 0;
				}
				$self-> reset if $needReset;
			}
			my $lw = $self-> {maxLineWidth};
			if ( $self-> {autoHScroll}) {
				my $hs = ( $lw > $sz[0] ) ? 1 : 0;
				if ( $hs != $self-> {hScroll}) {
					$self-> hScroll( $hs);
					@a = $self-> get_active_area;
					@sz = ( $a[2] - $a[0], $a[3] - $a[1]);
				}
			}
			$self-> {hScrollBar}-> set(
				max      => $lw - $sz[0],
				whole    => $lw,
				partial  => $sz[0],
			) if $self-> {hScroll};
		}
		$_from = $_to = $y;
	}

	$self-> {syntax}-> [$y] = undef;

	if ( defined $operation && $self-> has_selection) {
		if ( $operation ne q(overtype)) {
			$len *= -1 if $operation eq q(delete);
			my @sel = $self-> selection;
			if ( $self-> {blockType} == bt::CUA) {
				if ( $sel[3] == $sel[1] && $sel[1] == $y) {
					$sel[0] += $len if $from < $sel[0];
					if ( $from < $sel[2]) {
						$sel[2] += $len;
						@sel=(0,0,0,0) if $sel[2] <= $from;
					}
				} elsif ( $sel[1] == $y && $from < $sel[0]) {
					$sel[0] += $len;
				} elsif ( $sel[3] == $y && $from < $sel[2]) {
					$sel[2] += $len;
				}
				$sel[0] = 0 if $sel[0] < 0;
				$sel[2] = 0 if $sel[2] < 0;
			} elsif ( $newDim != $oldDim) {
				my @selE = @{$self-> {selEndl}};
				$selE[1] -= $oldDim - $newDim;
				($sel[2], $sel[3]) = $self-> make_physical( @selE);
				@sel = (0,0,0,0) if $sel[3] < $sel[1];
			}
			$self-> selection( @sel);
			delete $self-> {anchor};
			$self-> cancel_block unless $self-> has_selection;
		}
	} else {
		$self-> cancel_block;
	}

	if ( defined $_to)
	{
		$self-> invalidate_rect(
			$a[0], $a[3] - $fh * ( $_to - $tl + 1),
			$a[2], $a[3] - $fh * ( $_from - $tl)
		);
	} else {
		$self-> repaint;
	}
	$self-> cursor( $self-> cursor);
	$self-> end_undo_group;
	$self-> notify(q(Change)) unless $self-> {notifyChangeLock};

}

sub insert_empty_line
{
	my ( $self, $y, $len) = @_;
	my $maxY = $self-> {maxLine};
	$len ||= 1;
	return if $y > $maxY + 1 || $y < 0 || $len == 0;
	my $ly;
	$self-> push_undo_action('delete_line', $y, $len);
	if ( $self-> {wordWrap}) {
		if ( $y > $maxY) {
			$ly = $self-> {maxChunk} + 1;
		} else {
			( undef, $ly) = $self-> make_logical( 0, $y);
		}
		my ($i, $maxC, $cm) = ( 0, $self-> {maxChunk}, $self-> {chunkMap});
		if ( $y <= $maxY) {
			splice( @{$cm}, $ly * 3, 0, ( 0, 0, $y) x $len);
			for ( $i = $ly + 1; $i < $ly + $len; $i++) {

				$$cm[ $i * 3 + 2] += $i - $ly;

			}
			for ( $i = $ly + $len; $i <= $maxC + $len; $i++) {

				$$cm[ $i * 3 + 2] += $len;

			}
		} else {
			push( @{$cm}, ( 0, 0, $y)x$len);
			for ( $i = $ly; $i < $ly + $len; $i++) {

				$$cm[ $i * 3 + 2] += $i - $ly;

			}
		}
		$self-> {maxChunk} += $len;
	} else {
		$self-> {maxChunk} += $len;
		$ly = $y;
		$self-> {maxLineCount} += $len if $self-> {maxLineLength} == 0;
	}
	for (@{$self-> {markers}}) {

		$$_[1] += $len if $$_[1] >= $y;

	}
	splice( @{$self-> {lines}}, $y, 0, ('') x $len);
	$self-> {maxLine} += $len;
	splice( @{$self-> {syntax}}, $y, 0, ([0,cl::Black]) x $len)

		if $self-> {syntaxHilite};

	if ( $self-> has_selection) {
		my @sel = $self-> selection;
		unless ( $sel[3] < $y) {
			$sel[1] += $len if $sel[1] >= $y;
			$sel[3] += $len;
		}
		$self-> selection( @sel);
		delete $self-> {anchor};
	}
	my ( $tl, $rc, $yt, $fh, @a) = (
		$self-> {topLine }, $self-> {rows}, $self-> {yTail},
		$self-> font-> height + $self-> {lineSpace}, $self-> get_active_area,
	);
	if (

		$y < $tl + $rc + $yt - 1 &&

		$y + $len > $tl &&

		$y <= $maxY &&

		!$self-> has_selection
	) {
		$self-> scroll( 0, -$fh * $len,
			confineRect => [ @a[0..2], $a[3] - $fh * ( $y - $tl)]);
	}
	$self-> vScroll( $self-> {maxChunk} >= $self-> {rows}) if $self-> {autoVScroll};
	$self-> {vScrollBar}-> set(
		max      => $self-> {maxChunk} - $self-> {rows} + 1,
		whole    => $self-> {maxChunk} + 1,
		partial  => $self-> {rows},
	) if $self-> {vScroll};
	return $ly;
}

#--------------------------------------------------------------------------------------

sub insert_line
{
	my ( $self, $y, @lines) = @_;
	my $len = scalar @lines;
	my $maxY = $self-> {maxLine};
	return if $y > $maxY + 1 || $y < 0 || $len == 0;
	my $i;
	$self-> begin_undo_group;
	$self-> insert_empty_line( $y, $len);
	$self-> lock_change(1);
	for ( $i = 0; $i < $len; $i++) {
		$self-> set_line( $y + $i, $lines[ $i], q(add), 0, length( $lines[ $i]));
	}
	$self-> lock_change(0);
	$self-> end_undo_group;
}

sub delete_line
{
	my ( $self,$y,$len) = @_;
	my $maxY = $self-> {maxLine};
	$len ||= 1;
	return if $y > $maxY || $y < 0 || $len == 0;

	$self-> begin_undo_group;
	for ( my $i=0; $i < $len; $i++) {
		$self-> push_undo_action( 'set_line', $y+$i, $self-> {lines}-> [$y+$i]);
	}
	$self-> push_undo_action( 'insert_empty_line', $y, $len);

	$len = $maxY - $y + 1 if $y + $len > $maxY + 1;
	my ( $lx, $ly) = (0,0);
	if ( $self-> {wordWrap}) {
		( $lx, $ly) = $self-> make_logical( 0, $y);
		$lx = 0;
		my ($i, $maxC, $cm) = ($ly, $self-> {maxChunk}, $self-> {chunkMap});
		$lx++, $i++ while ( $i <= $maxC) and ( $$cm[ $i * 3 + 2] <= ( $y + $len - 1));
		splice( @{$cm}, $ly * 3, $lx * 3);
		$self-> {maxChunk} -= $lx;
		for ( $i = $ly; $i <= $maxC - $lx; $i++) { $$cm[ $i * 3 + 2] -= $len; }
	} else {
		$self-> {maxChunk} -= $len;
	}

	my @removed = splice( @{$self-> {lines}}, $y, $len);
	splice( @{$self-> {syntax}}, $y, $len) if $self-> {syntaxHilite};
	for (@{$self-> {markers}}) {
		$$_[1] -= $len if $$_[1] >= $y;
		$$_[1] = 0     if $$_[1] < 0;
	}

	$self-> {maxLine} -= $len;
	if ( $self-> has_selection) {
		my @sel = (@{$self-> {selStartl}}, @{$self-> {selEndl}});
		if ( $sel[3] >= $ly) {
			if ( $sel[1] >= $ly) {
				$sel[1] -= $lx;
				$sel[0] = 0, $sel[1] = $ly if $sel[1] < $ly;
			}
			$sel[3] -= $lx;
			$sel[2] = 0, $sel[3] = $ly if $sel[3] < $ly;
		}
		$self-> selection(

			$self-> make_physical($sel[0], $sel[1]),

			$self-> make_physical($sel[2], $sel[3])
		);
		delete $self-> {anchor};
		$self-> cancel_block unless $self-> has_selection;
	}

	$self-> vScroll( $self-> {maxChunk} >= $self-> {rows}) if $self-> {autoVScroll};
	$self-> topLine(0) if $self-> {maxChunk} < $self-> {rows};
	$self-> {vScrollBar}-> set(
		max   => $self-> {maxChunk} - $self-> {rows} + 1,
		whole => $self-> {maxChunk} + 1,
	) if $self-> {vScroll};

	unless ( $self-> {wordWrap}) {
		my $mlv       = $self-> {maxLineLength};
		for ( @removed) {
			$self-> {maxLineCount}-- if length($_) == $mlv;
			if ( $self-> {maxLineCount} <= 0) {
				$self-> reset;
				my $lw = $self-> {maxLineWidth};
				my $w  = $self-> width -

					$self-> {indents}-> [0] -

					$self-> {indents}-> [2];
				if ( $self-> {autoHScroll}) {
					my $hs = ( $lw > $w) ? 1 : 0;
					if ( $hs != $self-> {hScroll}) {
						$self-> hScroll( $hs);
						$w = $self-> width -

							$self-> {indents}-> [0] -

							$self-> {indents}-> [2];
					}
				}
				$self-> {hScrollBar}-> set(
					max      => $lw - $w,
					whole    => $lw,
					partial  => $w,
				) if $self-> {hScroll};
				last;
			}
		}
	}
	$self-> cursor( $self-> cursor);
	$self-> end_undo_group;
	$self-> repaint;
	$self-> notify(q(Change)) unless $self-> {notifyChangeLock};
}

sub delete_chunk
{
	my ( $self, $y, $len) = @_;
	my $maxY = $self-> {maxChunk};
	$len ||= 1;
	return if $y > $maxY || $y < 0 || $len == 0;

	$self-> delete_line( $y, $len), return unless $self-> {wordWrap};
	$len = $maxY - $y + 1 if $y + $len > $maxY + 1;
	return if $len == 0;

	my $cm = $self-> {chunkMap};
	my $psy   = $$cm[ $y * 3 + 2];
	my $pey   = $$cm[($y + $len - 1) * 3 + 2];
	my $start = $$cm[ $y * 3];
	my $end   = $$cm[($y + $len - 1) * 3] + $$cm[($y + $len - 1) * 3 + 1];
	if ( $psy == $pey) {
		my $c  = $self-> {lines}-> [$psy];
		$self-> delete_line( $psy), return

			if $start == 0 && $end == length( $c);
		substr( $c, $start, $end - $start) = '';
		$self-> set_line( $psy, $c, q(delete), $start, $end - $start);
		return;
	}
	$self-> lock;
	my ( $sy, $ey) = ( $psy, $pey);
	my $c;
	$self-> begin_undo_group;
	$self-> lock_change(1);
	if ( $start > 0) {
		$c  = $self-> {lines}-> [$psy];
		my $cs = length( $c) - $start + 1;
		substr( $c, $start, $cs) = '';
		$self-> set_line( $psy, $c, q(delete), $start, $cs);
		$sy++;
	}
	$c  = $self-> {lines}-> [$pey];
	if ( $end < length( $c)) {
		substr( $c, 0, $end) = '';
		$self-> set_line( $pey, $c, q(delete), 0,  $end);
		$ey--;
	}
	$self-> delete_line( $sy, $ey - $sy + 1) if $ey >= $sy;
	$self-> cursor( $self-> {cursorX}, $psy);
	$self-> unlock;
	$self-> lock_change(0);
	$self-> end_undo_group;
}

sub delete_text
{
	my ( $self, $x, $y, $len) = @_;
	my $maxY = $self-> {maxLine};
	$y = $maxY if $y < 0;
	return if $y > $maxY || $y < 0;

	my $c = $self-> {lines}-> [ $y];
	my $l = length( $c);
	$x = $l if $x < 0;
	return if $x < 0;

	if ( $x == $l) {
		return if $y == $maxY;
		$self-> lock_change(1);
		$self-> begin_undo_group;
		$self-> set_line( $y, $self-> get_line( $y) . $self-> get_line( $y + 1));
		$self-> delete_line( $y + 1);
		$self-> end_undo_group;
		$self-> lock_change(0);
		return;
	}
	$len = $l - $x if $len + $x >= $l;
	return if $len <= 0;
	substr( $c, $x, $len) = '';
	$self-> set_line( $y, $c, q(delete), $x, $len);
}

sub delete_char
{
	my $self = $_[0];
	$self-> delete_text( $self-> cursor, $_[1] || 1);
}

sub back_char
{
	my $self = $_[0];

{#wb
	if ( $self-> has_selection ) {
		$self-> delete_block;
		return;
	}
}

	my @c = $self-> cursor;
	my $d = $_[1] || 1;

	$self-> begin_undo_group;
	if ( $c[0] >= $d) {
		$self-> delete_text( $c[0] - $d, $c[1], $d);
		$self-> cursorX( $c[0] - $d);
	} elsif ( $c[1] > 0) {
		$self-> cursor( -1, $c[1] - 1);
		$self-> delete_text( -1, $c[1] - 1);
	}
	$self-> end_undo_group;
}

sub delete_current_chunk
{
	my $self = $_[0];
	$self-> delete_chunk( $self-> {cursorYl});
}

sub delete_to_end
{
	my $self = $_[0];
	my @cs = $self-> cursor;
	my $c = $self-> get_line( $cs[1]);
	return if $cs[ 0] > length( $c);

	$self-> set_line( $cs[1], substr( $c, 0, $cs[0]), q(delete), $cs[0], length( $c) - $cs[0]);
}

sub delete_block
{
	my $self = $_[0];
	return unless $self-> has_selection;

	$self-> begin_undo_group;
	$self-> push_undo_action('selection', $self-> selection);

	my @sel = ( @{$self-> {selStartl}}, @{$self-> {selEndl}});
	my $bt = $self-> {blockType};

	if ( $bt == bt::Horizontal) {
		$self-> delete_chunk( $sel[1], $sel[3] - $sel[1] + 1);
	} elsif ( $bt == bt::CUA) {
		my $c;
		my @sel = ( @{$self-> {selStart}}, @{$self-> {selEnd}});

#print "1=$sel[1] / 3= $sel[3]\n";

		if ( $sel[1] == $sel[3]) {
			$c = $self-> get_line( $sel[1]);
			substr( $c, $sel[0], $sel[2] - $sel[0]) = '';
			$self-> set_line( $sel[1], $c);
		} else {
			my ( $from, $len) = ( $sel[1], $sel[3] - $sel[1]);

			my $res = substr( $self-> get_line( $from), 0, $sel[0]);
			$c = $self-> get_line( $sel[3]);
			$sel[2] = length( $c) if $sel[2] > length( $c);
			$res .= substr( $c, $sel[2], length( $c) - $sel[2]);

#			} elsif ( $sel[3] < $self-> {maxLine}) {
#				$res .= $self-> get_line( $sel[3] + 1);
#			}

			$self-> lock_change(1);
			$self-> delete_line( $from + 1, $len) if $len > 0;
			$self-> set_line( $from, $res);

			$self-> lock_change(0);
		}
	} else {
		my @sel = ( @{$self-> {selStart}}, @{$self-> {selEnd}});
		my $len = $sel[2] - $sel[0];
		my $i;
		$self-> lock_change(1);
		$self-> lock;
		for ( $i = $sel[1]; $i <= $sel[3]; $i++)
		{
			my $c = $self-> get_line( $i);
			if ( $c ne '') {
				substr( $c, $sel[0], $len) = '';
				$self-> set_line( $i, $c);
			}
		}
		$self-> unlock;
		$self-> lock_change(0);
	}

	$self-> cursorLog( $sel[0], $sel[1]);
	$self-> cancel_block;
	$self-> end_undo_group;
}

sub copy_block
{
	my $self = $_[0];
	return if

		$self-> {readOnly} ||

		$self-> {blockType} == bt::CUA ||

		$self-> {wordWrap} ||

		!$self-> has_selection;

	my @sel = $self-> selection;
	$self-> lock_change(0);
	$self-> lock;
	$self-> begin_undo_group;
	if ( $self-> {blockType} == bt::Horizontal) {
		my @lines;
		my $i;
		for ( $i = $sel[1]; $i <= $sel[3]; $i++) {

			push @lines, $self-> get_line( $i);
		}
		$self-> insert_line( $self-> cursorY, @lines);
	} else {
		my @lines;
		my $i;
		for ( $i = $sel[1]; $i <= $sel[3]; $i++) {
			my $c = $self-> get_line( $i);
			$c .= ' ' x ($sel[2]-length($c))

				if length($c) < $sel[2];
			push( @lines, substr( $c, $sel[0], $sel[2]-$sel[0]));
		}
		my @cs = $self-> cursor;
		for ( $i = $cs[1]; $i < $cs[1] + scalar @lines; $i++) {
			my $c = $self-> get_line( $i);
			$c .= ' 'x($cs[0]-length($c)) if length($c) < $cs[0];
			substr( $c, $cs[0], 0) = $lines[ $i - $cs[1]];
			$self-> set_line( $i, $c);
		}
	}
	$self-> end_undo_group;
	$self-> unlock;
	$self-> lock_change(1);
}

sub overtype_block
{
	my $self = $_[0];
	return if

		$self-> {readOnly} ||

		$self-> {blockType} == bt::CUA ||

		$self-> {wordWrap} ||

		!$self-> has_selection;

	my @sel = $self-> selection;
	$self-> lock_change(0);
	$self-> lock;
	$self-> begin_undo_group;
	if ( $self-> {blockType} == bt::Horizontal) {
		my $i;
		for ( $i = $sel[1]; $i <= $sel[3]; $i++) {
			$self-> set_line( $i, $self-> get_line( $i));
		}
	} else {
		my @lines;
		my $i;
		for ( $i = $sel[1]; $i <= $sel[3]; $i++) {
			my $c = $self-> get_line( $i);
			$c .= ' ' x ($sel[2]-length($c)) if length($c) < $sel[2];
			push( @lines, substr( $c, $sel[0], $sel[2]-$sel[0]));
		}
		my @cs = $self-> cursor;
		my $bx = $sel[3] - $sel[1] + 1;
		for ( $i = $cs[1]; $i < $cs[1] + scalar @lines; $i++) {
			my $c = $self-> get_line( $i);
			$c .= ' ' x ($cs[0]-length($c))

				if length($c) < $cs[0];
			substr( $c, $cs[0], $bx) = $lines[ $i - $cs[1]];
			$self-> set_line( $i, $c);
		}
	}
	$self-> end_undo_group;
	$self-> unlock;
	$self-> lock_change(1);
}

sub split_line
{
	my $self = $_[0];
	my @cs = $self-> cursor;
	my $c = $self-> get_line( $cs[1]);
	$c .= ' 'x($cs[0]-length($c)) if length($c) < $cs[0];
	my ( $old, $new) = ( substr( $c, 0, $cs[0]), substr( $c, $cs[0], length( $c) - $cs[0]));
	$self-> lock_change(1);
	$self-> begin_undo_group;
	$self-> set_line( $cs[1], $old, q(delete), $cs[0], length( $c) - $cs[0]);
	my $cshift = 0;
	if ( $self-> {autoIndent}) {
		my $i = 0;
		my $add = '';
		for ( $i = 0; $i < length( $old); $i++) {
			my $c = substr( $old, $i, 1);
			last if $c ne ' ' and $c ne '\t';
			$add .= $c;
		}
		$new = $add.$new, $cshift = length( $add)

			if length( $add) < length( $old);
	}
	$self-> insert_line( $cs[1]+1, $new);
	$self-> cursor( $cshift, $cs[1] + 1);
	$self-> end_undo_group;
	$self-> lock_change(0);
}

sub begin_undo_group

{

	my $self = $_[0];
	return if !$self-> {undoLimit};
	if ( $self-> {undo_in_action}) {
		push @{$self-> {redo}}, [] unless $self-> {grouped_undo}++;
	} else {
		push @{$self-> {undo}}, [] unless $self-> {grouped_undo}++;
		$self-> {redo} = [] if !$self-> {redo_in_action};
	}
}

sub end_undo_group
{
	my $self = $_[0];
	return if !$self-> {undoLimit};

	my $ref = $self-> {undo_in_action} ? 'redo' : 'undo';
	$self-> {grouped_undo}-- if $self-> {grouped_undo} > 0;
	# skip last record if empty
	pop @{$self-> {$ref}}

		if !$self-> {grouped_undo} &&

			@{$self-> {$ref}} &&

			0 == @{$self-> {$ref}-> [-1]};
	shift @{$self-> {$ref}} if @{$self-> {$ref}} > $self-> {undoLimit};
}

sub push_undo_action
{
	my $self = shift;
	return if !$self-> {undoLimit};

	my $ref = $self-> {undo_in_action} ? 'redo' : 'undo';
	my $action = [ @_ ];
	if ( $self-> {grouped_undo}) {
		push @{$self-> {$ref}-> [-1]}, $action;
	} else {
		push @{$self-> {$ref}}, [ $action ];
		shift @{$self-> {$ref}} if @{$self-> {$ref}} > $self-> {undoLimit};
		$self-> {redo} = []

			if !$self-> {redo_in_action} && !$self-> {undo_in_action};
	}
}

sub push_group_undo_action
{
	my $self = shift;
	return if !$self-> {undoLimit};
	my $ref = $self-> {undo_in_action} ? 'redo' : 'undo';
	return $self-> push_undo_action(@_) if $self-> {grouped_undo};

	push @{$self-> {$ref}}, [] unless @{$self-> {$ref}};
	$self-> {grouped_undo} = 1;
	$self-> push_undo_action(@_);
	$self-> {grouped_undo} = 0;
}

sub undo
{
	my $self = $_[0];
	return if $self-> {undo_in_action} || !$self-> {undoLimit};
	return unless @{$self-> {undo}};
	my $group = pop @{$self-> {undo}};
	return unless $group && @$group;

	$self-> {undo_in_action} = 1;
	$self-> begin_undo_group;
	for ( reverse @$group) {
		my ( $method, @params) = @$_;
		next unless $self-> can($method);
		$self-> $method( @params);
	}
	$self-> end_undo_group;
	$self-> {undo_in_action} = 0;
}

sub redo
{
	my $self = $_[0];

	return if !$self-> {undoLimit};
	return unless @{$self-> {redo}};
	my $group = pop @{$self-> {redo}};
	return unless $group && @$group;

	$self-> {redo_in_action} = 1;
	$self-> begin_undo_group;
	for ( reverse @$group) {
		my ( $method, @params) = @$_;
		next unless $self-> can($method);
		$self-> $method( @params);
	}
	$self-> end_undo_group;
	$self-> {redo_in_action} = 0;
}

sub undoLimit
{
	return $_[0]-> {undoLimit} unless $#_;

	my ( $self, $ul) = @_;
	$self-> {undoLimit} = $ul if $ul >= 0;
	splice @{$self-> {undo}}, 0, $ul - @{$self-> {undo}} if @{$self-> {undo}} > $ul;
}

sub find
{
	my ( $self, $line, $x, $y, $replaceLine, $options) = @_;
	$x ||= 0;
	$y ||= 0;
	my $maxY = $self-> {maxLine};
	return if $y > $maxY || $maxY < 0;

	$line = '('.quotemeta( $line).')' unless $options & fdo::RegularExpression;
	$replaceLine = quotemeta( $replaceLine), $replaceLine =~ s[\\(\$\d+)][$1]g
		if !($options & fdo::RegularExpression) && defined $replaceLine;
	$y = $maxY if $y < 0;
	my $c = $self-> get_line( $y);
	my ( $l, $b, $len, $subLine, $re, $re2, $esub);
	$x = length( $c) if $x < 0;
	$re  = '/';
	$re .= '\\b' if $options & fdo::WordsOnly;
	$re .= "$line";
	$re .= '\\b' if $options & fdo::WordsOnly;
	$re .= '/';
	$re2 = '';
	$re2.= 'i' unless $options & fdo::MatchCase;

	unless ( $options & fdo::BackwardSearch) {
		$l = 0;
		$subLine = substr( $c, 0, $x);
		substr( $c, 0, $x) = '';
		$esub = eval(<<FINDER);
sub {
	\$_ = \$c;
	while ( 1) {
	if ( $re$re2) {
		\$l   = length(\$`);
		\$len = length(\$&);
		s$re$replaceLine/$re2 if defined \$replaceLine;
		return \$l+\$x, \$y, \$len, \$subLine.\$_;
	}
	\$y++;
	return if \$y > \$maxY;
	\$_ = \$self-> get_line( \$y);
	\$subLine = '';
	\$l = \$x = 0;
	}
}
FINDER
	} else {
		$re2 .= 'g';
		$l    = $b = undef;
		$subLine = substr( $c, $x, length( $c) - $x);
		substr( $c, $x, length( $c) - $x) = '';
		$esub = eval(<<FINDER);
sub {
	\$_ = \$c;
	while ( 1) {
		\$l = \$b, \$b = pos(\$_) while $re$re2;
		if ( defined \$b) {
			\$l ||= 0;
			pos = \$l;
			\$l = $re$re2;
			\$len = length(\$&);
			\$l   = pos(\$_) - \$len;
			substr(\$_, \$l, \$len) = \"$replaceLine\" if defined \$replaceLine;
			pos = undef;
			return \$l, \$y, \$len, \$_.\$subLine;
		}
		\$y--;
		return if \$y < 0;
		\$_ = \$self-> get_line( \$y);
		\$subLine = '';

}
FINDER
	}
	return $esub-> ();
}

sub add_marker
{
	my ( $self, $x, $y) = @_;
	push( @{$self-> {markers}}, [$x, $y]);
}

sub delete_marker
{
	my ( $self, $index) = @_;
	return if $index > scalar @{$self-> {markers}};
	splice( @{$self-> {markers}}, $index, 1);
}

sub select_all { $_[0]-> selection(0,0,-1,-1); }

sub autoIndent      {($#_)?($_[0]-> {autoIndent}    = $_[1])                :return $_[0]-> {autoIndent }  }
sub blockType       {($#_)?($_[0]-> set_block_type  ( $_[1]))               :return $_[0]-> {blockType}    }
sub cursor          {($#_)?($_[0]-> set_cursor    ($_[1],$_[2]))            :return $_[0]-> {cursorX},$_[0]-> {cursorY}}
sub cursorLog       {($#_)?($_[0]-> set_cursor    ($_[0]-> make_physical($_[1],$_[2])))            :return $_[0]-> {cursorXl},$_[0]-> {cursorYl}}
sub cursorX         {($#_)?($_[0]-> set_cursor    ($_[1],$_[0]-> {cursorY})):return $_[0]-> {cursorX}    }
sub cursorY         {($#_)?($_[0]-> set_cursor    ($_[0]-> {q(cursorX)},$_[1])):return $_[0]-> {cursorY}    }
sub cursorWrap      {($#_)?($_[0]-> {cursorWrap     }=$_[1])                :return $_[0]-> {cursorWrap     }}
sub topLine         {($#_)?($_[0]-> set_top_line (   $_[1]))               :return $_[0]-> {topLine }    }
sub hiliteNumbers   {($#_)?$_[0]-> set_hilite_numbers ($_[1])               :return $_[0]-> {hiliteNumbers} }
sub hiliteQStrings  {($#_)?$_[0]-> set_hilite_q_strings($_[1])              :return $_[0]-> {hiliteQStrings} }
sub hiliteQQStrings {($#_)?$_[0]-> set_hilite_qq_strings($_[1])             :return $_[0]-> {hiliteQQStrings} }
sub hiliteChars     {($#_)?$_[0]-> set_hilite_chars     ($_[1])             :return $_[0]-> {hiliteChars    } }
sub hiliteIDs       {($#_)?$_[0]-> set_hilite_ids       ($_[1])             :return $_[0]-> {hiliteIDs      } }
sub hiliteREs       {($#_)?$_[0]-> set_hilite_res       ($_[1])             :return $_[0]-> {hiliteREs      } }
sub insertMode      {($#_)?($_[0]-> set_insert_mode  (    $_[1]))           :return $_[0]-> {insertMode}   }
sub mark            {($#_)?(shift-> set_marking  (    @_   ))               :return exists $_[0]-> {anchor}  }
sub markers         {($#_)?($_[0]-> {markers}    = [@{$_[1]}])              :return $_[0]-> {markers  }    }
sub modified        {($#_)?($_[0]-> {modified }     = $_[1])                :return $_[0]-> {modified }    }
sub offset          {($#_)?($_[0]-> set_offset   (    $_[1]))               :return $_[0]-> {offset   }    }
sub persistentBlock {($#_)?($_[0]-> {persistentBlock}=$_[1])               :return $_[0]-> {persistentBlock}}
sub readOnly        {($#_)?($_[0]-> {readOnly }     = $_[1])                :return $_[0]-> {readOnly }    }
sub selection       {($#_)? shift-> set_selection   (@_)           : return (@{$_[0]-> {selStart}},@{$_[0]-> {selEnd}})}
sub selStart        {($#_)? $_[0]-> set_selection   ($_[1],$_[2],@{$_[0]-> {selEnd}}): return @{$_[0]-> {'selStart'}}}
sub selEnd          {($#_)? $_[0]-> set_selection   (@{$_[0]-> {'selStart'}},$_[1],$_[2]):return @{$_[0]-> {'selEnd'}}}
sub syntaxHilite    {($#_)? $_[0]-> set_syntax_hilite($_[1])                :return $_[0]-> {syntaxHilite}}
sub tabIndent       {($#_)?$_[0]-> set_tab_indent(    $_[1])                :return $_[0]-> {tabIndent}     }
sub textRef         {($#_)?$_[0]-> set_text_ref  (    $_[1])                :return $_[0]-> get_text_ref;   }
sub wantTabs        {($#_)?($_[0]-> {wantTabs}      = $_[1])                :return $_[0]-> {wantTabs}      }
sub wantReturns     {($#_)?($_[0]-> {wantReturns}   = $_[1])                :return $_[0]-> {wantReturns}   }
sub wordDelimiters  {($#_)?($_[0]-> {wordDelimiters}= $_[1])                :return $_[0]-> {wordDelimiters}}
sub wordWrap        {($#_)?($_[0]-> set_word_wrap(    $_[1]))               :return $_[0]-> {wordWrap }    }

1;

__END__

=pod

=head1 NAME

Prima::CodeManager::Edit - standard text editing widget

=head1 DESCRIPTION

This is intesively modified the original Prima::Edit module.
Please see details there: L<Prima::Edit>.

=head1 AUTHOR OF MODIFICATIONS

Waldemar Biernacki, E<lt>wb@sao.plE<gt>

=head1 COPYRIGHT AND LICENSE OF THE FILE MODIFICATIONS

Copyright 2009-2012 by Waldemar Biernacki.

L<http://CodeManager.sao.pl>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
