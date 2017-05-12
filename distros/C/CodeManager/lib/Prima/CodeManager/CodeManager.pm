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
# Last modified (DMYhms): 14-01-2013 07:25:17.
################################################################################

package Prima::CodeManager::CodeManager;

our $VERSION  = '0.05';

1;

#######################################################################

package Prima::CodeManager;

use strict;
use warnings;

use Cwd;

use Prima qw(Application);
use Prima::Buttons;
use Prima::FileDialog;
use Prima::FrameSet;
use Prima::ExtLists;
use Prima::ImageViewer;
use Prima::MsgBox;
use Prima::ScrollWidget;
use Prima::StdDlg;


use Prima::CodeManager::Outlines;
use Prima::CodeManager::Notebooks;
use Prima::CodeManager::Label;
use Prima::CodeManager::Image;

use base "Prima::CodeManager::Misc";
use base "Prima::CodeManager::File";
#use base "Prima::CodeManager::Remote";

use File::Copy;
use File::Path qw(make_path remove_tree);
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove);
use File::HomeDir;

our $VERSION  = '0.04';

########################################################################################

my ( $screen_width, $screen_height ) = $::application->size;
$::application-> wantUnicodeInput(1);

#-------------------------------------------------------

#setting OS
our $_OS;
	$_OS = 'unknown';
	$_OS = 'os'      if $::application-> get_system_info()->{apc} == 1;
	$_OS = 'windows' if $::application-> get_system_info()->{apc} == 2;
	$_OS = 'linux'   if $::application-> get_system_info()->{apc} == 3;

#-------------------------------------------------------
our $CodeManager_encoding  = '';
#-------------------------------------------------------

#setting CodeManager.pm directory
our $CodeManager_directory = '';

if ( $PerlApp::BUILD ) {

#	$CodeManager_directory  = PerlApp::exe();
#	$CodeManager_directory  =~ s/(\\|\/)[^\\\/]*\.exe$//;
#	$CodeManager_directory .= '/Prima/CodeManager';
	$CodeManager_directory  = 'Prima/CodeManager';

} else {

	$CodeManager_directory =  $INC{'Prima/CodeManager/CodeManager.pm'};
	$CodeManager_directory =~ s/\/CodeManager\.pm$//;
}

#print "CodeManager_directory=$CodeManager_directory\n";

#-------------------------------------------------------

#setting user home directory
our $home_directory = File::HomeDir-> my_home.'/.CodeManager';

#-------------------------------------------------------

our %developer;
our %info_of_files;
our @list_of_files;
our %file_encodings; #this is a hash of the files encodings
our %all_extensions;
our $file_number = 0;

my $popup;

#-------------------------------------------------------
my $int_color = int(rand(360));
my $int_white = 170;
my $int_black =  40;
my $project_color = Prima::CodeManager::Misc::angle_color( undef, $int_color, $int_white, $int_black );

#-------------------------------------------------------

sub new
{
	my ( $project ) = ( shift );
	my $this = {};
	bless ( $this, $project );

	use Prima::Application (
		title		=>	'CodeManager',
		wantUnicodeInput => 1,
		hintFont	=>	{
			name	=>	'DejaVu Sans',
			size	=>	10,
			style	=>	fs::Italic,
		},
		font		=> {
			name	=>	'DejaVu Sans',
			size	=>	10,
			style	=>	fs::Normal,
		},
	);
#-------------------------------------------------------
	$this-> create_user_home_directory ( $home_directory ) unless -d "$home_directory";
	Prima::message ( "I can't create your CodeManager home directory:\n$home_directory" ) unless -d $home_directory;
#-------------------------------------------------------
	my $DIR;
	#reading names of the hiliting files in "Prima/CodeManager/hilite" subdirectory:
	my @hilite_files = [];
	my @hilite_files_ext; # = <$CodeManager_directory/hilite/hilite_*.pl>; (doesn't work on Windows)
	if ( opendir $DIR, "$CodeManager_directory/hilite" ) {

		@hilite_files_ext = sort grep { $_ =~ /hilite_\w+\.pl/ } readdir $DIR;
		closedir $DIR;
	}

##################################################

	for ( my $i = 0; $i < @hilite_files_ext; $i++ ) {
		if ( $hilite_files_ext[$i] =~ /hilite_(\w+)\.pl/ ) {
			my $ext = $1;
			$hilite_files[$i] = [ $1 => sub { $this->file_edit ( "$CodeManager_directory/hilite/hilite_$ext.pl" ) } ];
			eval ( $this-> read_file( "$CodeManager_directory/hilite/hilite_$ext.pl" ));
			$all_extensions{$ext} = $ext if $ext;
			$all_extensions{'pm'} = 'pm' if $ext eq 'pl';
		}
	}
#-------------------------------------------------------

	#reading images:
	my @images_files_ext; # = <$CodeManager_directory/img/*.png>;
	if ( opendir $DIR, "$CodeManager_directory/img" ) {
		@images_files_ext = sort grep { $_ =~ /\.png/ } readdir $DIR;
		closedir $DIR;
	}
	for ( my $i = 0; $i < @images_files_ext; $i++ ) {
		if ( $images_files_ext[$i] =~ /(\w+)\.png$/ ) {
			$this->{images}->{$1} = $this-> load_icon( "$CodeManager_directory/img/$1.png" );
			$this->{images}->{$1} = $this-> load_icon( "$CodeManager_directory/img/nil.png" ) unless $this->{images}->{$1};
		}
	}
#-------------------------------------------------------
	#reading names of the projects file names in the user CodeManager home "~/.CodeManager/projects" subdirectory:
	my @projects_files_open;
	my @projects_files_edit;
	my @projects_files_name;
	if ( opendir $DIR, "$home_directory/projects" ) {
		@projects_files_name = sort grep { $_ =~ /\.cm/ } readdir $DIR;
		closedir $DIR;
	}
	my $_group = '`';
	my @files_open;
	my @files_edit;
	foreach ( sort map {
		if ( $_ =~ /([^\/]+)\.cm/ ) {
			my $content = $this-> read_file( "$home_directory/projects/$1.cm" );
			my ( $group, $name, $file ) = ( '', $_, $1 );
			$group = $1 if $content =~ /\n\s*group\s*=\s*\b(.*)\b\s*\n/;
			$name  = $1 if $content =~ /\n\s*name\s*=\s*\b(.*)\b\s*\n/;
			$_ = "$group`$name`$file";
		}
	} @projects_files_name ) {
		if ( $_ =~ /(.*)`(.*)`(.*)/ ) {
			my ( $group, $name, $file ) = ( $1, $2, $3 );
			if ( $_group && $_group ne $group && $_group ne '`' ) {
				push @projects_files_open, [ $_group => [ @files_open ]];
				push @projects_files_edit, [ $_group => [ @files_edit ]];
				undef @files_open;
				undef @files_edit;
			}
			$_group = $group;
			push @files_open, [ $name => sub { $this-> open      ( "$home_directory/projects/$file.cm" )}];
			push @files_edit, [ $name => sub { $this-> file_edit ( "$home_directory/projects/$file.cm" )}];
		}
	}
	push @projects_files_open, [ $_group => [ @files_open ]];
	push @projects_files_edit, [ $_group => [ @files_edit ]];

#print Dumper(@projects_files_edit);

#	for ( my $i = 0; $i < @projects_files_name; $i++ ) {
#		if ( $projects_files_name[$i] =~ /([^\/]+)\.cm/ ) {
#			my $name = $1;
#			if ( -f "$home_directory/projects/$name.cm" ) {
#				my $content = $this-> read_file( "$home_directory/projects/$name.cm" );
#				$name = $1 if $content =~ /\n\s*name\s*=\s*\b(.*)\b\s*\n/;
#				$projects_files_open[$i] = [ $name => sub { $this-> open ( "$home_directory/projects/$name.cm" )}];
#				$projects_files_edit[$i] = [ $name => sub { $this-> file_edit ( "$home_directory/projects/$name.cm" )}];
#			}
#		}
#	}
#-------------------------------------------------------
	$this->{mw} = Prima::MainWindow-> create(
		icon => $this-> load_icon( "$CodeManager_directory/img/cm32.png" ),
		name		=>	'CodeManager',
		text		=>	'CodeManager',
		title		=>	'CodeManager',
		size		=>	[[$::application-> size]->[0]-400, [$::application-> size ]->[1]-300],
		origin		=>	[ 0, 300 ],
		centered	=>	1,
		menuFont	=>	{
			name	=>	'DejaVu Sans',
			size	=>	9,
			style	=>	fs::Normal,
		},
		menuBackColor => $this->licz_kolor( 0xffffff, $project_color, 0.3 ),
		menuItems => [
			[ '~System' => [
				[ '~Hiliting Files'		=> [ @hilite_files ]],
				[ '~Meld'				=> 'AltM'			=> '@M'		=> sub { $this-> meld }],
#				[ '~Hiliting Files'		=> 'CtrlH'			=> '^H'		=> sub { &hilite_open }]
#				],
				[],
				[ 'E~xit'				=> 'AltX'			=> '@X'		=> sub { $::application-> close}],
			]],
			[ '~Project' => [
				[ '~Open project'		=> [ @projects_files_open ]],
				[],
				[ '~Open from disk'		=> 'F4'				=> 'F4'		=> sub { $this-> open }],
				[ '~Refresh'			=> 'F5'				=> 'F5'		=> sub { $this-> make_tree }],
				[ '~Save'				=> 'F2'				=> 'F2'		=> sub { $this-> save }],
				[],
				[ '~Edit projects files'=> [ @projects_files_edit ]],
			]],
			[ '~Edit' => [
				[ 'Undo'				=> 'CtrlZ'			=> '^Z',					q(undo)],
				[ 'Undo'				=> 'AltBackspace'	=>	km::Alt|kb::Backspace,	q(undo)],
				[ 'Redo'				=> 'CtrlD'			=> '^D',					q(redo)],
			]],
			[ '~File' => [
				[ '~New'				=> 'CtrlN'			=> '^N'		=> sub { $this-> file_new($this) } ],
				[ '~Open...'			=> 'CtrlO'			=> '^O'		=> sub { $this-> file_open } ],
				[ '~Save'				=> 'CtrlS'			=> '^S'		=> sub { $this-> file_save } ],
				[ 'Save ~as...'			=> 'CtrlA'			=> '^A'		=> sub { $this-> file_save_as($this) } ],
				[ '~Find...'			=> 'CtrlF'			=> '^F'		=> sub { $this-> find } ],
				[ '~Jump the line...'	=> 'CtrlJ'			=> '^J'		=> sub { $this-> jump } ],
				['~Replace...'			=> 'CtrlR'			=> '^R'		=> sub { $this-> replace } ],
				['Find n~ext'			=> 'F3'				=> 'F3'		=> sub { $this-> find_next } ],
				[],
				['Show next'			=> 'AltRight'		=>	km::Alt|kb::Right			=>	sub { $this->show_tab( 1) } ],
				['Show next'			=> 'CtrlTab'		=>	km::Ctrl|kb::Tab			=>	sub { $this->show_tab( 1) } ],
				['Show prev'			=> 'AltLeft'		=>	km::Alt|kb::Left			=>	sub { $this->show_tab(-1) } ],
				['Show prev'			=> 'CtrlShiftTab'	=>	km::Ctrl|kb::Tab|km::Shift	=>	sub { $this->show_tab(-1) } ],
				[],
				['Font size -'			=> 'CtrlUp'			=>	km::Ctrl|kb::Up				=>	sub { $this->show_size(-1, 0) } ],
				['Font size +'			=> 'CtrlDown'		=>	km::Ctrl|kb::Down			=>	sub { $this->show_size( 1, 0) } ],
				['Line spacing -'		=> 'AltUp'			=>	km::Alt|kb::Up				=>	sub { $this->show_size( 0,-1) } ],
				['Line spacing +'		=> 'AltDown'		=>	km::Alt|kb::Down			=>	sub { $this->show_size( 0, 1) } ],
				[],
				['~Close'				=> 'CtrlW'			=> '^W'		=> sub { $this-> file_close }],
#				['Re~place pages'		=> 'Ctrl+L'			=> '^L'		=> sub { $this-> file_replace }],
			]],
			[ '~Help' => [
				["~About ver. $VERSION"	=> sub { $this-> about }],
			]],
		],
		onClose		=>	sub {
			my $r = 0;
			for ( my $i = 0; $i < $Prima::CodeManager::developer{notes}->pageCount; $i++ ) {
				$r = 0;
				if ( $Prima::CodeManager::developer{ "notes_$i" }-> modified ) {
					$r =  Prima::MsgBox::message_box (
						"File not saved! ",
						'File '.$Prima::CodeManager::list_of_files[$i].' has been modified.  Save?', mb::YesNoCancel | mb::Warning
					);
					$this-> file_save_batch( $i ) if $r == mb::Yes;
					$_[0]-> clear_event, return if $r == mb::Cancel;
				}
			}
			$_[0]-> clear_event, return if mb::Cancel == $r;
		},
	);

	return $this;
}
################################################################################
sub loop
{
	my ( $self ) = shift;
	run Prima;
}
################################################################################
sub load_icon {
	my ( $self, $file ) = @_;
	my $dir = '';
	$file = $dir.$file;
	return undef unless -e $file;
	my $im = Prima::Icon-> new( type=>im::RGB, ) || return undef;
	$im->load( $file ) || return undef;
	return $im;
}
################################################################################
sub open
{
	my ( $self, $project_file ) = ( shift, shift );
	my $sliderWidth = 4;
	unless ( $self->{frame_main} ) {
		$self-> {frame_main} = $self->{mw}-> insert(
			FrameSet	=>
			owner		=>	$self->{mw},
			frameProfile => {
				borderWidth		=>	0,
				backColor		=>	$self->licz_kolor( 0xffffff, $project_color, 0.5 ),
			},
			arrangement		=>	fra::Vertical,
			size			=>	[$self->{mw}-> size],
			origin			=>	[0,0],
			frameSizes		=>	[qw(3% *)],
			opaqueResize	=>	1,
			sliderWidth		=>	$sliderWidth,
			sliderProfile => {
				borderWidth		=>	1,
				backColor		=>	$self->licz_kolor( 0xffffff, $project_color, 0.5 ),
				light3DColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.6 ),
				dark3DColor		=>	$self->licz_kolor( 0xffffff, $project_color, 0.4 ),
			},
		);
		$self-> {frame_top} = $self-> {frame_main}-> insert_to_frame(
			1,
			FrameSet	=>
			frameProfile => {
				borderWidth		=>	0,
				backColor		=>	$self->licz_kolor( 0xffffff, $project_color, 0.5 ),
			},
			size			=>	[$self-> {frame_main}-> frames-> [1]-> size],
			origin			=>	[0,0],
			frameSizes		=>	[qw(20% *)],
			opaqueResize	=>	1,
			sliderWidth		=>	$sliderWidth,
			sliderProfile => {
				borderWidth		=>	1,
				backColor		=>	$self->licz_kolor( 0xffffff, $project_color, 0.5 ),
				light3DColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.6 ),
				dark3DColor		=>	$self->licz_kolor( 0xffffff, $project_color, 0.4 ),
			},
		);
		$self-> {frame_left} = $self-> {frame_top}-> insert_to_frame(
			0,
			FrameSet	=>
			frameProfile => {
				borderWidth		=>	1,
				backColor		=>	$self->licz_kolor( 0xffffff, $project_color, 0.5 ),
			},
			arrangement		=>	fra::Vertical,
			size			=>	[$self-> {frame_top}-> frames-> [0]-> size],
			origin			=>	[0,0],
			frameSizes		=>	[qw(20% *)],
			opaqueResize	=>	1,
			sliderWidth		=>	$sliderWidth,
			sliderProfile => {
				borderWidth		=>	1,
				backColor		=>	$self->licz_kolor( 0xffffff, $project_color, 0.5 ),
				light3DColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.6 ),
				dark3DColor		=>	$self->licz_kolor( 0xffffff, $project_color, 0.4 ),
			},
		);
	}
#-------------------------------------------------------------------------------
	#if no project is defined we define empty one:
	$project_file ||= '';
	#if does not exixts we look in project directories; local and home ones:
	unless ( -f $project_file ) {
		$project_file = "./projects/$project_file" if -f "./projects/$project_file";
		$project_file = "$home_directory/projects/$project_file" if -f "$home_directory/projects/$project_file";
	}
	#if still does not exists then it should be choosen:
	unless ( -f $project_file ) {
		my $win = Prima::OpenDialog-> new(
			filter		=>	[[ 'CodeManager project files' => '*.cm' ],],
			directory	=>	"$home_directory/projects/",
			system		=>	0,
			font		=>	{
				name	=>	'DejaVu Sans Mono',
				size	=>	9,
				style	=>	fs::Normal,
			},
		);
		$project_file = $win-> fileName() if $win-> execute();
	}
	#if still does not exists then we resign:
	return unless -f $project_file;
#-------------------------------------------------------------------------------
	undef $self->{global};
	if ( -f $project_file && CORE::open ( my $FH, "<", $project_file ))
	{
		my $group = '';
		my $directory_nr = -1;
		my $directory_if =  0;
		while ( my $wiersz = <$FH> ) {
			next if $wiersz =~ /^(;|#|--)/;
			$wiersz =~ s/\n*//g;
			$wiersz =~ s/\r*//g;
			$wiersz =~ s/\t*//g;
			next unless $wiersz;
			$wiersz =~ s/^([^#]*)#.*$/$1/;
			if ( $wiersz =~ /^\s*\[(.+)\]/ ) {
				$group = $1;
				if ( $group eq 'DIRECTORY' ) {
					$directory_nr++;
					$directory_if = "_$directory_nr";
				} else {
					$directory_if = '';
				}
			} else {
				if ( $wiersz =~ /^([^=]+?)\s*=\s*(.*)$/ ) {
					my $name  = $1;
					my $value = $2;
					$value =~ s/%\[([^%]*)\]([^%]*)%/$self->{global}->{$1}->{$2}/g;
					$self->{global}->{$group}->{$name.$directory_if} = $value if $group && $name;
				}
			}
		}
		CORE::close ($FH);
	}

	unless ( $self->{global}->{GLOBAL}->{name} ) {
		$self->{global}->{GLOBAL}->{name} = $project_file;
		$self->{global}->{GLOBAL}->{name} =~ s/\.cm$//;
	}
	$self->{mw}->set( text => $self->{global}->{GLOBAL}->{name});
	$self->{global}->{GLOBAL}{notebook_fontSize} ||= 10;

	$self->{global}->{extensions} = '';
	my $i = 0;
	while ( $self->{global}->{DIRECTORY}->{$_OS."_$i"} ) {
		$self->{global}->{DIRECTORY}->{"directories_$i"} ||= '';
		$self->{global}->{DIRECTORY}->{$_OS."_$i"} =~ s/\~/$home_directory/g;
		$self->{global}->{DIRECTORY}->{"directory_$i"}  = $self->{global}->{DIRECTORY}->{$_OS."_$i"};
		$self->{global}->{DIRECTORY}->{"directory_$i"}  =~ s/\%CodeManager\%/$CodeManager_directory/g;
		$self->{global}->{DIRECTORY}->{"extensions_$i"} ||= '';
		$self->{global}->{extensions} .= '|'.$self->{global}->{DIRECTORY}->{"extensions_$i"} if $self->{global}->{DIRECTORY}->{"extensions_$i"};
		$self->{global}->{DIRECTORY}->{"sorting_$i"} ||= 'by extension';
		$self->{BRANCH}->[$i]->{sao_library} = $self->{global}->{DIRECTORY}->{"sao_library_$i"} || '.';

		$i++;
	}
	$self->{global}->{extensions} = 'nil|dir|'.$self->{global}->{extensions};
	$self->{global}->{extensions} =~ s/\s+//g;
	$self->{global}->{extensions} =~ s/\|+/\|/g;
	my @exten = split '\|', $self->{global}->{extensions};
#	for (@exten) {
#		$self->{images}->{$_} = $self-> load_icon( "$CodeManager_directory/img/$_.png" );
#		$self->{images}->{$_} = $self-> load_icon( "$CodeManager_directory/img/nil.png" ) unless $self->{images}->{$_};
#		eval( $self->read_file( "$CodeManager_directory/hilite/hilite_$_.pl")) if -e "$CodeManager_directory/hilite/hilite_$_.pl";
#	}
	$self->{global}->{GLOBAL}->{CodeManager_encoding} ||= '';
	$main::CodeManager_encoding = $self->{global}->{GLOBAL}->{CodeManager_encoding};
	$self->{global}->{GLOBAL}->{backup} = 0 unless $self->{global}->{GLOBAL}->{backup};
	$self-> make_tree;
	$self-> make_notebook;

	return;
}

####################################################################

sub make_tree
{
	my ( $self ) = shift;

	#we remember the topItem in the tree before refreshing:
	$self->{expanded}->{topItem} = 0;
	$self->{expanded}->{topItem} = $self->{tree}->topItem if $self->{tree};

	$self->{global}->{GLOBAL}{tree_itemHeight} += 0;
	$self->{global}->{GLOBAL}{tree_itemHeight}  = 12 if $self->{global}->{GLOBAL}{tree_itemHeight} < 12;

	$self->{global}->{GLOBAL}{tree_itemIndent} += 0;
	$self->{global}->{GLOBAL}{tree_itemIndent}  =
		$self->{global}->{GLOBAL}{tree_itemIndent} < $self->{global}->{GLOBAL}{tree_itemHeight}
		? $self->{global}->{GLOBAL}{tree_itemHeight}
		: $self->{global}->{GLOBAL}{tree_itemIndent}
	;

	my ( $type_dimen, $font_dimen ) = ( 'size', int( 0.625 * $self->{global}->{GLOBAL}{tree_itemHeight}));

	if ( $self->{global}->{GLOBAL}{tree_fontHeight} && $self->{global}->{GLOBAL}{tree_fontHeight} > 0 ) {

		$type_dimen	= 'height';
		$font_dimen	=
			$self->{global}->{GLOBAL}{tree_fontHeight} < $self->{global}->{GLOBAL}{tree_itemHeight}
			? $self->{global}->{GLOBAL}{tree_fontHeight}
			: $self->{global}->{GLOBAL}{tree_itemHeight}
		;

	} elsif ( $self->{global}->{GLOBAL}{tree_fontSize} && $self->{global}->{GLOBAL}{tree_fontSize} > 0 ) {

		$type_dimen	= 'size';
		$font_dimen	=
			$self->{global}->{GLOBAL}{tree_fontSize} < 0.625 * $self->{global}->{GLOBAL}{tree_itemHeight}
			? $self->{global}->{GLOBAL}{tree_fontSize}
			: 0.625 * $self->{global}->{GLOBAL}{tree_itemHeight}
		;
	}

	$self->{global}->{GLOBAL}{tree_fontName}   ||= 'DejaVu Sans Mono';
	my @items = [];
	my $i = 0;
	while ( my $directory = $self->{global}->{DIRECTORY}->{"directory_$i"} ) {
		$self->{global}->{DIRECTORY}->{"directory_$i"} .= '/' unless $self->{global}->{DIRECTORY}->{"directory_$i"} =~ /\/$/;
		$self->{global}->{DIRECTORY}->{"image_$i"} = '' unless $self->{global}->{DIRECTORY}->{"image_$i"};
		$self->{images}->{"dir_$i"} =
			$self-> load_icon( $self->{global}->{DIRECTORY}->{"image_$i"} )
			|| $self-> load_icon( "$CodeManager_directory/img/".$self->{global}->{DIRECTORY}->{"image_$i"} )
			|| $self-> load_icon( "$CodeManager_directory/img/nil.png" );
		my $name = $self->{global}->{DIRECTORY}->{"name_$i"};
		$name = $self->{global}->{DIRECTORY}->{name}.'-'.$i unless $name;
		$items[0]->[$i][0] = [ $name, $self->{images}->{"dir_$i"}, 0, '', $directory, $i, $name ];
		$items[0]->[$i][1] = [];

		my $ext_exclude = '\.~CodeManager';		$ext_exclude .= '|'.$self->{global}->{DIRECTORY}->{"ext_exclude_$i"} if $self->{global}->{DIRECTORY}->{"ext_exclude_$i"};
		my $dir_exclude = '\.~CodeManager';		$dir_exclude .= '|'.$self->{global}->{DIRECTORY}->{"dir_exclude_$i"} if $self->{global}->{DIRECTORY}->{"dir_exclude_$i"};


#		if ( $self->{global}->{DIRECTORY}->{"host_$i"} ) {
#			$self->connect( $i );
#		}

		$items[0]->[$i][1] = [] unless $self-> read_tree( $items[0]->[$i][1], $directory, 1, $i, $ext_exclude, $dir_exclude );
		$items[0]->[$i][2] = $self->{expanded}->{$name} || 0;
		$self->{list}->[$i] = $items[0]->[$i][0];
		$i++;
	}
	$self->{listdim} = 1;
	delete $self->{tree} if $self->{tree};

	$self->{tree} = $self->{frame_left}-> insert_to_frame(
		1,
		'CodeManager::Outline' =>
		name			=>	'tree',
		multiSelect		=>	0,
		extendedSelect	=>	0,
		path			=>	'./',
		buffered		=>	0,
		borderWidth		=>	1,
		place => {
			x=>0,	relx => 0.5,	width	=>-6,	relwidth	=> 1,
			y=>-2,	rely => 0.5,	height	=>-6,	relheight	=> 1,
		},
		light3DColor=>	$self->licz_kolor( 0xffffff, $project_color, 0.2 ),
		dark3DColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.4 ),
		darkColor	=>	$self->licz_kolor( 0xf7f7f7, $self->angle_color( $int_color , 255, 220 ), 0 ),

		frameProfile => {
			borderWidth	=>	1,
			backColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.5 ),
			light3DColor=>	$self->licz_kolor( 0xffffff, $project_color, 0.6 ),
			dark3DColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.4 ),
		},
		items			=>	@items,
		indent			=>	$self->{global}->{GLOBAL}{tree_itemIndent},
		itemHeight		=>	$self->{global}->{GLOBAL}{tree_itemHeight},
#		multiSelect		=>	1,
		hScroll			=>	1,
		vScroll			=>	1,
		popupFont	=>	{
			name		=>	'DejaVu Sans',
			size		=>	9,
			style		=>	fs::Normal,
		},
		font		=>	{
			name		=>	$self->{global}->{GLOBAL}{tree_fontName},
			$type_dimen	=>	$font_dimen,
			style		=>	fs::Normal,
		},
		onMouseClick	=>	sub {
			my ($this, $btn, $mod, $x, $y, $dblclk) = @_;
			my $clicked = int( $this->topItem + ($self->{tree}-> height - $y)/$this-> itemHeight );
			if ( $btn == 4 && !$dblclk ) {
				$this-> deselect_all ();
				$this-> select_item ( $clicked );
				$this-> focusedItem ( $clicked );
				$popup = $self->popup_show (
					$this,
					$clicked,
					left		=>	$self->{frame_left}-> left   + $x,
					bottom		=>	$self->{frame_left}-> bottom + $y,
					title		=>	'Making tree',
					itemHeight	=>	$this-> itemHeight,
				);
			}
			my @arr = $this-> get_item( $clicked );
			if ( $arr[0]->[0] ) {
				my $fn  = $arr[0]->[0]->[4].'/'.$arr[0]->[0]->[0];
				if ( $arr[0]->[0]->[3] eq 'file' && $fn && -e $fn && $dblclk ) {
					$self->file_edit( $fn, $arr[0]->[0]->[5] );
				}
			}
			#we remember (for later refreshing) if the branch is expanded:
			$self->{expanded}->{$arr[0]->[0]->[6]} = $arr[0]->[2] if defined $arr[0]->[2];
		},
		onKeyDown	=>	sub {
			my ($this, $code, $key, $mode) = @_;
#			print "$this, $code, $key, $mode\n";
			if ( $code == 13 ) {
				my $current = $this->focusedItem;
				my @arr = $this-> get_item( $current );
				if ( $arr[0]->[0] ) {
					my $fn  = $arr[0]->[0]->[4].'/'.$arr[0]->[0]->[0];
					if ( $arr[0]->[0]->[3] eq 'file' && $fn && -e $fn ) {
						$self->file_edit( $fn, $arr[0]->[0]->[5] );
					}
				}
				#we remember (for later refreshing) if the branch is expanded:
				$self->{expanded}->{$arr[0]->[0]->[6]} = $arr[0]->[2] if defined $arr[0]->[2];
			}
		},
	);

	$self->{tree}->set( topItem => $self->{expanded}->{topItem} ) if $self->{expanded}->{topItem};
	$developer{ftt} = $self-> {frame_left}-> insert_to_frame (
		0,
		CheckList	=>
		items			=> [],
		multiColumn		=> 0,
		vertical		=> 1,
		multiSelect		=> 1,
		extendedSelect	=> 0,
		place 			=> {
			x =>  0,	relx => 0.5,	width  => -6,	relwidth  => 1,
			y =>  0,	rely => 0.5,	height => -6,	relheight => 1,
		},
		font		=>	{
			name	=>	'DejaVu Sans Mono',
			size	=>	9,
			style	=>	fs::Normal,
		},
		frameProfile => {
			borderWidth	=>	1,
			backColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.5 ),
			light3DColor=>	$self->licz_kolor( 0xffffff, $project_color, 0.6 ),
			dark3DColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.4 ),
		},
		borderWidth		=>	1,
		light3DColor=>	$self->licz_kolor( 0xffffff, $project_color, 0.2 ),
		dark3DColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.2 ),
	);
}


####################################################################

sub save
{
	my $r =  Prima::MsgBox::message_box (
		'Project saving',
		'Sorry! Project saving is not ready yet...', mb::OK
	);
}

####################################################################

sub read_tree {
	my ( $self, $object, $dir, $level, $nr_of_dir, $ext_exclude, $dir_exclude ) = @_;
	$dir =~  s/\/$//;

	my $k = 0;
	my $type = '';
	my @fils = $self-> read_dir( $dir, 'all', $nr_of_dir );
#	@fils = sort_ext( @fils );
#	@fils = sort mysort ( @fils );

	foreach (@fils) {
#		( $type, $_ ) = ( $1, $2 ) if $_ =~ /^(.*?)\-.*?([^\/]*)$/;
#		if ( $type eq 'fil' ) {
		$_ = $1 if $_ =~ /^.*?([^\/]*)$/;

		if ( -f "$dir/$_" ) {
			next if $ext_exclude && $_ =~ /$ext_exclude$/;
			$_ =~  /\.(\w+)$/;
			my $ext = lc($1);
			$ext = '' unless $ext;
			$object->[$k][0] = [ $_, $self->{images}->{$ext}||$self->{images}->{nil}, $level, 'file', $dir, $nr_of_dir, "$dir/$_" ];
			$self->{listdim} ++;
			$self->{list}->[ $self->{listdim} ] = $object->[$k][0];
			$k++;
		}

		if ( -d "$dir/$_" ) {
			next if $dir_exclude && $_ =~ /$dir_exclude$/;
			$object->[$k][0] = [ $_, $self->{images}->{dir}, $level, '', $dir, $nr_of_dir, "$dir/$_" ];
			$object->[$k][1] = [];
			$object->[$k][1] = [] unless $self-> read_tree( $object->[$k][1], "$dir/$_", $level + 1, $nr_of_dir, $ext_exclude, $dir_exclude );
			$object->[$k][2] = $self->{expanded}->{"$dir/$_"}||0;
			$self->{listdim} ++;
			$self->{list}->[ $self->{listdim} ] = $object->[$k][0];
			$k++;
		}
	}

	return $k;
}

################################################################################

sub read_dir {
	my ( $self, $dir, $type, $nr_of_dir ) = @_;
	my @contents;
	if ( opendir(my $DIR, $dir )) {
		@contents = readdir( $DIR );
		closedir( $DIR );
	}
#	if ( $self->{global}->{sorting} =~ /names/i ) {
#	print "sorting_$nr_of_dir = ",$self->{global}->{DIRECTORY}->{"sorting_$nr_of_dir"},"\n";

	if ( $self->{global}->{DIRECTORY}->{"sorting_$nr_of_dir"} =~ /name/i ) {
		@contents = sort mysort @contents;
	} else {
		@contents = sort_ext( @contents );
	}

#	@contents = sort @contents;

#	foreach my $ext (sort {lc($contents{$a}) cmp lc($contents{$b}) } keys %contents) {
#		push @cont, $contents{$ext}
#	}
#	@contents = @cont;

	my @result;
	$self->{global}->{GLOBAL}->{search_directories} ||= '';
	foreach (@contents) {
		if ( $_ ne '.' && $_ ne '..' ) {
			if ( -d "$dir/$_" ) {
#				push @result, "dir-$dir/$_"
				push @result, "$dir/$_" if $type =~ /dir|all/ &&
				(	$_ =~ /$self->{global}->{DIRECTORY}->{"directories_$nr_of_dir"}/i
					|| $self->{global}->{DIRECTORY}->{"directories_$nr_of_dir"} =~ /all/i
				);
			} else {
				$_ =~  /\.(\w+)$/;
				my $ext = $1 ? lc($1) : '';
				$ext = '' unless $ext;
#				push @result, "fil-$dir/$_"
				push @result, "$dir/$_" if $type =~ /file|all/ &&
				(	$_ =~ /$self->{global}->{DIRECTORY}->{"extensions_$nr_of_dir"}/i
					|| $self->{global}->{DIRECTORY}->{"extensions_$nr_of_dir"} =~ /all/i
				);
			}
		}
	}
	return @result;
}
################################################################################
sub close
{
	my ( $self ) = shift;
	my $nr = 0;
	return 0;
}
################################################################################
sub mysort
{
	lc($a) cmp lc($b);
}
# ------------------------------------------------------------------------------
sub sort_ext
{
	my %ext_contents;
	while ( my $file =  shift @_ ) {
		my $ext = chr(254);
		$ext = $1 if $file =~ /\.([^\.]*)$/;
		$ext_contents{"ext_${ext}_$file"} = $file;
	}
	my @contents;
# according extentions:
	foreach my $ext (sort mysort (keys(%ext_contents))) {
		push @contents, $ext_contents{$ext}
	}
# according names:
#	foreach my $ext (sort {lc($ext_contents{$a}) cmp lc($ext_contents{$b}) } keys %ext_contents) {
#		push @contents, $ext_contents{$ext}
#	}
	return @contents;
}
################################################################################
sub make_notebook
{
	my ( $self ) = shift;
	my $fontSize = $self->{global}->{GLOBAL}{notebook_fontSize} + 0; $fontSize = 10 if $fontSize < 1;
	my $fontName = $self->{global}->{GLOBAL}{notebook_fontName} || 'DejaVu Sans Mono';
	my $sliderWidth = 4;
	undef $developer{notes};
	$developer{notes} = $self->{frame_top}->insert_to_frame (
		1,
		'CodeManager::TabbedScrollNotebook' =>
		tabs	=>	[],
		place	=>	{
			x=>0,	relx => 0.5,	width =>-6,	relwidth  => 1,
			y=>0,	rely => 0.5,	height=>-6,	relheight => 1,
		},
		colored	=>	1,
		enabled	=>	1,
		style	=>	tns::Standard,
		font	=>	{
			name	=>	$fontName,
			size	=>	$fontSize,
			style	=>	fs::Normal,
		},
		orientation		=>	tno::Top,
		borderWidth		=>	1,
		backColor		=>	$self->licz_kolor( 0xffffff, $project_color, 0.5 ),
		arrangement		=>	fra::Vertical,
		size			=>	[$self->{mw}-> size],
		origin			=>	[0,0],
#		frameSizes		=>	[qw(3% *)],
		opaqueResize	=>	1,
	);
#	for ( my $page = 0; $page < $file_number; $page++ ) {
#		Prima::Notebook::delete_page( $developer{notes}, $page, 1 ) ;
#	}
	@list_of_files = ();
	$file_number = 0;
	$developer{notes}-> set_tabs( @list_of_files );
	$developer{notes}-> repaint;
}

################################################################################

sub popup_show
{
	my ( $self, $tree, $clicked ) = @_;
	my @arr   = $tree-> get_item( $clicked );
	my $level = $arr[0]->[0]->[2];
	my $name  = $arr[0]->[0]->[0];
	my $type  = $arr[0]->[0]->[3]||'',
	my $dir   = $arr[0]->[0]->[4],
	my $bra   = $arr[0]->[0]->[5],
	my %par;
	my $i = 3;
	while ( my $key = $_[$i] ) { $par{$key} = $_[$i+1]; $i += 2 }
	$par{left}   = 0 unless $par{left};
	$par{bottom} = 0 unless $par{bottom};
	$par{width}  = 740;
	$par{height} = 240;
	my $x = [$self->{mw}->origin]->[0] + [$self->{frame_left}->pointerPos]->[0];
	my $y = [$self->{mw}->origin]->[1] + [$self->{frame_left}->pointerPos]->[1] - $par{height} + $par{itemHeight};
	my $tmp_popup = Prima::Dialog-> create(
		title		=> $par{title},
		text		=> $par{title},
		origin		=> [ $x,          $y ],
		size		=> [ $par{width}, $par{height} ],
#		borderIcons	=> 0,
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
		},
	);
	$tmp_popup->insert( Label =>
		origin	=>	[ 10, $par{height} - 30 ],
		size	=>	[ $par{width} - 20,  20 ],
		text	=>	$name,
		flat	=>	1,
		x_centered	=> 1,
		alignment	=>	ta::Center,
		color		=>	$self->licz_kolor( 0x000000, $project_color, 0.8, 0 ),
		borderWidth	=>	1,
		font 		=>	{	size	=>	10,	style	=>	fs::Normal,	},
	);
	$tmp_popup->insert( Button =>
		origin		=>	[ 10, 10 ],
		size		=>	[ 80, 20 ],
		text		=>	'Cancel',
		enabled		=>	1,
		flat		=>	0,
		color		=>	0x000000,
		borderWidth	=>	1,
		borderColor =>	0xffffff,
		backColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.8, 0 ),
		font 		=>	{	size	=>	9,	style	=>	fs::Normal,	},
		onClick	=>	sub {
			$tmp_popup->close;
			undef $popup;
		},
	);
#----------------------------------------------------------------
	my $input = $tmp_popup-> insert( InputLine =>
		origin		=>	[  10,  $par{height} -55 ],
		size		=>	[ 480,  20 ],
		text		=>	$name,
		flat		=>	0,
		alignment	=>	ta::Left,
		color		=>	0x000000,
		borderWidth	=>	1,
		font 		=>	{
			size	=>	10,
			style	=>	fs::Normal,
		},
		backColor	=> 0xffffff,
	);
#----------------------------------------------------------------
	my @lista = split /\n/, $self->read_file( "$home_directory/templates/templates.ini" );
	my @template_names = ('...');
	my @template_files = (''   );
	my $j = 0;
	foreach (@lista) {
		if ( $_ =~ /^(.*?)=(.*)$/ ) {
			my ( $file, $name ) = ( $1, $2 );
			$file =~ s/^\s*//;	$file =~ s/\s*$//;
			$name =~ s/^\s*//;	$name =~ s/\s*$//;
			next unless $file && $name;
			if ( $file ne 'line' ) {
				$j++;
				push @template_files, $file;
				push @template_names, "$j. $name";
			} else {
				push @template_names, "";
			}
		}
	}
	my $check1 = $tmp_popup-> insert( ComboBox =>
		origin		=>	[  10,  $par{height} -80 ],
		size		=>	[ 480,  20 ],
		style		=>	(cs::DropDownList),
		items		=>	[( @template_names )],
		flat		=>	1,
		font 		=>	{
			size	=>	9,
			style	=>	fs::Normal,
		},
	);
#-------------------------------------------------------------
	$tmp_popup-> insert( Button =>
		origin		=>	[ 500, $par{height} - 55 ],
		size		=>	[ 230,  20 ],
		text		=>	'Insert',
		enabled		=>	1,
		flat		=>	0,
		color		=>	0x000000,
		borderWidth	=>	1,
		borderColor =>	0xffffff,
		backColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.8, 0 ),
		font 		=>	{	size	=>	9,	style	=>	fs::Normal,	},
		onClick		=>	sub {
			if ( $input-> text eq '' ) {
				Prima::message ( "No name!" );
			} else {
				my $go = 1;
				foreach (@{$self->{list}}) {
					if ( "$dir/$name" eq $_->[4] && $_->[3] eq '' ) {
						if ( $input-> text eq $_->[0] ) {
							$go = 0;
							last;
						}
					}
				}

				if ( $go ) {
					my $tmp_name = "$name/";
					$tmp_name = '' unless $level;
					my $template_file = '';
					if ( $check1-> text =~ /(\d+)\./ ) { $template_file = $template_files[$1] if $1 }
					my $info = $self-> make_object (
						action	=>	'Insert',
						name	=>	"$dir/$tmp_name".$input-> text,
						branch	=>	$bra,
						template=>	$template_file,
					);
					if ( $info eq 'OK' ) {
							$self-> make_tree;
					} else {
						Prima::message ( $info );
					}
					$tmp_popup-> close();
					undef $popup ;
				} else {
					Prima::message ( "The name [$name] already exists!" );
				}
			}
		},
	);
#-------------------------------------------------------------
	$tmp_popup->insert( Button =>
		origin		=>	[ 500,  $par{height} - 80 ],
		size		=>	[ 230,  20 ],
		text		=>	'Update',
		enabled		=>	1,
		flat		=>	0,
		color		=>	0x000000,
		borderWidth	=>	1,
		borderColor =>	0xffffff,
		backColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.8, 0 ),
		font 		=>	{ size => 9, style => fs::Normal, },
		onClick		=>	sub {
			if ( $input->text eq '' ) {
				Prima::message ( "No name!" );
			} elsif ( $input->text eq $name ) {
				Prima::message ( "The same name!" );
			} else {
				my $info = $self-> make_object (
					action		=>	'Update',
					name		=>	"$dir/".$input->text,
					branch		=>	$bra,
					old_name	=>	"$dir/".$name,
				);
				if ( $info eq 'OK' ) {
					$self-> make_tree;
					$tmp_popup->close();
					undef $popup ;
				} else {
					Prima::message ( $info );
				}
			}
		},
	);
#-------------------------------------------------------------
	$tmp_popup->insert( Button =>
		origin		=>	[ 500,  $par{height} -105 ],
		size		=>	[ 230,  20 ],
		text		=>	'Backup',
		enabled		=>	1,
		flat		=>	0,
		color		=>	0x000000,
		borderWidth	=>	1,
		borderColor =>	0xffffff,
		backColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.8, 0 ),
		font 		=>	{	size	=>	9,	style	=>	fs::Normal,	},
		onClick		=>	sub {
			my $info = $self-> make_object (
				action	=>	'Backup',
				name	=>	"$dir/".$name,
				branch	=>	$bra,
			);
			if ( $info eq 'OK' ) {
				my ( $x, $l ) = $tree-> get_item( $tree-> focusedItem );
				$tree-> delete_item ( $x );
				$tmp_popup->close();
				undef $popup ;
			} else {
				Prima::message ( $info );
			}
		},
	);
#-------------------------------------------------------------
	$tmp_popup->insert( Button =>
		origin		=>	[ 500,  $par{height} -130 ],
		size		=>	[ 230,  20 ],
		text		=>	'Copy',
		enabled		=>	1,
		flat		=>	0,
		color		=>	0x000000,
		borderWidth	=>	1,
		borderColor =>	0xffffff,
		backColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.8, 0 ),
		font 		=>	{	size	=>	9,	style	=>	fs::Normal,	},
		onClick		=>	sub {
			if ( $input->text eq '' ) {
				Prima::message ( "No name!" );
			} elsif ( $input->text eq $name ) {
				Prima::message ( "The same name!" );
			} else {
				my $info = $self-> make_object (
					action		=>	'Copy',
					old_name	=>	"$dir/".$name,
					name		=>	"$dir/".$input->text,
					branch		=>	$bra,
				);
				if ( $info eq 'OK' ) {
					$self-> make_tree;
					$tmp_popup->close();
					undef $popup ;
				} else {
					Prima::message ( $info );
				}
			}
		},
	);

#-------------------------------------------------------------

	$tmp_popup->insert( Button =>
		origin		=>	[ 500,  $par{height} -155 ],
		size		=>	[ 230,  20 ],
		text		=>	'Delete',
		enabled		=>	1,
		flat		=>	0,
		color		=>	0x000000,
		borderWidth	=>	1,
		borderColor =>	0xffffff,
		backColor	=>	$self->licz_kolor( 0xffffff, $project_color, 0.8, 0 ),
		font 		=>	{	size	=>	9,	style	=>	fs::Normal,	},
		onClick		=>	sub {
			my $info = $self-> make_object (
				action	=>	'Delete',
				name	=>	"$dir/".$name,
				branch	=>	$bra,
			);
			if ( $info eq 'OK' ) {
				my ( $x, $l ) = $tree-> get_item( $tree-> focusedItem );
				$tree-> delete_item ( $x );
				$tmp_popup->close();
				undef $popup ;
			} else {
				Prima::message ( $info );
			}
		},
	);
#-------------------------------------------------------------
	$tmp_popup->insert( Button =>
		origin		=>	[ 500,  10 ],
		size		=>	[ 230,  20 ],
		text		=>	'find files with the text',
		enabled		=>	1,
		flat		=>	0,
		color		=>	0x000000,
		borderWidth	=>	1,
		borderColor =>	0xffffff,
		backColor	=>	$self-> licz_kolor( 0xffffff, $project_color, 0.8, 0 ),
		font 		=>	{ size => 9, style => fs::Normal, },
		onClick		=>	sub {
			my @files	=	();

			foreach ( @{$self->{list}} ) {
				my $fn = $_->[4]."/".$_->[0];
				next unless $_->[3] eq 'file' && $fn =~ /$self->{global}->{DIRECTORY}->{"directory_$bra"}/;
				push @files, $fn if ftt_has_feature( $fn, $input-> text );
			}

			my $cap = join "\n",@files,"\n";
			$developer{ftt}-> set (
				items	=>	[@files],
				onMouseClick	=>	sub {
					my ($this, $btn, $mod, $x, $y, $dblclk ) = @_;
					my $clicked	= int( $this-> topItem + ($developer{ftt}-> height - $y)/$this-> itemHeight );
					my $fn		= $developer{ftt}-> items-> [$clicked] ? $developer{ftt}-> items-> [$clicked] : '';
					$self-> file_edit( $fn, $bra ) if $dblclk && -f $fn;
				}
			);
			$tmp_popup-> close();
			undef $popup ;
		},
	);
	$tmp_popup->execute;
	return $tmp_popup;
}

########################################################################

sub make_object
{
	my ( $self ) = shift;
	my %par;
	while ( my $key = shift ) { $par{$key} = shift }
	return "No name defined!" unless $par{name};
	my $ext     = '';
	my $default = '';
	if ( $par{name} =~ /\.([^\.\\\/]+)$/ ) {
		$ext     = $1;
		$default = "$home_directory/templates/default/$ext.pl";
	}

	if ( $par{action} eq 'Insert' ) {

		if ( -e $par{name} ) {

			return "Object with the name: ['$par{name}'] already exists!";

		} else {

			# file is created when extension is defined:
			if ( $ext ) {
				# if there is template chosen:
				if ( $par{template} && -e "$home_directory/templates/".$par{template} ) {
					our @_ARGV = ( $self, $self->{global}->{DIRECTORY}->{"directory_".$par{branch}}, $par{name}, $par{branch}||0 );
					eval $self-> read_file( "$home_directory/templates/".$par{template});
				# next if there is a default extension template:
				} elsif ( -e $default ) {
					our @_ARGV = ( $self, $self->{global}->{DIRECTORY}->{"directory_".$par{branch}}, $par{name} );
					eval $self-> read_file( $default );
				# remain only to create empty file:
				} else {

					eval { $self-> write_to_file( $par{name}, '' ); };
				}
			} else {
				# if no extension there is a directory:
				# if there is template chosen:
				if ( $par{template} && -e "$home_directory/templates/".$par{template} ) {

					our @_ARGV = ( $self, $self->{global}->{DIRECTORY}->{"directory_".$par{branch}}, $par{name}, $par{branch}||0 );
					eval $self-> read_file( "$home_directory/templates/".$par{template} );
					# remain only to create empty directory (with .exists file only:

				} else {
					eval { make_path ( $par{name} ) };
#					$self->write_to_file( $par{name}.'/.exists','');
				}
			}

			return $@ || 'OK';
		}

	} elsif ( $par{action} eq 'Copy' ) {

		if ( -f $par{old_name} ) {

			eval { fcopy( $par{old_name}, $par{name} ) };

		} elsif ( -d $par{old_name} ) {

			eval { dircopy( $par{old_name}, $par{name} ) } ;
		}

		return $@ || 'OK';

	} elsif ( $par{action} eq 'Update' ) {

		if ( -f $par{old_name} ) {

			eval { move( $par{old_name}, $par{name} ) };

		} elsif ( -d $par{old_name} ) {

			eval { dirmove( $par{old_name}, $par{name} ) } ;
		}

		return $@ || 'OK';

	} elsif ( $par{action} eq 'Backup' ) {

		if ( -f $par{name} ) {

			eval { unlink( $par{name}.".~CodeManager" ) };
			return $@ if $@;

			eval { move( $par{name}, $par{name}.".~CodeManager" ) };

		} elsif ( -d $par{name} ) {

			eval { dirmove( $par{name}, $par{name}.".~CodeManager" ) } ;
		}

		return $@ || 'OK';

	} elsif ( $par{action} eq 'Delete' ) {

		my $what = Prima::MsgBox::message_box( 'Delete the file?', "Confirm deleting:\n".$par{name}, mb::YesNo );

		return unless $what == 2;

		if ( -f $par{name} ) {

			eval { unlink( $par{name} ) };

		} elsif ( -d $par{name} ) {

			eval { remove_tree( $par{name} ) };
		}

		return $@ || 'OK';

	} else {

		return "Incorect action: ".$par{action};
	}
	return '';
}

################################################################################

sub ftt_has_feature {
	my ( $name, $str ) = @_;
	if ( CORE::open( my $FH, "<$name" )) {
		my(@lines) = <$FH>;
		foreach (@lines) {
			return 1 if $_ =~ /$str/i;
		}
		CORE::close($FH);
	}
	return 0;
}

##########################################################################

sub meld
{
	my ( $self ) = shift;

	my ( $file1, $file2 ) = splice( @Prima::CodeManager::list_of_files, -2 );

	system( "meld $file1 $file2  > /dev/null &") if -f $file1 && -f $file2;

	return
}

1;

__END__

=pod

=head1 NAME

CodeManager - Yet Another Source Editor

=head1 SYNOPSIS

	#!/usr/bin/perl -w

	use strict;
	use warnings;

	use Prima::CodeManager::CodeManager;

	our $project = Prima::CodeManager-> new();
	$project-> open( 'CodeManager.cm' );
	$project-> loop;

	__END__

where I<CodeManager.cm> is a CodeManager project configuration file. This one is created in your
home directory: I<~/.CodeManager/projects/CodeManager.cm>.

=head1 DESCRIPTION

The aim of creating CodeManager is to manage projects with many types source files. Specially
when deal with exotic ones or our own ones. Moreover it is useful in projects
which files are in a few independent directories. It could be usefull in the cases
when "standard" highlitning is not satisactory.

CodeManager uses excelent L<Prima> libraries and therefore works identically
in those systems which have Prima installed (tested Linux and Windows).

=head1 DETAILS

CodeManager is a source editor with the following features in mind:

=head2 1. Easy project tree(s) maintenance.

Project can consists of few main directories - not just one.
Each of the sub-projects has it's own file extensions list
that have to be displayed. Directories and files can be easily draged and droped
(with a mouse and Ctrl key).

=head2 2. Easy source files edition.

Extremaly ease defining source files hilighting of known and unknown file types (in fact effortless
when Perl regular expression rules are known). The inspiration for this was a horrible higliting
quite a lot of types and the fact, that I use in my projects my own types of files.

The highliting is not perfect, especially there is no block one. I think this is the price
of having the one-line highliting very fast. As a result CodeManager can handle large file quite easyly.
I use it for instance to edit PostgreSQL dump files of size over 200MB and over 470 000 lines.

=head2 3. Easy template files preparation.

CodeManager has templates files. CodeManager project consists of files (always
with an extension) and directories (without). When new object is created, then
it is possible to bind with the creation a sequence of perl tasks (written in a template file).
It is as easy as to write perl script. The template file is then eval(uated).

=head1 MORE DETAILS

CodeManager creates in your HOME directory a subdirectory I<.CodeManager> in which stores the projects
configuration (with a I<.CodeManager> extensions) and I<templates> subdirectory to store
template files (perl scripts).

CodeManager uses images files that are stored in CodeManager installation sub-directory I<CodeManager/img>.
The images are 12x12 png objects.
Their names have the form I<XXX.png>, where XXX stands for the extension.

Highliting files are stored similarly: in the I<hilite> subdirectory. These are perl scripts with
regular expressions and their names have the form: I<hilite_XXX.pl>, where XXX stands for the extension.

=head1 AUTHOR

Waldemar Biernacki, E<lt>wb@sao.plE<gt>

=head1 COPYRIGHT

Copyright 2009-2012 by Waldemar Biernacki.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
