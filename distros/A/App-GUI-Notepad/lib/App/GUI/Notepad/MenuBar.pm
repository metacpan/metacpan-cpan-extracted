package App::GUI::Notepad::MenuBar;

use strict;
use Wx::Menu ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	my %args  = @_;

	# Create the object
	my $this = bless {
		ID_NEW    => 99,
		ID_OPEN   => 100,
		ID_SAVE   => 105,
		ID_SAVEAS => 110,
		ID_CLOSE  => 115,
		ID_EXIT   => 120,
		ID_UNDO   => 123,
		ID_REDO   => 124,
		ID_CUT    => 125,
		ID_COPY   => 130,
		ID_PASTE  => 135,
		ID_ABOUT  => 140,
		}, $class;

	# Create the File menu
	$this->{filemenu} = Wx::Menu->new() or die();
	$this->{filemenu}->Append( $this->{ID_NEW},    "&New",     "Create a file" );
	$this->{filemenu}->Append( $this->{ID_OPEN},   "&Open",    "Open a file" );
	$this->{filemenu}->Append( $this->{ID_SAVE},   "&Save",    "Save current file" );
	$this->{filemenu}->Append( $this->{ID_SAVEAS}, "Save &As", "Save under different filename" );
	$this->{filemenu}->Append( $this->{ID_CLOSE},  "&Close",   "Close current file" );
	$this->{filemenu}->AppendSeparator();
	$this->{filemenu}->Append( $this->{ID_EXIT},   "E&xit",    "Quit this Program" );

	# Create the Edit menu
	$this->{editmenu} = Wx::Menu->new() or die();
	$this->{editmenu}->Append( $this->{ID_UNDO},   "&Undo",    "Undo" );
	$this->{editmenu}->Append( $this->{ID_REDO},   "&Redo",    "Redo" );
	$this->{editmenu}->AppendSeparator();
	$this->{editmenu}->Append( $this->{ID_CUT},    "&Cut",     "Cut selected text" );
	$this->{editmenu}->Append( $this->{ID_COPY},   "&Copy",    "Copy selected text" );
	$this->{editmenu}->Append( $this->{ID_PASTE},  "&Paste",   "Paste text" );

	# Create the Help menu
	$this->{helpmenu} = Wx::Menu->new();
	$this->{helpmenu}->Append( $this->{ID_ABOUT},  "&About",   "About this program" );	

	# Assemble the menubar
	$this->{menubar} = Wx::MenuBar->new() or die();
	$this->{menubar}->Append( $this->{filemenu}, "&File" );
	$this->{menubar}->Append( $this->{editmenu}, "&Edit" );
	$this->{menubar}->Append( $this->{helpmenu}, "&Help" );

	return $this;
}

sub menubar {
	$_[0]->{menubar};
}

1;
