package App::GUI::Notepad::Frame;

use strict;
use File::Spec  ();
use base qw/Wx::Frame/;
use Wx          qw/:allclasses wxTE_MULTILINE wxID_OK wxSAVE wxOK wxCENTRE wxFONTENCODING_SYSTEM wxMODERN wxNORMAL wxNullColour wxSWISS wxTE_RICH/;
use Wx::Event   qw/EVT_MENU/;


use App::GUI::Notepad::MenuBar;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

# This is the constructor for the object.
# It creates:
# 			- the menubar
#			- the textctrl which is where the text that is being edited is 
#			is stored
#			- the status bar where non modal messages can be sent to the 
#			user 
# It associates actions to the various menu options, sets the application 
# icon and sets the font for displaying the file to a fixed width font.

sub new {
	my ($class) = shift;
	my ($title, $position, $size) = @_;
	my ($this) = $class->SUPER::new( undef, -1, $title, $position, $size );
	$this->SetIcon( Wx::GetWxPerlIcon() );

	$this->{menubar} = App::GUI::Notepad::MenuBar->new();
	$this->SetMenuBar( $this->{menubar}->menubar() );

	# Associate the various menu options with subroutines that are the 
	# actions to be carried out when the user clicks on the menu item.
	#
    # I wanted to do this in the MenuBar object but this function 
	# EVT_MENU need a reference to the frame and so they are called 
	# here

	EVT_MENU( $this, $this->{menubar}->{ID_NEW},    \&_menu_new    );
	EVT_MENU( $this, $this->{menubar}->{ID_OPEN},   \&_menu_open   );
	EVT_MENU( $this, $this->{menubar}->{ID_SAVE},   \&_menu_save   );
	EVT_MENU( $this, $this->{menubar}->{ID_SAVEAS}, \&_menu_saveas );
	EVT_MENU( $this, $this->{menubar}->{ID_CLOSE},  \&_menu_close  );
	EVT_MENU( $this, $this->{menubar}->{ID_EXIT},   \&_menu_exit   );
	EVT_MENU( $this, $this->{menubar}->{ID_UNDO},   \&_menu_undo   );
	EVT_MENU( $this, $this->{menubar}->{ID_REDO},   \&_menu_redo   );
	EVT_MENU( $this, $this->{menubar}->{ID_CUT},    \&_menu_cut    );
	EVT_MENU( $this, $this->{menubar}->{ID_COPY},   \&_menu_copy   );
	EVT_MENU( $this, $this->{menubar}->{ID_PASTE},  \&_menu_paste  );
	EVT_MENU( $this, $this->{menubar}->{ID_ABOUT},  \&_menu_about  );

	# Create the main text control

	$this->{textctrl} = Wx::TextCtrl->new(
		$this,
		-1,
		"", 
	        [ 0, 0 ], 
		[ 100, 100 ],
		wxTE_MULTILINE | wxTE_RICH,
		);

	# Set the font of the new text control to a fixed width font Courier New
	# This font was chosen because of it's availablity on different platforms.

	my $font = Wx::Font->new(10, wxMODERN, wxNORMAL, wxNORMAL, 0, "Courier New");

	my $black = Wx::Colour->new(255,255,255);
	my $white = Wx::Colour->new(0,0,0);
	my $textattr = Wx::TextAttr->new($white, $black, $font);

	$this->{textctrl}->SetDefaultStyle($textattr);


	#Create the statusbar

	$this->CreateStatusBar(2);

	return $this;
}


# This sub is called when the user clicks on menu File item New
# The textctrl and filename is cleared

sub _menu_new {
	my ($this) = @_;
	$this->SetTitle("Perlpad");
	$this->{textctrl}->SetValue("");
	$this->{filename} = "";
	return 1;
}


# This sub is called when the user clicks on menu File item Open
# The dialog that allows the user to choose a new file is displayed
# The text control is then instructed to load the contents of the file
# The title of the frame is altered to show the file's name

sub _menu_open {
	my ($this) = @_;
	my $opendialog = Wx::FileDialog->new($this, "Choose a file to open", 
                                          "", "", "*.*", 0, [0,0]);
	my $result = $opendialog->ShowModal();
	if ($result == wxID_OK) { 
		$this->{filename} = File::Spec->catfile(
			$opendialog->GetDirectory(), $opendialog->GetFilename()
			);
		$this->{textctrl}->LoadFile( $this->{filename} );

		$this->SetTitle( "Perlpad - " . $this->{filename} );
	}
}

# This sub is called when the user clicks on menu File item Exit
# It causes the editor to exit.
# TODO: Check if file was changed and ask if it needs to be saved.

sub _menu_exit {
	exit(0);
}


# This sub is called when the user clicks on menu File item Save
# The text control is instructed to save the file to the filename 
# that we have as the name of the currently opened file.

sub _menu_save {
	my ($this) = @_;
	$this->{textctrl}->SaveFile( $this->{filename} );
	return 1;
}

# This sub is called when the user clicks on menu File item Save As
# The Save As dialog is shown to allow the user to select a new filename
# A new path is constructed with File::Spec to allow for platform independance
# The text control is instructed to save the file to the filename 
# The new filename is stored as the opened file's name

sub _menu_saveas {
	my ($this) = @_;
	my $saveasdialog = Wx::FileDialog->new($this, "Choose a file name and " . 
                                                  "location to save to", 
                                                  "", "", "*.*", 
                                                  wxSAVE, [0,0]);
	my $result = $saveasdialog->ShowModal();
	if ($result == wxID_OK) {
		$this->{textctrl}->SaveFile(File::Spec->catfile(
                                        $saveasdialog->GetDirectory(), 
                                        $saveasdialog->GetFilename()
                                                       )
                                   );
		$this->{filename} = File::Spec->catfile($saveasdialog->GetDirectory(), 
                                                $saveasdialog->GetFilename());
		$this->SetTitle("Perlpad - " . $this->{filename});
	}
}




# This sub is called when the user clicks on menu File item Close
# Does the same thing as File..New
# Clears on the text in the text control and changes the filename 
# of the curently opened file to ''
# TODO: Check if file was changed and ask if it needs to be saved.
sub _menu_close{
	my ($this) = @_;
	$this->SetTitle("Perlpad");
	$this->{textctrl}->SetValue("");
	$this->{filename} = "";

}

# This sub is called when the user clicks on menu Edit item Undo
# Causes text control to undo the last edit
sub _menu_undo {
	my ($this) = @_;
	$this->{textctrl}->Undo();

}

# This sub is called when the user clicks on menu Edit item Redo
# Causes text control to redo the last edit ie Undo the undo. :-)

sub _menu_redo {
	my ($this) = @_;
	$this->{textctrl}->Redo();
}

# This sub is called when the user clicks on menu Edit item Cut
# Causes text control to redo the last edit ie Undo the undo. :-)

sub _menu_cut {
	my ($this) = @_;
	$this->{textctrl}->Cut();
	print "Cut\n";
	#TODO: Put a message in the status "Cut text placed in clipboard"?
}

# This sub is called when the user clicks on menu Edit item Copy

sub _menu_copy{
	my ($this) = @_;
	$this->{textctrl}->Copy();
	print "Copy\n";
	#TODO: Put a message in the status "Copied text placed in clipboard"?
}

# This sub is called when the user clicks on menu Edit item Paste

sub _menu_paste{
	my ($this) = @_;
	$this->{textctrl}->Paste();
	print "Paste\n";
	#TODO: Put a message in the status "Copied text placed in clipboard"?
}

# This sub is called when the user clicks on menu Help item About
# Displays information about the application in a modal dialog

sub _menu_about{
	my ($this) = @_;

	my $dialogtext = "Copyright 2005 by \n" . 
				"\tBen Marsh <blm\@woodheap.org> \n" . 
				"\tAdam Kennedy <cpan\@ali.as>\n" . 
			"All rights reserved.  You can redistribute and/or modify this \n" .
			"bundle under the same terms as Perl itself\n\n" .
			"See http://www.perl.com/perl/misc/Artistic.html";

	Wx::MessageBox($dialogtext, "About perlpad", wxOK|wxCENTRE, $this);
}

1;
