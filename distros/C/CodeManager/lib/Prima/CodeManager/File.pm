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
# Last modified (DMYhms): 14-01-2013 07:15:49.
################################################################################

package Prima::CodeManager::File;

use strict;
use warnings;

use File::Copy;

use Prima::CodeManager::Edit;
use Prima::CodeManager::Label;

my $findData;

#-------------------------------------------------------------------------------

eval "use Encode;";

################################################################################

sub file_new
{
	my ( $self ) = @_;
	$self-> file_edit ( './.Untitled' );
}

################################################################################

sub file_open
{
	my ( $self ) = @_;

	my @filtr;
	push @filtr, [ "All" => "*" ];
	my @ext = split /\|/, $self->{global}->{extensions};
	for ( @ext ) {
		push @filtr, [ "type $_" => "*.$_" ] if $_ !~ /all/i
	}
	my $nr = $Prima::CodeManager::developer{notes}-> pageIndex;
	my $dire_name = '.';
	my $file_name = $Prima::CodeManager::list_of_files[ $nr ] || '';
	if ( $file_name =~ /^(.*)([\\\/]+)([^\\\/]*)$/ ) {
		$dire_name = $1;
		$file_name = $3;
	}
	my $open = Prima::OpenDialog-> new(
		filter		=> [ @filtr ],
		directory	=> $dire_name,
		fileName	=> $file_name,
		system		=> 0,
		font => {
			name	=>	'DejaVu Sans Mono',
			size	=>	9,
			style	=>	fs::Normal,
		},
	);
	if ( $open-> execute() ) {
		my $fn = $open-> fileName();
		$self-> file_edit( $fn ) if -f $fn;
	}
}

################################################################################

sub file_edit
{
	my ( $self, $file, $branch ) = @_;

	my $ext = '';	$ext = lc($1) if $file =~ /\.(\w+)$/;

	if ( $self->{global}->{EXTERNAL_EDITORS}{$ext} ) {
		if ( $self->{global}->{EXTERNAL_EDITORS}{$ext} =~ /no edit!/ ) {
			Prima::MsgBox::message_box (
				'File edition',
				"Sorry! This file is not presumed for edition: $file", mb::OK );
			return;
		}
		my $editor = $self->{global}->{EXTERNAL_EDITORS}{$ext};
		my $error  = eval { system( $editor, $file ) };
		if ( $error ) {
			Prima::MsgBox::message_box (
				'Error calling external editor!',
				"Sorry! I have a problem with the command:\n\n$editor $file\n\nError: $!",

				mb::Cancel
			);
		}

		return;
	}

	$branch ||= 0;
	unless ( $Prima::CodeManager::all_extensions{$ext} ) {

		Prima::MsgBox::message_box (
			'Unknown file type in the current project!',
			"Sorry! I do not know how display the file - unknown type: $ext", mb::OK
		);
		$ext = 'pl';
	}
	my $short_file = $file;
	if ( $Prima::CodeManager::info_of_files{$file}->{exists} ) {
		for ( my $i = 0; $i < @Prima::CodeManager::list_of_files; $i++ ) {
			if ( $Prima::CodeManager::list_of_files[$i] eq $file ) {
				$Prima::CodeManager::developer{notes}-> pageIndex( $i ) ;
				$Prima::CodeManager::developer{"notes_$i"}-> focus ;
				return;
			}
		}
	}

	my ( $type_dimen, $font_dimen ) = ( 'size', 10 );
	if ( $self->{global}->{GLOBAL}{editor_fontHeight} && $self->{global}->{GLOBAL}{editor_fontHeight} > 0 ) {

		$type_dimen	= 'height';
		$font_dimen	=  $self->{global}->{GLOBAL}{editor_fontHeight};

	} elsif ( $self->{global}->{GLOBAL}{editor_fontSize} && $self->{global}->{GLOBAL}{editor_fontSize}> 0 ) {

		$type_dimen	= 'size';
		$font_dimen	=  $self->{global}->{GLOBAL}{editor_fontSize};
	}

	$self->{global}->{GLOBAL}{editor_fontName}  ||= 'DejaVu Sans Mono';
	$self->{global}->{GLOBAL}{editor_backColor} ||=  0xffffff;
	$self->{global}->{GLOBAL}{editor_lineSpace} ||=  0;

	my $cap = '';
	if ( $file && -e $file) {
		my $encoding = $self->{global}->{DIRECTORY}->{"encoding_$branch"} || $self->{global}->{GLOBAL}->{CodeManager_encoding};
		$Prima::CodeManager::file_encodings{$file} = $encoding;
		my $reading_parameters = $encoding ? ":encoding($encoding)" : '';
		if ( CORE::open ( my $FH, "<$reading_parameters", $file )) {
			if ( ! defined read( $FH, $cap, -s $file)) {
				Prima::MsgBox::message("Cannot read file $file:$!");
				$file = undef;
			}
			CORE::close $FH;
		}
		$cap =~ s/\r\n/\n/g;
		$cap =~ s/\r/\n/g;
	}
	my $type = 'nil';
	$type = lc($1) if $file =~ /\.(\w+)$/;
	$type = 'pl'   if $type eq 'pm' || !$Prima::CodeManager::all_extensions{$type};
#	my @ext = split /\|/, $self->{global}->{extensions};
#	for ( @ext ) {
		eval( $self->read_file( "$Prima::CodeManager::CodeManager_directory/hilite/hilite_$type.pl")) if -f "$Prima::CodeManager::CodeManager_directory/hilite/hilite_$type.pl";
		$::hilite{"rexp_$type"} = [] unless $::hilite{"rexp_$type"};
		$::hilite{"case_$type"} = 0  unless $::hilite{"case_$type"};
		$::hilite{"styl_$type"} = 0  unless $::hilite{"styl_$type"};
		$::hilite{"blok_$type"} = [] unless $::hilite{"blok_$type"};
#	}
	push @Prima::CodeManager::list_of_files, ( $short_file );
#	$Prima::CodeManager::info_of_files{$file}->{backColor} =
#		$Prima::CodeManager::warpColors[ $Prima::CodeManager::file_number % scalar @Prima::CodeManager::warpColors ];

	$Prima::CodeManager::info_of_files{$file}->{backColor} =
			Prima::CodeManager::Misc::angle_color(undef,int(rand(360)), 250,150 );

#		Prima::CodeManager::Misc::licz_kolor (
#			undef,
#			0xffffff,
#			Prima::CodeManager::Misc::angle_color(undef,int(rand(360)), 255, 200 ),
#			0
#		);

	$Prima::CodeManager::file_number++;
	my $pageCount = $Prima::CodeManager::developer{notes}->pageCount;
	$pageCount    = 0 unless $pageCount;
	$Prima::CodeManager::developer{notes}->set_tabs( @Prima::CodeManager::list_of_files );

	Prima::CodeManager::Notebook::insert_page( $Prima::CodeManager::developer{notes}, $pageCount );
	my $kolor_paska = $self->licz_kolor( 0xffffff, $Prima::CodeManager::info_of_files{$file}->{backColor} , 0.75 );
	my $kolor_posre = $self->licz_kolor( $kolor_paska, 0x888888, 0.5 );
	my $szer = 5;
	for ( my $k = 0; $k <= $szer; $k++ ) {
		$Prima::CodeManager::developer{ "space_$pageCount-$k-1" } = $Prima::CodeManager::developer{notes}->insert_to_page (
			$pageCount,
			Label	=>
			text			=>	'',
			backColor		=>	$self->licz_kolor(
				$kolor_paska,
				$Prima::CodeManager::info_of_files{$file}->{backColor},
				($szer-$k)/$szer
			),
			light3DColor	=>	0x000000,
			dark3DColor		=>	0x000000,
			borderWidth		=>	0,
			autoWidth		=>	0,
			place => {
				x => 55 - $szer + $k,	relx => 0.0,	width  => 1,	relwidth  => 0,
				y =>  0,				rely => 0.5,	height => 0,	relheight => 1,
			},
		);
		$Prima::CodeManager::developer{ "space_$pageCount-$k-2" } = $Prima::CodeManager::developer{notes}->insert_to_page(
			$pageCount,
			Label	=>
			text		=>	'',
			backColor	=>	$self->licz_kolor(
				$Prima::CodeManager::info_of_files{$file}->{backColor},
				$self->{global}->{GLOBAL}{editor_backColor},
				($szer-$k)/$szer,
			),
			light3DColor=>	0x000000,
			dark3DColor	=>	0x000000,
			borderWidth	=>	0,
			autoWidth	=>	0,
			place => {
				x => 67 - 2*$szer + 2*$k,	relx => 0.0,	width  => 2,	relwidth  => 0,
				y =>  0,					rely => 0.5,	height => 0,	relheight => 1,
			},
		);
	}

	$Prima::CodeManager::developer{ "numer_$pageCount" } = $Prima::CodeManager::developer{notes}->insert_to_page(
		$pageCount,
		'CodeManager::Label'	=>
		text			=>	'',
		backColor		=>	$kolor_paska,
		light3DColor	=>	0x000000,
		dark3DColor		=>	0x000000,
		borderWidth		=>	0,
		alignment		=>	ta::Right,
		autoWidth		=>	0,
		lineSpace		=>	$self->{global}->{GLOBAL}{editor_lineSpace},
		place => {
			x => 25,	relx => 0.0,	width  => 50,	relwidth  => 0,
			y =>  0,	rely => 0.5,	height =>  0,	relheight => 1,
		},
		font => {
			name	=>	$self->{global}->{GLOBAL}{editor_fontName},
			$type_dimen	=>	$font_dimen,
			style	=>	fs::Normal,
		},
	);

	$Prima::CodeManager::developer{ "notes_$pageCount" } = $Prima::CodeManager::developer{notes}->insert_to_page(
		$pageCount,
		'CodeManager::Edit'	=>
		name			=>	"Edit_$pageCount",
		title			=>	$file,
		textRef			=>	\$cap,
		hScroll			=>	1,
		vScroll			=>	1,
		tabIndent		=>	4,
		syntaxHilite	=>	1,
		hiliteREs		=>	$::hilite{"rexp_$type"},
		hiliteCase		=>	$::hilite{"case_$type"},
		hiliteStyl		=>	$::hilite{"styl_$type"},
		hiliteBlok		=>	$::hilite{"blok_$type"},
		exportHTML		=>	0,
		backColor		=>	$self->{global}->{GLOBAL}{editor_backColor},
		borderWidth		=>	0,
		cursorWrap		=>	1,
		scope			=>	fds::Cursor,
		lineSpace		=>	$self->{global}->{GLOBAL}{editor_lineSpace},
		wheelRows		=>	5,
		place => {
			x => 33,	relx => 0.5,	width  =>-66,	relwidth  => 1,
			y => 0,		rely => 0.5,	height =>0,		relheight => 1,
		},
		font => {
			name	=>	$self->{global}->{GLOBAL}{editor_fontName},
			$type_dimen	=>	$font_dimen,
#			name	=>	$fontName,
#			size	=>	$fontSize,
			style	=>	fs::Normal,
		},
	);

	$Prima::CodeManager::info_of_files{$file}->{exists} = 1;
	$Prima::CodeManager::developer{notes}-> tabIndex($pageCount);
	$Prima::CodeManager::developer{"notes_$pageCount"}-> focus;

}

########################################################################################

sub file_close
{
	my ( $self ) = ( shift );

	my $nr = $Prima::CodeManager::developer{notes}-> pageIndex;
	if ( $nr >= 0 ) {
		if ( $Prima::CodeManager::developer{ "notes_$nr" }-> modified) {
			my $r =  Prima::MsgBox::message_box (
				'File not saved! ',
				'File '.$Prima::CodeManager::list_of_files[$nr].' has been modified.  Save?', mb::YesNoCancel | mb::Warning
			);
			$self-> clear_event, return if mb::Cancel == $r;
			$self-> clear_event, return unless $self->file_save_batch( $nr );
		}

		$Prima::CodeManager::developer{notes}-> tabIndex($nr);
		for ( my $i = $nr; $i < $Prima::CodeManager::developer{notes}->pageCount - 1; $i++ ) {
			for ( $Prima::CodeManager::developer{notes}-> widgets_from_page( $i ) ) {
				$Prima::CodeManager::developer{notes}-> delete_widget ( $_ );
			}
			my $hn = $i + 1;
			for ( $Prima::CodeManager::developer{notes}-> widgets_from_page( $hn ) ) {
				$Prima::CodeManager::developer{notes}-> move_widget ( $_, $i );
				$Prima::CodeManager::developer{notes}-> widget_set( $_,
					visible => 1,
					autoEnableChildren => 1,
					enabled => 1,
					geometry => gt::Default,
				);
				my $k = 0;
				while ( $Prima::CodeManager::developer{ "space_$i-$k-1" } ) {
					$Prima::CodeManager::developer{ "space_$i-$k-1" } = $Prima::CodeManager::developer{ "space_$hn-$k-1" };
					$Prima::CodeManager::developer{ "space_$i-$k-2" } = $Prima::CodeManager::developer{ "space_$hn-$k-2" };
					$k++;
				}
				$Prima::CodeManager::developer{ "numer_$i" } = $Prima::CodeManager::developer{ "numer_$hn" };
				$Prima::CodeManager::developer{ "notes_$i" } = $Prima::CodeManager::developer{ "notes_$hn" };
			}
		}
		Prima::CodeManager::Notebook::delete_page( $Prima::CodeManager::developer{notes}, $nr, 1 ) ;
		delete $Prima::CodeManager::info_of_files{ $Prima::CodeManager::list_of_files[$nr] };
		splice( @Prima::CodeManager::list_of_files, $nr, 1 );
		$Prima::CodeManager::developer{notes}-> set_tabs( @Prima::CodeManager::list_of_files );
		$Prima::CodeManager::developer{notes}-> repaint;
	}
}

########################################################################################

sub file_save
{
	my ( $self ) = @_;

	my $nr = $Prima::CodeManager::developer{notes}-> pageIndex;

	$self-> file_save_batch ( $nr );
}

########################################################################################

sub file_save_as
{
	my ( $self ) = ( shift );

	my $nr = $Prima::CodeManager::developer{notes}-> pageIndex;
	my $dire_name = '.';
	my $file_name = $Prima::CodeManager::list_of_files[ $nr ] || '';
	if ( $file_name =~ /^(.*)([\\\/]+)([^\\\/]*)$/ ) {
		$dire_name = $1;
		$file_name = $3;
	}
	my $fn = Prima::save_file(
		directory	=> $dire_name,
		fileName	=> $file_name,
		system		=> 0,
		font => {
			name	=>	'DejaVu Sans Mono',
			size	=>	9,
			style	=>	fs::Normal,
		},
	);
	my $ret = 0;
	if ( defined $fn ) {
		SAVE:
		while(1) {
			next SAVE unless CORE::open my $FH, '>', $fn;
			my $white_trimming = $self->{global}->{GLOBAL}{white_trimming} || $Prima::CodeManager::_OS;
			my $cap = $Prima::CodeManager::developer{ "notes_$nr" }->text();
			$cap  =~ s/[ \r\t]+$//mgs;
			$cap .= "\n" unless $cap =~ /\n$/s;
			$cap  =~ s/\n/\r\n/mgs if $white_trimming =~ /windows/;

			my $modified= $self->czas('DD-MM-YYYY h:m:s');
			my $year_to	= $self->czas('YYYY');
			my $today	= $self->czas('DD-MM-YYYY');
			$cap =~ s/Waldemar Biernacki, (20\d{2})-20\d{2}/Waldemar Biernacki, $1-$year_to/g;
			$cap =~ s/Last modified \(DMYhms\): [^\$\.]*\./Last modified \(DMYhms\): $modified\./;
			$cap =~ s/This version date: \d{2}-\d{2}-\d{4}/This version date: $today/;
			$cap = encode( $Prima::CodeManager::file_encodings{$fn} , $cap ) if $Prima::CodeManager::file_encodings{$fn};
			my $swr = syswrite( $FH, $cap,length($cap));
			CORE::close $FH;

			unless ( defined $swr && $swr == length($cap)) {
				undef $cap;
				unlink $fn;
				next SAVE;
			}
			undef $cap;
			$Prima::CodeManager::developer{ "notes_$nr" }-> modified(0);
			$Prima::CodeManager::list_of_files[ $nr ] = $fn;
			$Prima::CodeManager::developer{notes}-> set_tabs( @Prima::CodeManager::list_of_files );
			$Prima::CodeManager::developer{notes}-> repaint;
			$ret = 1;
			last;
		} continue {
			last SAVE unless
				mb::Retry == Prima::MsgBox::message_box( $fn, "Cannot save to $fn", mb::Error|mb::Retry|mb::Cancel );
		}
	}
	return $ret;
}

########################################################################################

sub file_save_batch
{
	my ( $self, $nr ) = (shift,shift);
	$nr = $Prima::CodeManager::developer{notes}-> pageIndex unless defined $nr;
	my $fn = $Prima::CodeManager::list_of_files[ $nr ];

	$fn =~  s/^\*//;
	return $self->file_save_as if $fn eq './.Untitled';

	my $white_trimming = $self->{global}->{GLOBAL}{white_trimming} || $Prima::CodeManager::_OS;

	if ( CORE::open my $FH, '>', $fn ) {
		my $cap = $Prima::CodeManager::developer{ "notes_$nr" }->text();
		$cap  =~ s/[ \r\t]+$//mgs;
		$cap .= "\n" unless $cap =~ /\n$/s;
		$cap  =~ s/\n/\r\n/mgs if $white_trimming =~ /windows/;

		my $modified = $self->czas('DD-MM-YYYY h:m:s');
		my $year_to  = $self->czas('YYYY');
		my $today    = $self->czas('DD-MM-YYYY');
		$cap =~ s/Waldemar Biernacki, (20\d{2})-20\d{2}/Waldemar Biernacki, $1-$year_to/g;
		$cap =~ s/Last modified \(DMYhms\): [^\$\.]*\./Last modified \(DMYhms\): $modified\./g;
		$cap =~ s/This version date: \d{2}-\d{2}-\d{4}/This version date: $today/g;
		$cap = encode( $Prima::CodeManager::file_encodings{$fn} , $cap ) if $Prima::CodeManager::file_encodings{$fn};
		my $swr = syswrite( $FH, $cap, length( $cap ));
		CORE::close $FH;

		unless (defined $swr && $swr == length( $cap )) {
			undef $cap;
			unlink $fn;
			Prima::MsgBox::message_box( $fn, "Cannot save to $fn", mb::Error|mb::OK);
			return 0;
		}
		undef $cap;

		$Prima::CodeManager::developer{ "notes_$nr" }-> modified(0);
		$Prima::CodeManager::list_of_files[ $nr ] = $fn;
		$Prima::CodeManager::developer{notes}-> set_tabs( @Prima::CodeManager::list_of_files );

		return 1;

	} else {

		Prima::MsgBox::message_box( $fn, "Cannot save to $fn", mb::Error|mb::OK);
	}

	return 0;
}

################################################################################

sub hilite_open
{
	my ( $self ) = @_;

	my $nr  = $Prima::CodeManager::developer{notes}-> pageIndex;
	my $hfn = '';
	$hfn = "hilite_$1.pl" if ( $Prima::CodeManager::list_of_files[ $nr ] =~ /\.(\w+)$/ );
	my $fn = Prima::open_file(
		directory => './hilite/',
		fileName  => $hfn,
		system    => 0,
	);
	edit( $fn ) if $fn;
}

########################################################################################

sub show_size
{
	my ( $self, $size, $glue ) = @_;
	return unless $size == 1 || $size == 0 || $size == -1;
	return unless $glue == 1 || $glue == 0 || $glue == -1;
	return unless $size != 0 || $glue != 0;

	my $i = $Prima::CodeManager::developer{notes}-> pageIndex;

	$size = $Prima::CodeManager::developer{ "notes_$i" }-> font-> size + $size;
	$size = 1 if $size < 1;
	$glue = $Prima::CodeManager::developer{ "notes_$i" }-> {lineSpace} + $glue;
	$glue = 1 - $size if $glue < 1 - $size;

	$Prima::CodeManager::developer{ "notes_$i" }-> font-> size( $size );
	$Prima::CodeManager::developer{ "notes_$i" }-> {lineSpace} = $glue;
	$Prima::CodeManager::developer{ "notes_$i" }-> repaint;

	$Prima::CodeManager::developer{ "numer_$i" }-> font-> size( $size );
	$Prima::CodeManager::developer{ "numer_$i" }-> {lineSpace} = $glue;
	$Prima::CodeManager::developer{ "numer_$i" }-> repaint;
}

########################################################################################

sub show_tab
{
	my ( $self, $step ) = @_;
	return unless $step == 1 || $step == -1;
	my $next = $Prima::CodeManager::developer{notes}-> pageIndex + $step;
	$next = 0 if $next >= $Prima::CodeManager::developer{notes}-> pageCount;
	$next = $Prima::CodeManager::developer{notes}-> pageCount - 1 if $next < 0;
	$Prima::CodeManager::developer{notes}-> tabIndex($next);
}

########################################################################################

sub jump
{
	my ( $self ) = ( shift );
#	my $this = $Prima::CodeManager::developer{ "notes_".$Prima::CodeManager::developer{notes}->pageIndex };
#	undef $self-> {findData};
	$self-> find_dialog( 1 );
	$self-> do_find;
}
########################################################################################
sub find
{
	my ( $self ) = ( shift );
#	my $this = $Prima::CodeManager::developer{ "notes_".$Prima::CodeManager::developer{notes}->pageIndex };
#	undef $self-> {findData};
	$self-> find_dialog( 1 );
	$self-> do_find;
}
#--------------------------------------------------------------------------------------
sub find_dialog
{
	my ( $self ) = ( shift );
	my $findStyle = $_[0];
	my $this = $Prima::CodeManager::developer{ "notes_".$Prima::CodeManager::developer{notes}->pageIndex };
	my %prf;
	%{$findData} = (
		replaceText  => '',
		findText     => $this-> get_selected_text,
		replaceItems => [],
		findItems    => [],
		options      => 0,
		scope        => fds::Cursor,
	) unless defined $findData;
	$findData->{findText} = $this-> get_selected_text;
	my $fd = $findData;
	my @props = qw(findText options scope);
	push( @props, q(replaceText)) unless $findStyle;
	if ( $fd) { for( @props) { $prf{$_} = $fd-> {$_}}}
	my $findDialog = Prima::FindDialog-> create;
	$findDialog-> set( %prf, findStyle => $findStyle);
	$findDialog-> Find-> items($fd-> {findItems});
	$findDialog-> Replace-> items($fd-> {replaceItems}) unless $findStyle;
	my $ret = 0;
	my $rf  = $findDialog-> execute;
	if ( $rf != mb::Cancel) {
		{ for( @props) { $findData-> {$_} = $findDialog-> $_()}}
		$findData-> {result} = $rf;
		$findData-> {asFind} = $findStyle;
##############
		my @pozycje = @{$findDialog-> Find-> items};
		my @newitems;
		for ( my $i = 0 ; $i < @pozycje; $i++ ) {
			my $czy = 1;
			for ( my $j = 0 ; $j < $i; $j++ ) {
				$czy = 0 if lc($pozycje[$i]) eq lc($pozycje[$j]);
				last unless $czy;
			}
			push @newitems, $pozycje[$i] if $czy;
		}
##############
		@{$findData-> {findItems}} = @newitems;
#		@{$findData-> {findItems}} = @{$findDialog-> Find-> items};
		@{$findData-> {replaceItems}} = @{$findDialog-> Replace-> items}
			unless $findStyle;
		$ret = 1;
	}
	return $ret;
}
#--------------------------------------------------------------------------------------
sub do_find
{
	my ( $self ) = ( shift );
	my $e = $Prima::CodeManager::developer{ "notes_".$Prima::CodeManager::developer{notes}-> pageIndex };
#	my $e = $this;
#	my $p = $this-> {findData};
	my $p = $findData;
	my @scope;
	FIND:{
		if ( $$p{scope} != fds::Cursor) {
			if ( $e-> has_selection) {
				my @sel = $e-> selection;
				@scope = ($$p{scope} == fds::Top) ? ($sel[0],$sel[1]) : ($sel[2], $sel[3]);
			} else {
				@scope = ($$p{scope} == fds::Top) ? (0,0) : (-1,-1);
			}
		} else {
			@scope = $e-> cursor;
		}
		my @n = $e-> find( $$p{findText}, @scope, $$p{replaceText}, $$p{options});
		if ( !defined $n[0]) {
			Prima::MsgBox::message( "No more matches found!" , mb::NoSound | mb::Information );
			return;
		}
		$e-> cursor(($$p{options} & fdo::BackwardSearch) ? $n[0] : $n[0] + $n[2], $n[1]);
		$e-> selection( $n[0], $n[1], $n[0] + $n[2], $n[1]);
		unless ( $$p{asFind}) {
			if ( $$p{options} & fdo::ReplacePrompt) {
				my $r = Prima::MsgBox::message_box( "Replace...","Replace text '$$p{findText}'?", mb::YesNoCancel|mb::Information|mb::NoSound);
#				my $r = Prima::MsgBox::message_box( $e-> text,
#				"Replace this text?",
#				mb::YesNoCancel|mb::Information|mb::NoSound);
				redo FIND if ($r == mb::No) && ($$p{result} == mb::ChangeAll);
				last FIND if $r == mb::Cancel;
			}
			$e-> set_line( $n[1], $n[3]);
			redo FIND if $$p{result} && $$p{result} == mb::ChangeAll;
		}
	}
}
#-------------------------------------------------------------------------------
sub find_next
{
	my ( $self ) = ( shift );
#	my ( $this ) = ( $Prima::CodeManager::developer{ "notes_".$Prima::CodeManager::developer{notes}->pageIndex } );
#	return unless $this-> {findData};
	return unless $findData;
	$self-> do_find;
}
#-------------------------------------------------------------------------------
sub replace
{
	my ( $self ) = ( shift );
#	my ( $self ) = ( $d::eveloper{ "notes_".$Prima::CodeManager::developer{notes}->pageIndex } );
	return unless find_dialog(0);
	$self-> do_find;
}
################################################################################
sub about
{
	my ( $self ) = @_;
	my $project_color = 0x0088ff;
	my @dim = ( 360, 170 );
#	my $img = $self-> load_icon( "$::Prima::CodeManager::CodeManager_directory/img/CodeManager64.png" );
	my $tmp_popup = Prima::Dialog-> create(
		icon => $self-> load_icon( "$Prima::CodeManager::CodeManager_directory/img/cm64.png" ),
		title		=> "CodeManager - About",
		text		=> "CodeManager - About",
		size		=>	[ @dim ],
		origin		=>	[ 0, 0 ],
		borderIcons	=>  bi::SystemMenu,
		centered	=>	1,
#		borderStyle	=> bs::None,
		backColor	=> $self->licz_kolor( 0xffffff, $project_color, 0.5, 0 ),
		onPaint => sub {
			my ( $this, $canvas) = @_;
			$canvas-> clear;
			$canvas-> color( $self->licz_kolor( 0xffffff, $project_color, 0.2, 0 ) );
			$canvas-> bar( 0, 0, $this-> width, $this-> height);
			my $margin = 2;
			my $width  = 1;
			$canvas-> color( $self->licz_kolor( 0xffffff, $project_color, 0.8, 0 ) );
			$canvas-> fillpoly([
				$margin,						$margin,
				$margin,						$this-> height - $margin - 1,
				$this-> width - $margin - 1,	$this-> height - $margin - 1,
				$this-> width - $margin - 1,	$margin
			]);
			$canvas-> color( $self->licz_kolor( 0xffffff, $project_color, 0.5, 0 ) );
			$canvas-> fillpoly([
				$margin + $width,						$margin + $width,
				$margin + $width,						$this-> height - $margin - 1 - $width,
				$this-> width - $margin - 1 - $width,	$this-> height - $margin - 1 - $width,
				$this-> width - $margin - 1 - $width,	$margin + $width
			]);
#			$canvas-> put_image( $dim[0]/2-64, $dim[1] - 64 - 10, $img );
		},
	);
	my $height = 18;
	$tmp_popup-> insert (
		Label	=>
		origin		=>	[ 10, $dim[1]-15 - $height ],
		size		=>	[ $dim[0]-20, $height ],
		text		=>	"This is CodeManager, ver. $Prima::CodeManager::VERSION",
		flat		=>	1,
		x_centered	=> 1,
		alignment	=>	ta::Center,
		color		=>	$self->licz_kolor( 0x000000, $project_color, 0.6, 0 ),
		borderWidth	=>	1,
		font 		=>	{
			height	=>	$height,
			style	=>	fs::Bold,
		},
	);
	my $about = "Copyright 2009-2013 by Waldemar Biernacki\n" .
		"http://codemanager.sao.pl\n" .
		"\n" .
		"\nLicense statement:\n" .
		"This program/library is free software; you can redistribute it\n" .
		"and/or modify it under the same terms as Perl itself.";
	$tmp_popup->insert( Label =>
		origin		=>	[ 10, 30 ],
		size		=>	[ $dim[0] - 20, $dim[1] - 75 ],
		text		=>	$about,
		flat		=>	1,
		x_centered	=>	1,
		alignment	=>	ta::Center,
		color		=>	$self->licz_kolor( 0x000000, $project_color, 0.6, 0 ),
		borderWidth	=>	1,
		font 		=>	{ size=>8, style=>fs::Normal, },
	);
	$tmp_popup->insert( Button =>
		origin		=>	[ int($dim[0]/2) - 40, 10 ],
		size		=>	[ 80, 20 ],
		text		=>	'OK',
		enabled		=>	1,
		flat		=>	0,
		color		=>	0x000000,
		color		=>	0xffffff,
		borderWidth	=>	1,
		borderColor =>	0xffffff,
		backColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.3, 0 ),
		font 		=>	{	size	=>	9,	style	=>	fs::Normal,	},
		onClick	=>	sub { $tmp_popup->close; },
	);
	$tmp_popup->execute;
	return;
}
1;
__END__

=pod

=head1 NAME

Prima::CodeManager::File - functions to open, read, save and close project files

=head1 DESCRIPTION

This is part of CodeManager project - not for direct use.

=head1 AUTHOR

Waldemar Biernacki, E<lt>wb@sao.plE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2013 by Waldemar Biernacki.
L<http://codemanager.sao.pl>
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
