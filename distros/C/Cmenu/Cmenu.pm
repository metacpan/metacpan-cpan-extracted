#****************************************************************************
# Cmenu.pm -- Perl Curses Menu Support Facility 
#
# Last updated Time-stamp: <01/10/20 23:14:23 devel> 
# 
#
# Author:  Andy Ferguson (cmenu@afccommercial.co.uk)
#          AFC Commercial
#          Bangor, Northern Ireland
#          BT19 1PF
#
# derived from [perlmenu] (Version +4.0):
#          Steven L. Kunz
#          Networked Applications
#          Iowa State University Computation Center
#          Ames, IA  50011
#
# Date:    Version 5.0 -- Jan, 2001 -- Complete re-write using Curses code and dialog
#				       'look and feel'. Simplified sub-calls and 
#                                      colour support. Preferences stored in file.
#          Version 5.1 -- Jan, 2001 -- fencepost errors and field edit fixes
#          Version 5.2 -- Jan, 2001 -- bugfix and check for Curses >1.03
#          Version 5.3 -- Feb, 2001 -- Use hash for kseq and fix numeric data entry
#          Version 1.0 -- Apr, 2001 -- Minor fixes and revised for CPAN
#          Version 1.1 -- Oct, 2001 -- Improvements in rc configuration
#
# Notes:   Perl4 - Will not work since it relies on Curses.pm
#                  Use perlmenu.pm instead
#          Perl5 - Requires "Curses" extension available from any CPAN
#		   site (http://www.perl.com/CPAN/CPAN.html).
#                  Will also require Text::Wrap for splash screen calls
#                  
#                  Put the following at top of your code:
#
#                    use Curses;
#                    use Cmenu;
#
# Use:
#             &menu_initialise("title","advice");
#             &menu_init(1,"title");
#             &menu_item("Topic 1","got_1"....);
#             &menu_item("Topic 2","got_2"....);
#             ...
#             &menu_item("Topic n","got_n"....);
#             $sel_text = &menu_display("Select using arrow keys");
#             ...
#             &menu_terminate();
#
#
# Cmenu - Perl library module for curses-based menus & data-entry 
# Copyright (C) 2001     Andy Ferguson, AFC Commercial, Bangor BT19 1PF, UK
#
#    This Perl library module is free software; you can redistribute it
#    and/or modify it under the terms of the GNU Library General Public
#    License (as published by the Free Software Foundation) or the
#    Artistic License.
#
#    This library is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of 
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    Library General Public License for more details.
#
#    You should have received a copy of the GNU Library General Public
#    License along with this library; if not, write to the Free
#    Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#****************************************************************************
#
#****************************************************************************
# BUGS
#
# 1.   Refresh does not redraw top and bottom few lines of the backdrop
#      if the display gets totally trashed
#      Tried defining "screen" as a "window" to no avail
#
# 2.   Cannot find the ncurses BACK-TAB key so there is no default BACK
#      function. User needs to map this to another key
#
# 3.   Does not resize when called as a subshell or whatever, eg. as when called
#      from within "mc". Rsize works OK in a basic xterm.
#
# 4.   No line checking with multi-line subtitles; subtitle or pane may
#      overflow window
#****************************************************************************

package Cmenu;

use Curses;
use Text::Wrap;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     menu_initialise 
	     menu_init
	     menu_item
	     menu_display
	     menu_show
	     menu_popup
	     menu_button_set
	     menu_terminate
	    );

@EXPORT_OK = qw (
		 $menu_sep
		 $menu_sepn
	       );

$Cmenu::VERSION ='1.01';

use vars qw($VERSION $menu_sep $menu_sepn);

BEGIN {
  # Field seperator characters returned after menu activity
  # menu_sep seperates individual fields
  # menu_sepn breaks up field name from field contents
  $menu_sep="¬";
  $menu_sepn="~";
}
  
# ##################################################################################
# Public variables and functions
# ==============================
# These variables and functions are available for user programs
# While others may be accessed, they are in fact surreal
# and may cease to exist in later releases
# ---< variables >------------------------------------------------------------------
# $menu_screen          : the base curses screen
# $menu_screen_lines    : current logical depth of the screen
# $menu_screen_cols     : current logical width of the screen
# $menu_inlay           : the main display
# $menu_inlay_lines     : depth of the menu inlay
# $menu_inlay_cols      : width of the menu inlay
# $menu_inlay_y         : y offset of inlay from screen top 0
# $menu_inlay_x         : x offset of inlay from screen left 0
# $menu_advice          : standard text for display at foot
# ---< functions >------------------------------------------------------------------
# All menu functions generally apply keypad, echo and other Curses ops, on
# return from any function Curses settings can be guaranteed as if these calls 
# had been made directly
#    &echo();
#    &nocbreak();
#    &curs_set(1);
# keypad control is only applied to new windows which should always be destroyed
# before returning.
# ----------------------------------------------------------------------------------
# &menu_initialise      : sets up all menu variables and constructs
# &menu_button_set      : swicthes menu buttons on and off
# &menu_item            : create a menu item
# &menu_display         : display a menu and get a response from it
# &menu_popup           : flash a busy window
# &menu_show            : gives a full screen text display
# &menu_terminate       : close the menu environment down
# ----------------------------------------------------------------------------------
# All Curses functions can of course be used in user programs but be aware that
# management of all windows then becomes the users responsibility and behaviour
# of the menuing environment may be unpredictable
# ##################################################################################

# ##################################################################################
# Variable Definitions
# ##################################################################################

my $did_initterm = 0;	# We already got escape sequences for arrows, etc.

# Keystroke arrays
my %kseq=();               # hash for function key translation
my $key_max=0;             # longest keystroke

# Windows
my $menu_screen;           # the backdrop
my $menu_inlay;            # background for the menu window with shadow etc
my $menu_window;           # menu window with text elements
my $menu_pane;             # where the menu options actually get drawn
my $menu_popup;            # special for popup and splash displays

# Window elements
my $menu_title;            # title of script in backdrop
my $menu_top_title;        # title of menu
my $menu_sub_title;        # sub-title of a menu
my $menu_sub_title_lines;  # depth of sub-title
my $menu_advice;           # message at foot of backdrop
my $menu_item_pos;         # where menu items will start 
my $menu_indent;           # where menu item labels will start

my $menu_index;            # counter of menu items

# Extent of display screen - fixed - unchangeable - from TERM settings
# Always starts at 0,0
my $menu_screen_cols=0;         # - COLS from Curses   } size of the full screen
my $menu_screen_lines=0;        # - LINES from Curses  }

# Extent of Menu Inlay - size and position of main window
# Amendable via preferences
# Mono screens lose the shadow so get a bigger inlay
my $menu_inlay_lines=0;
my $menu_inlay_cols=0;
my $menu_inlay_y=3;         # 2 for mono
my $menu_inlay_x=6;         # 4 for mono

# Extent of Menu text pane
# All defined at runtime depending on the menu items
my $menu_pane_lines=0;
my $menu_pane_cols=0;
my $menu_pane_y=0;
my $menu_pane_x=0;
my $menu_pane_scroll; 

my $menu_resized=0;          # trigger for terminal resizing
my $menu_style=0;            # 
my $max_item_len=0;          # longest menu item
my $max_sel_len=0;           # longest label length
my $menu_top_option=0;       # current menu item at the top of the display
my $menu_cur_option=0;       # the active menu option during navigation
   
# define global colour variables
my %menu_attributes=();      # load and hold color definitions
my $menu_hascolor;           # terminal colour capability flag

# Initialise menu item arrays
my @menu_sel_text =();             # Menu item text
my @menu_sel_style =();            # Menu item type
my @menu_sel_label = ();           # Menu item label
my @menu_sel_flag = ();            # Menu item special
my @menu_sel_return = ();          # value to be returned on selection
my @menu_sel_pos = ();             # Menu item position (data fields)
                                   #   max length + dec.places + 0

# User hacks
my($menu_hack25)=0;                # hack to make a small screen bigger


# Set the default file for help display
my $menu_help="help.txt";
my $menu_help_root="/etc/Cmenu/";

# Initialise button arrays
my @menu_button = ();
my @menu_button_action = ();
# Default text for buttons
$menu_button[1]="Select";
$menu_button[2]="Help";
$menu_button[3]="Exit";
# What each button will do if pressed
$menu_button_action[1]="ACCEPT";
$menu_button_action[2]="HELP";
$menu_button_action[3]="QUIT";

my $menu_buttons=3;                # start with all buttons available
my $menu_hot_button=1;             # first button will be active

my $buffer = "";                   # temp storage for field editing

# ##################################################################################
# Initialisation Routines
# ##################################################################################

#**********
#  MENU_INITIALISE
#
#  Function:	Setups Curses elements and prepares a backdrop
#		Also define terminal atributes and defines default colours
#		(these can be changed after this function has been called)
#
#  Call format:	&menu_initialise("title string","advice note string");
#
#  Arguments:   - the title of the Menu application
#                 this is displayed in the top left-hand corner of all screens 
#               - an advice note to be displayed on all pages 
#                 normally displayed at the foot of each screen
#                 may be replaced by user comments with &menu_advice routine
#
#  Returns:	Main window - this can be referenced externally for 
#               direct drawing by user program (untested)
#**********
sub menu_initialise {
 my ($title,$advice)=@_;
 my ($key,$action);

 $menu_title=$title;
 $menu_advice=$advice;

 # Only do this once
 if($did_initterm==0) {

# ##################################################################################
# BLOCK 1
# =======
# Initialise curses structures
# ##################################################################################

   if(!$menu_screen) {          # Checks whether user has done this already
     $menu_screen=&initscr();   # create a curses structure
   }                       # auto save tty settings to be restore at end by endwin
   $menu_hascolor=eval {has_colors()};
   start_color(); 

   
# ##################################################################################
# BLOCK 2
# =======
# Setup key sequences for input filtering
# These are the defaults - may be over-ridden by loaded preferences
# ##################################################################################

# ##################################################################################
# Unable to test the alternative getcap/tigetstr/tput settings so these are
# left alone. tigetstr continues to not work on Linux/Curses
# --------------------------------------------------------------------------------
# Functional mappings are
# Cursor movement
#   UP       : move up
#   DOWN     : move down
#   RITE     : move right
#   LEFT     : move left
#   LYNXR    : move right - can mimic lynx-style motion
#   LYNXL    : move left - can mimic lynx-style motion
# Large cursor movement
#   HOME     : go to top (of menu)
#   END      : go to bottom (of menu)
#   NEXT     : next page 
#   PREV     : previous page
#   JUMP     : leap to a specific menu item 
# action
#   HELP     : display active help page/info
#   RET      : action current selection
#   EXIT     : cancel or abort current operation
#   QUIT     : go back a menu
#   SPACE    : toggle radio button or action button (equiv to RET)
#   REFS     : refresh the screen
# button or field navigation
#   TAB      : next field
#   BACK     : previous field
# text buffer editing
#   DEL      : delete chracter right
#   BS       : delete character left
#   INS      : toggle insert mode
#   KILL     : kill current line to buffer
#   YANK     : yank buffer
#   BUFF     : empty the text buffer
# Specials
# KEY_RESIZE : } trap screen resizing   } these are input from Curses
#   401      : }   "     "       "      } not by the user
#   NOP      : do nothing
# --------------------------------------------------------------------------------
 
# ==================================================================================
# Next blocks are system specific - choose the one(s) you need
# ==================================================================================
# Method 1 (getcap) - UNTESTED
# Uncomment if you have "getcap"
# --------------------------------------------------------------------------------
#   $kseq{&getcap('ku')}="UP";	  # Cursor-up
#   $kseq{&getcap('kd')}="DOWN";  # Cursor-down
#   $kseq{&getcap('kr')}="RITE";  # Cursor-right
#   $kseq{&getcap('kl')}="LEFT";  # Cursor-left
#   $kseq{&getcap('cr')}="RET";	  # Carriage-return
#   $kseq{&getcap('nl')}="RET";	  # New-line

# --------------------------------------------------------------------------------
# Method 2 (tigetstr) - UNTESTED
# Uncomment if you have tigetstr (Solaris) instead of "getcap"
# --------------------------------------------------------------------------------
#   $kseq{&tigetstr('kcuu1')}="UP";	  # Cursor-up
#   $kseq{&tigetstr('dcud1')}="DOWN";	  # Cursor-down
#   $kseq{&tigetstr('kcuf1')}="RITE";	  # Cursor-right
#   $kseq{&tigetstr('kcub1')}="LEFT";	  # Cursor-left
#   $kseq{&tigetstr('cr')}="RET";	  # Carriage-return
#   $kseq{&tigetstr('nl')}="RET";	  # New-line

# --------------------------------------------------------------------------------
# Method 3 (tput)
# Uncomment if you have terminfo (and tput) instead of "getcap"
# Works for modern Linux
# --------------------------------------------------------------------------------
   $kseq{`tput kcuu1`}="UP";	  # Cursor-up
   $kseq{`tput kcud1`}="DOWN";	  # Cursor-down
   $kseq{`tput kcuf1`}="RITE";	  # Cursor-right
   $kseq{`tput kcub1`}="LEFT";	  # Cursor-left
   $kseq{`tput kent`}="RET";	  # Carriage-return
		# HP-UX 9.05 users: try $kseq[4] = `tput cr` if
		#                   "tput kent" gives errors
   $kseq{ `tput nel`}="RET";	  # New-line
# --------------------------------------------------------------------------------
# Method 4
# Explicit control sequences - should work for all terminals regardless
# These should be Uncommented for all systems/platforms
# Hacks for Xterms and standard emacs style definitions
# --< Xterm hacks >---------------------------------------------------------------
   $kseq{"\033[A"}="UP";        # Ansi cursor-up (for DEC xterm)
   $kseq{"\033[B"}="DOWN";      # Ansi cursor-down (for DEC xterm)
   $kseq{"\033[C"}="RITE";     # Ansi cursor-right (for DEC xterm)
   $kseq{"\033[D"}="LEFT";     # Ansi cursor-left (for DEC xterm)
   # added mapping for Home/End and Page buttons for xterms
   $kseq{"\033[E"}="PREV";    # Ansi guess (for DEC xterm)
   $kseq{"\033[F"}="END";     # Ansi end key (for DEC xterm)
   $kseq{"\033[G"}="NEXT";    # Ansi guess (for DEC xterm)
   $kseq{"\033[H"}="HOME";    # Ansi home key (for DEC xterm)
# --< kvt specials >---------------------------------------------------------------
# --  KDE2 and its terminal kvt do funny things with the keys
# --  keymaps may be lost entirely with the key bindings
   $kseq{scalar(KEY_SELECT)}="END";   # end key (for kvt)
   $kseq{scalar(KEY_FIND)}="HOME";    # home key (for kvt)
# --< Emacs hacks >---------------------------------------------------------------
   $kseq{"\cA"}="HOME";       # begin of line
   $kseq{"\cE"}="END";        # end of line
   $kseq{"\cF"}="RITE";      # next char
   $kseq{"\cB"}="LEFT";      # prev char
   $kseq{"\cN"}="TAB";        # next field
   $kseq{"\cP"}="BACK";       # prev field
   $kseq{"\cL"}="REFS";       # redraw screen
   $kseq{"\cD"}="DEL";        # delete right
   $kseq{"\cK"}="KILL";       # kill line
   # Normally yank_line would be "\cY" (C-y), unfortunately both C-z and C-y are
   # are used to send the suspend signal in our environment. Bind it to
   # C-v for a lack of anything better.
   $kseq{"\cV"}="YANK";       # yank/paste buffer
   # buffer
   $kseq{"\cX"}="BUFF";       # copy and kill to buffer

# --------------------------------------------------------------------------------
# Method 5
# Standard PC keyboard commands
# with ncurses keypad turned on - these should work for any terminal type
# either termcap or terminfo
# --------------------------------------------------------------------------------
   $kseq{scalar(KEY_HOME)}="HOME";    # home
   $kseq{scalar(KEY_END)}="END";      # end
   $kseq{scalar(KEY_PPAGE)}="PREV";   # page up
   $kseq{scalar(KEY_NPAGE)}="NEXT";   # page down
   $kseq{scalar(KEY_IC)}="INS";       # insert toggle
   $kseq{scalar(KEY_DC)}="DEL";       # delete
   $kseq{scalar(KEY_BACKSPACE)}="BS"; # backspace
   $kseq{"\cI"}="TAB";                # tab
   $kseq{scalar(KEY_BTAB)}="BTAB";    # shifted tab
   $kseq{scalar(KEY_UP)}="UP";        # up arrow
   $kseq{scalar(KEY_DOWN)}="DOWN";    # down arrow
   $kseq{scalar(KEY_LEFT)}="LYNXL";   # left arrow
   $kseq{scalar(KEY_RIGHT)}="LYNXR";  # right arrow
   $kseq{scalar(KEY_ENTER)}="RET";    # enter key
   $kseq{scalar(KEY_BREAK)}="EXIT";   # break
   $kseq{"\cJ"}="RET";                # normal return key

   # Functions keys have no special meaning - user mapable
   # some helpful defaults are set here but are not necessary
   $kseq{scalar(KEY_F(1))}="HELP";    # Func key 1
   $kseq{scalar(KEY_F(2))}="NOP";     # Func key 2
   $kseq{scalar(KEY_F(3))}="NOP";     # Func key 3
   $kseq{scalar(KEY_F(4))}="NOP";     # Func key 4
   $kseq{scalar(KEY_F(5))}="NOP";     # Func key 5
   $kseq{scalar(KEY_F(6))}="NOP";     # Func key 6
   $kseq{scalar(KEY_F(7))}="NOP";     # Func key 7
   $kseq{scalar(KEY_F(8))}="QUIT";    # Func key 8
   $kseq{scalar(KEY_F(9))}="EXIT";    # Func key 9
   $kseq{scalar(KEY_F(10))}="NOP";    # Func key 10
   $kseq{scalar(KEY_F(11))}="NOP";    # Func key 11
   $kseq{scalar(KEY_F(12))}="EXIT";   # Func key 12

# ##################################################################################
# BLOCK 3
# =======
# Load defaults from a config file if it exists
# ##################################################################################

   # Does the terminal have colour?
   $menu_hascolor = eval { has_colors() };

   if($menu_hascolor==1) {
	 # Set default colours for init_pairs
	 $menu_attributes{"backdrop"}="6.4.NORMAL";
	 $menu_attributes{"advice"}="6.4.BOLD";
	 $menu_attributes{"text"}="0.7.NORMAL";
	 $menu_attributes{"title"}="3.7.BOLD";
	 $menu_attributes{"option"}="1.7.BOLD";
	 $menu_attributes{"button"}="7.7.BOLD";
	 $menu_attributes{"scroll"}="2.7.BOLD";
	 $menu_attributes{"rtext"}="7.4.BOLD";
	 $menu_attributes{"rtitle"}="6.4.BOLD";
	 $menu_attributes{"roption"}="3.4.BOLD";
	 $menu_attributes{"edge"}="7.7.BOLD";
	 $menu_attributes{"dull"}="0.7.BOLD";
	 $menu_attributes{"help"}="0.2.BOLD";
	 $menu_attributes{"warn"}="7.3.NORMAL";
	 $menu_attributes{"error"}="7.1.NORMAL";
	 $menu_attributes{"popup"}="3.2.BOLD";
	 $menu_attributes{"shadow"}="0.0.NORMAL";
   } else {
	 # Set mono defaults
	 $menu_attributes{"backdrop"}="DIM";
	 $menu_attributes{"advice"}="NORMAL";
	 $menu_attributes{"text"}="NORMAL";
	 $menu_attributes{"title"}="NORMAL";
	 $menu_attributes{"option"}="BOLD";
	 $menu_attributes{"button"}="DIM";
	 $menu_attributes{"scroll"}="NORMAL";
	 $menu_attributes{"rtext"}="REVERSE";
	 $menu_attributes{"rtitle"}="REVERSE";
	 $menu_attributes{"roption"}="REVERSE|BLINK";
	 $menu_attributes{"edge"}="DIM";
	 $menu_attributes{"dull"}="DIM";
	 $menu_attributes{"help"}="REVERSE";
	 $menu_attributes{"warn"}="REVERSE";
	 $menu_attributes{"error"}="REVERSE";
	 $menu_attributes{"popup"}="NORMAL";
   }
   if(-e "/etc/Cmenu/cmenurc") {
     # load system wide preferences
     &menu_config_file("/etc/Cmenu/cmenurc");
   }
   if(-e "~/.cmenurc") {
     # Load the users specific preferences
     &menu_config_file("~/.cmenurc");
   }
   if(-e "cmenurc") {
     # Load the application specific preferences
     &menu_config_file("cmenurc");
   }

   # Now setup colour rendering
   menu_set_colours();

# ##################################################################################
# BLOCK 4
# =======
# Draw the screens backdrop and establish dimensions
# ##################################################################################

   &menu_redraw_backdrop();

   $did_initterm = 1;
 }

 # Calculate the longest keystroke sequence
 $key_max=0;
 foreach $key(sort(keys(%kseq))) {
   if(length($key)>$key_max) { $key_max=length($key); }
    }
}

#**********
#  MENU_CONFIG_FILE
#
#  Function:	Loads user over-rides from a config file
#
#  Call format:	&menu_config_file("filename");
#
#  Notes:       See the modules sample file for data structure
#**********
sub menu_config_file {
  my ($filename) = @_;
  my ($type,$key,$action);

  open(IN,"<$filename");
  while(<IN>) {
    if(length($_)>1) {
      chop;
	  # Remove all spaces
	  s/ //g;
      ($type,undef,$key,$action)=split(/:/);
      if(($type eq "C")&&($menu_hascolor)) { $menu_attributes{$key}=$action; }
      if(($type eq "M")&&(!$menu_hascolor)){ $menu_attributes{$key}=$action; }
      if($type eq "H") { $menu_help_root=$action; }
      if($type eq "K") { $kseq{$key}=$action; }
      if($type eq "X") {
		if($action eq "hack25") { $menu_hack25=1; }
	  }
    }
  }
  close(IN);
}

#**********
#  MENU_SET_COLOURS
#
#  Function:	Defines and sets up terminal and user defined colours
#
#  Call format:	&menu_set_colours();
#
#  Notes:       NONE
#**********
sub menu_set_colours {

  my ($i,$x,$y,$z,$key);
  my @menu_colour=();

  if ($menu_hascolor==1) {	
	# Set colours
	# Default colour preferences
	$menu_colour[0]=COLOR_BLACK;
	$menu_colour[1]=COLOR_RED;
	$menu_colour[2]=COLOR_GREEN;
	$menu_colour[3]=COLOR_YELLOW;
	$menu_colour[4]=COLOR_BLUE;
	$menu_colour[5]=COLOR_MAGENTA;
	$menu_colour[6]=COLOR_CYAN;
	$menu_colour[7]=COLOR_WHITE;
	# Set color rendering
	$i=1;
	foreach $key(keys(%menu_attributes)) {
	  ($x,$y,$z)=split(/\./,$menu_attributes{$key});
	  init_pair($i,$menu_colour[$x],$menu_colour[$y] );
	  $menu_attributes{$key}=COLOR_PAIR($i)|menu_set_attributes($z);
	  $i++;
	}
  } else {
	# for monochrome terminals
	foreach $key(keys(%menu_attributes)) {
	  $menu_attributes{$key}=menu_set_attributes($menu_attributes{$key});
	}
	# Make inlay larger since there is no shadow
	$menu_inlay_y=$menu_inlay_y-1;
	$menu_inlay_x=$menu_inlay_x-2;
  }
  clear();                # clear the screen

}

#**********
#  MENU_SET_ATTRIBUTES
#
#  Function:	Set display attributes appending to any existing colour info
#
#  Call format:	&menu_set_attributes(attribute_string);
#
#  Notes:       The attribute string contains any Curses element from this list
#                   NORMAL BOLD STANDOUT DIM BLINK REVERSE UNDERLINE
#               each seperated by a vertical bar (|) This is the format passed
#               in from the Config file
#               These attribs cannot always be rendered by the terminal
#**********
sub menu_set_attributes {
  my($x)=@_;
  my($atts)=0;
  my($i);
  my(@y)=();

  if(length($x)>0) {
	@y=split(/\|/,$x);
	for($i=0;$i<=$#y;$i++) {
	ATTRIBUTES: for($y[$i]) {
		/NORMAL/ && do {
		  $atts=$atts|A_NORMAL;
		  last ATTRIBUTES;
		};
		/STANDOUT/ && do {
		  $atts=$atts|A_STANDOUT;
		  last ATTRIBUTES;
		};
		/UNDERLINE/ && do {
		  $atts=$atts|A_UNDERLINE;
		  last ATTRIBUTES;
		};
		/REVERSE/ && do {
		  $atts=$atts|A_REVERSE;
		  last ATTRIBUTES;
		};
		/BLINK/ && do {
		  $atts=$atts|A_BLINK;
		  last ATTRIBUTES;
		};
		/DIM/ && do {
		  $atts=$atts|A_DIM;
		  last ATTRIBUTES;
		};
		/BOLD/ && do {
		  $atts=$atts|A_BOLD;
		  last ATTRIBUTES;
		};
	  }
	}
  }
  return($atts);
}

#**********
#  MENU_REDRAW_BACKDROP
#
#  Function:	Draws the backdrop and then inlay
#
#  Call format:	&menu_redraw_backdrop();
#
#  Notes:       Also called to refresh the screen on command or after resizing
#**********
sub menu_redraw_backdrop {
  # Setup Curses dimensions
  $menu_screen_cols=COLS;
  $menu_screen_lines=LINES;
  $menu_resized=0;		# flag to detect subsequent resizing
                                # this only works on a direct xterm - spawned xterms such
                                # as mc sub-shells will not be detected
  
  # Draw title on the backdrop
  # Backdrop fills whole screen with a title at the top (left-just)
  # and a small advice note at the foot (centred)
  &bkgd($menu_screen,$menu_attributes{"backdrop"});
  &clear($menu_screen);
  if(length($menu_title)<1) {
    &addstr($menu_screen,0,1,"Cmenu Menu");
  } else {
    &addstr($menu_screen,0,1,$menu_title);
  }
  &move($menu_screen,1,1);
  &hline($menu_screen,ACS_HLINE,$menu_screen_cols-2);
  # Display system advice message
  &attrset($menu_screen,$menu_attributes{"advice"});
  &move($menu_screen,$menu_screen_lines-1,0);
  if(length($menu_advice)>0) {
    &addstr($menu_screen,$menu_screen_lines-1,($menu_screen_cols-length($menu_advice))/2,$menu_advice);
  }
  
  if($menu_hascolor) {
    # Draw basic Window inlay with shadow (colour only)
    attrset($menu_screen,$menu_attributes{"shadow"});
    move($menu_screen,$menu_inlay_y+1,$menu_screen_cols-$menu_inlay_x);
    vline($menu_screen," ",$menu_screen_lines-($menu_inlay_y*2));
    move($menu_screen,$menu_inlay_y+1,$menu_screen_cols-$menu_inlay_x+1);
    vline($menu_screen," ",$menu_screen_lines-($menu_inlay_y*2));
    move($menu_screen,$menu_screen_lines-$menu_inlay_y,$menu_inlay_x+2);
    hline($menu_screen," ",$menu_screen_cols-($menu_inlay_x*2)-2);
  }
  # Create Window insert
  $menu_inlay=newwin($menu_screen_lines-($menu_inlay_y*2),$menu_screen_cols-($menu_inlay_x*2),$menu_inlay_y,$menu_inlay_x);
  bkgd($menu_inlay,$menu_attributes{"text"});
  &clear($menu_inlay);
  
  noutrefresh($menu_screen);
  
  # Sets bounds for Window inlay
  $menu_inlay_lines=$menu_screen_lines-($menu_inlay_y*2);
  $menu_inlay_cols=$menu_screen_cols-($menu_inlay_x*2);
}

#**********
#  MENU_TERMINATE
#
#  Function:	Closedown all Curses structures and quit
#
#  Call format:	&menu_terminate("Message text");
#
#  Arguments:	- Text message to be left on the screen when program finishes
#                 This is not a Curses string, just a simple Perl echo
#
#  Returns:	Peace and Happiness for all ManKind
#**********
sub menu_terminate {
  my ($message)=@_;

  my($key);

  &delwin($menu_inlay);
  &standend();
  &clear();
  &refresh();                 # clears the screen
  &curs_set(1);               # turn the cursor back on
  &endwin();                  # closes all structures and auto restores tty
  print "$message\r\n";
  exit();
}

# ##################################################################################
# Menu Processing and Navigation
# ##################################################################################

#**********
#  MENU_INIT
#
#  Function:	Initialize a new menu structure: menu arrays, title, and "top" flags.
#
#  Call format:	&menu_init("Top Title","Sub Titles","HelpFile");
#
#  Arguments:   - "Top Title" is the title of the menu displayed centred in
#                 the window inlay
#               - "Sub Title" is text comments provided to describe the menu or
#                 give clues to its usage; user provided.
#                 Normally centred unless greater than the width of the window
#               - "HelpFile" defines a help file to be displayed when the
#                 help key is pressed. Help files can be associated with individual
#                 menu items so this file is used when an item has no help file
#                 See menu_help for more information on these help facilities
#
#  Returns:	Window value from "initscr" call.
#
#**********
sub menu_init {
  my ($top_title,$sub_title,$help_page) = @_;

  my ($i,$justify);


  $menu_top_title=$top_title;
  $menu_sub_title=$sub_title;

  # Sort out undefined variables to their default
  if(!$help_page) {
    $menu_help="help.txt"; 
  } else {
    $menu_help=$help_page;
  }

  &menu_draw_inlay();

#  $item_lines_per_screen = $last_line - $first_line + 1;

# Init menu items array
  @menu_sel_text = ();		# Selection text for each item
  @menu_sel_label = ();	        # Action text/label for each item
  @menu_sel_style = ();         # Display style for menu item
  @menu_sel_flag = ();  	# Data associated with menu item
  @menu_sel_pos = ();           # Position for data field
  $menu_index = 0;		# menu item counter

# Init some other key variables
  $max_item_len = 0;		# max length of menu item text
  $max_sel_len = 0;             # length of selection text/label

# Return window value from "initscr" call.
  &noutrefresh($menu_inlay);
  $menu_inlay;
}

#***********
#  MENU_ITEM
#
#  Function:	Add an item to the active menu.
#               Maintained as a set of arrays
#               This function now controls style of presentation
#               so that a menu can have mixed type options
#
#  Call format:	&menu_item("Item text","Text label",item_style,pre_set_flag,"item_pos");
#
#  Arguments:	- "Item text" the string presented in menu. Required.
#                 If this item is blank the menu item will be totally ignored
#                 This may be useful when displaying blank fields or empty records
#		        - "Text label" String returned if selected. Optional.
#                 This will also be used as an abbreviated name in some styles, 
#                 the first character being the option letter (auto-capitalised)
#                 Although some options do not need a label, it is strongly
#                 recomended that a label is provided
#               - Item style - how the menu item should be presented
#                 Notice that menu style is determined at item level rather
#                 than globally for the menu; this permits a mixture of menu
#                 items to be displayed
#                 Be careful though when mixing inappropriate types as the
#                 return values may be difficult to differentiate
#                 Possibilities include
#                    0 - (default) item with text labels
#                        when selected an item will return the Text_label
#                        which is also shown to the left of the item text
#                    1 - item with numeric labels
#                        selected items will still return the Text_label but
#                        the item text will be prefixed with an option number
#                        Option number are incremental; if you want to force
#                        a return number, use item type 8
#                    2 - radio buttons
#                        item text is prefixed with [ ] or [X] for unset and set
#                        items; setting of items is controlled by making
#                        pre_set_flag non-zero for an item
#                        the selected item returns its Text_label
#                    3 - check buttons
#                        as for radio buttons except styled as ( ) or (+)
#                        any number of buttons can be on
#                        returns a string of ON buttons (all other buttons
#                        may be assumed to be off). The string is a token
#                        spererated list, break out items with split function
#                        Field spererator is $menu_sep
#                        items are identified by their Text_label
#                    4 - left justified data field (display only)
#                        Text_labels are usually left-just, this type is for
#                        data forms; text_labels are right-just
#                        Data fields (item text) are left justified
#                        Text_label is returned 
#                    5 - right justified data field (display only)
#                        as for style 4 except item_text is right-just
#                        to the maximum width of the largest field
#                    6 - edit alphanumeric field
#                        displayed like a type 4 but if selected may be edited
#                        revised data is returned as a tokenised string
#                        Field sep is $menu_sepn, seperate using split
#                        Editing function assumes and permits alpha text
#                    7 - edit numeric field
#                        as for style 6 except only numeric data is permitted
#                        pre-set_flag can be used to specifiy the number of
#                        decimal places in the number
#                    8 - offset text label (return label stored in pre_set_flag
#                        Since the Text_label can be displayed as part of the menu
#                        it may not always be useful as a return value e.g. when
#                        displaying records. the pre_set_flag can be used instead
#                        as the return value
#                        The style of presentation is as for type 4
#                        used in data entry forms for style consistency when a regular
#                        menu option is required
#                    9 - seperator
#                        allows inactive spaces to be included in complex menus
#                        to break up the display
#                        The labels are used directly as textual seperators
#                        it must at least be " " or the item will be ignored
#		        - pre_set_flag: Value to pre-set multiple selection menu. Optional.
#		          (neg=lockout selection,0=allow selection,1=preset selection)
#                 For radio/checklists - toggles options on (1) or off (0)
#                 For offset items this is the value to be returned
#               - item_pos: specifies the explicit location of a data field  
#                 expressed as a string of numbers
#                 For numeric field, indicates decimal precision
#                 For alpha-fields indicates maximum length
#                 eg 20 4 6
#                    20 max field length
#                     4 numbers before dec.pt
#                     6 numbers after dec.pt
#
#  Returns:	nothing useful or next menu index if you want it
#***********
sub menu_item {
  my ($item_text,$item_sel,$item_style,$item_data,$item_pos) = @_;
  my ($i);

# Sanity checks
  if (!$item_style) { $item_style = 0; }            # force null sets to zero
  if (!$item_text) {                                # return if there was no text
    if($item_style<6) {
      return($menu_index);
    } else {
      $item_text="";
    }
  }
  if (!$item_data) {                                 # force null sets to zero
    if(($item_style==6)||($item_style==7)) {         # set defaults for editing
      $item_data=$menu_index;
    } else {
      $item_data = 0; 
    }
  }
  if (!$item_pos) {                                 # force null sets to zero
    if(($item_style==6)||($item_style==7)) {         # set default for editing
      $item_pos="10 0 0";
    } else {
      $item_pos = 0; 
    }
  }

  # Adjust max length value (for centering menu) - do this later when displaying
  # Test the length of the item text
  if(($item_style==6)||($item_style==7)) {         # set default for editing
    ($i,undef,undef)=split(/ /,$item_pos);
    if ($i > $max_item_len) { $max_item_len = $i; }
  } else {
    $_ = length($item_text);
    if ($_ > $max_item_len) { $max_item_len = $_; }
  }
  # Test the length of the Text_label
  # For numeric or radio labels, this is forced to be 3 chracters long
  $_ = length($item_sel);
  if(($item_style==1)||($item_style==2)||($item_style==3)) {
    $_=3;
  }
  if (($_<3)) { $_=3; }
  if ($_ > $max_sel_len) { $max_sel_len = $_; }

# Load into arrays and adjust index
  $menu_sel_text[$menu_index] = $item_text;
  $menu_sel_flag[$menu_index] = 0;                # empty as defualt
  if (!$item_sel) {
    # if no selected text is given, use the number of the item index
    $item_sel= $menu_index;
  }
  $menu_sel_label[$menu_index] = $item_sel;        # usually the data label
  $menu_sel_return[$menu_index] = $item_sel;       # the data label is usually returned too
  $menu_sel_style[$menu_index] = $item_style;      # type of menu item
  # Deal with special item types needing extra data
  if(($item_style==2)||($item_style==3)) {
    $menu_sel_flag[$menu_index] = $item_data;      # toggle switches
  }
  if($item_style==6) {
    # editable field returns this label
    $menu_sel_return[$menu_index] = $item_data;    #
    # this is an editable field so set max length and position
    $menu_sel_pos[$menu_index] = $item_pos;        # 
  }
  if($item_style==7) {
    # editable field returns this label
    $menu_sel_return[$menu_index] = $item_data;    #
    # this is an editable field so set max length and position
    $menu_sel_pos[$menu_index] = $item_pos;        # 
  }
  if($item_style==8) {
    # offset return values
    $menu_sel_return[$menu_index] = $item_data;     # the data label is usually returned too
  }
  $menu_index++;
}

#**********
#  MENU_ADVICE
#
#  Function:	Displays an advice message at the foot of the screen
#
#  Call format:	&menu_advice([NULL|"advice string"]);
#
#  Arguments:	Advice message to be displayed
#               If no message is given, displays a standard default message
#               passed when module initialises (see menu_initialise)
#               This message is therefore self clearing
#
#  Returns:	user friendliness
#**********
sub menu_advice {
  my ($advice)=@_;

  if($menu_buttons==0) {
    # Display messages in button bar
    &attrset($menu_inlay,$menu_attributes{"dull"});
    &move($menu_inlay,$menu_inlay_lines-2,1);
    &clrtoeol($menu_inlay);
    move($menu_inlay,$menu_inlay_lines-2,$menu_inlay_cols-1);
    vline($menu_inlay,ACS_VLINE, 1);
    if(length($advice)>0) {
      &addstr($menu_inlay,$menu_inlay_lines-2,($menu_inlay_cols-length($advice))/2,$advice);
    } else {
      &addstr($menu_inlay,$menu_inlay_lines-2,($menu_inlay_cols-length($menu_advice))/2,$menu_advice);
    }
    &noutrefresh($menu_inlay);
  } else {
    # display messages at foot of screen
    &attrset($menu_screen,$menu_attributes{"advice"});
    &move($menu_screen,$menu_screen_lines-1,1);
    &clrtoeol($menu_screen);
    if(length($advice) > 0 ) {
      &addstr($menu_screen,$menu_screen_lines-1,($menu_screen_cols-length($advice))/2,$advice);
    } else {
      &addstr($menu_screen,$menu_screen_lines-1,($menu_screen_cols-length($menu_advice))/2,$menu_advice);
    }
    &noutrefresh($menu_screen);
  }
}

#**********
#  MENU_NAVIGATE 
#
#  Function:	Allows user to navigate the current menu until an items is selected
#		or the menu is exited
#
#  Call format:	&menu_navigate();
#
#  Returns:     selected menu item at exit point
#		%UP%    -- quit menu 
#               %EMPTY% -- abort menu
#
#  Notes:	1) This routine ALWAYS sets "nocbreak" and "echo" terminal 
#		   modes before returning.
#		2) This routine exits directly (after calling the optional 
#		   "quit" routine) if "q"|"Q" is pressed.
#               3) performs all menu functions including field editing
#                  returning any data as a tokenised string
#**********
sub menu_navigate {
 
  my ($help,$i,$j,$style,$new_option,$action,$trunc,$indent);
  my $ret="";
  
  # Check for no "menu_item" calls.
  if ($#menu_sel_text < 0) {
    return("%EMPTY%".$menu_sep);
  }
  
  # curses cookery
  cbreak();               # permits keystroke examination
  noecho();               # no input echo until enabled explicitly
  curs_set(0);            # turn the cursor off
  
  # reset and draw button bar
  $menu_hot_button=1;
  &menu_button_bar(0);
  
  &menu_draw_window();
  noutrefresh($menu_window);
  
  # Compute prepend length (for stuff we prepend to each selection text)
  #   indent   : indent to centre items
  #   item_pos : where item text starts
  $menu_item_pos=$max_sel_len+1;

  # Also trunc is number of characters to shorten text
  # decide whether or not to truncate menu items
  $trunc=($max_item_len+$menu_item_pos)-($menu_pane_cols-2);
  if($trunc<=0) {
    $menu_indent=($trunc*-1)/2;
    $trunc=0;
  } else {
    $menu_indent=0;
  }
  if($trunc>=$max_item_len) {
    # menu not wide enough to show anything so abort this menu
    &menu_advice("Item descriptions too long - Aborting!");
    &refresh();
    getch($menu_screen);
    $ret="%UP%".$menu_sep;
  } else {

    &menu_create_pane();

  GET_KEY:  do {
      # Draw up and down symbols
      # Skip the next next bit if everything fits on one page
      if(($menu_pane_lines-3)<$menu_index-1) {
	# Display page excess arrows
	move($menu_window,0,$menu_pane_scroll);
	if($menu_top_option>0) {
	  # there are items above this
	  attrset($menu_window,$menu_attributes{"scroll"});
	  addstr($menu_window, "-^-");
	} else {
	  attrset($menu_window,$menu_attributes{"dull"});
	  hline($menu_window,ACS_HLINE,3);
	}  
	move($menu_window,$menu_pane_lines-1,$menu_pane_scroll);
	if($menu_index-1>$menu_top_option+$menu_pane_lines-3) {
	  # there are items below this
	  attrset($menu_window,$menu_attributes{"scroll"});
	  addstr($menu_window, "-v-");
	} else {
	  attrset($menu_window,$menu_attributes{"edge"});
	  hline($menu_window,ACS_HLINE,3);
	}  
	noutrefresh($menu_window);
      }

      doupdate();

      # Collect key sequences until something we recoginize 
      # (or we know we don't care)
            $action = &menu_key_seq($menu_pane);

      # ------------------------------------------------------------------------------
      # Switch construct for dealing with key sequence input
      # ------------------------------------------------------------------------------
    KEYWAIT: for ($action) {
	# Set return value as current option
	$ret=$menu_sel_return[$menu_cur_option].$menu_sep;

	# General cursor movement
	/LEFT/ && do {		# Left arrow
	  # Treat this like an UP-Menu request
	  $action="UP";
#	  redo KEYWAIT;
	};
	/RITE/ && do {		# Right arrow
	  # Treat this like a RETURN
	  $action="DOWN";
#	  redo KEYWAIT;
	};
	/LYNXL/ && do {		# Left arrow
	  # Treat this like an UP-Menu request
	  $action="QUIT";
	  redo KEYWAIT;
	};
	/LYNXR/ && do {		# Right arrow
	  # Treat this like a RETURN
	  $action="RET";
	  redo KEYWAIT;
	};
	/DOWN/ && do {		# down arrow
	  if($menu_cur_option==$menu_index-1) {
	    # Hit the bottom
	    &menu_advice("You are on the last entry!");
	  } else {
	    do {
	      menu_draw_line($menu_cur_option,$menu_indent);
	      $menu_cur_option++;
	      if(($menu_cur_option-$menu_top_option)>$menu_pane_lines-3) {
		&scrl($menu_pane,1);
		$menu_top_option++;
	      } 
	    } until ($menu_sel_style[$menu_cur_option]!=9);
	      &menu_draw_active($menu_cur_option,$menu_indent);
	    &noutrefresh($menu_pane);
	    &menu_advice("");
	  }
	  &doupdate();
	  last KEYWAIT;
	};
	/UP/ && do {		# Up arrow
	  if($menu_cur_option==0) {
	    # Hit the bottom
	    &menu_advice("You are on the first entry!");
	  } else {
	    do {
	      menu_draw_line($menu_cur_option,$menu_indent);
	      $menu_cur_option--;
	      if(($menu_cur_option-$menu_top_option)<0) {
		&scrl($menu_pane,-1);
		$menu_top_option--;
	      }
	      redo if ($menu_sel_style[$menu_cur_option]==9);
	      &menu_draw_active($menu_cur_option,$menu_indent);
	    };
	    &noutrefresh($menu_pane);
	    &menu_advice("");
	  }
	  &doupdate();
	  last KEYWAIT;
	};
	# larger cursor motion
	/PREV/ && do {		# Page up
	  if($menu_top_option<=0) {
	    # Hit the bottom
	    menu_advice("There are no more options!");
	  } else {
	    $menu_cur_option=$menu_cur_option-($menu_pane_lines-3);
	    $menu_top_option=$menu_top_option-($menu_pane_lines-3);
	    &menu_draw_pane();
	    &menu_advice("");
	  }
	  &doupdate();
	  last KEYWAIT;
	};
	/NEXT/ && do {		# Page down
	  if($menu_top_option>($menu_index-1-($menu_pane_lines-2))) {
	    # Hit the bottom
	    menu_advice("There are no more options!");
	  } else {
	    $menu_cur_option=$menu_cur_option+($menu_pane_lines-3);
	    $menu_top_option=$menu_top_option+($menu_pane_lines-3);
	    &menu_draw_pane();
	    &menu_advice("");
	  }
	  &doupdate();
	  last KEYWAIT;
	};
	/HOME/ && do {		# Home
	  if($menu_top_option==0) {
	    # Check if the top item is already on the screen
	    if($menu_cur_option==0) {
	      # Already at the top
	      &menu_advice("You are already at the top");
	    } else {
	      menu_draw_line($menu_cur_option,$menu_indent);
	      $menu_cur_option=0;
	      &menu_draw_active($menu_cur_option,$menu_indent);
	      &noutrefresh($menu_pane);
	      &menu_advice("");
	    }
	  } else {
	    $menu_top_option=0;
	    $menu_cur_option=0;
	    &menu_draw_pane();
	    &menu_advice("");
	  }
	  &doupdate();
	  last KEYWAIT;
	};
	/END/ && do {		# End
	  if($menu_cur_option==$menu_index-1) {
	    &menu_advice("You are already on the last option!");
	  } else {
	    if($menu_top_option+$menu_pane_lines-3>$menu_index-1) {
	      # the final option is already on screen
	      menu_draw_line($menu_cur_option,$menu_indent);
	      $menu_cur_option=$menu_index-1;
	      &menu_draw_active($menu_cur_option,$menu_indent);
	      &noutrefresh($menu_pane);
	      &menu_advice("");
	    } else {
	      # Need to paint a new screen
	      $menu_top_option=$menu_index-1;
	      $menu_cur_option=$menu_index-1;
	      menu_draw_pane();
	      &menu_advice("");
	    }
	  }
	  &doupdate();
	  last KEYWAIT;
	};
	/RET/ && do {		# button press
	  $action=$menu_button_action[$menu_hot_button];
	  redo KEYWAIT;
	};
	# immediate actions
	/SPACE/ && do {		# Return (enter)
	  $action="STOP";
	  # Togle radio buttons
	  $style=$menu_sel_style[$menu_cur_option];
	DO_STYLE: for ($style) {
	    /2/ && do {
	      for($i=0;$i<$menu_index;$i++) {
		if($menu_sel_style[$i]==2) {
		  $menu_sel_flag[$i]=0;
		}
	      }
	      $menu_sel_flag[$menu_cur_option]=1;
	      &menu_draw_pane();
	      $action="NOP";
	      &doupdate();
	      last DO_STYLE;
	    };
	    /3/ && do {
	      if($menu_sel_flag[$menu_cur_option]==1) {
		$menu_sel_flag[$menu_cur_option]=0;
	      } else {
		$menu_sel_flag[$menu_cur_option]=1;
	      }
	      &menu_draw_active($menu_cur_option,$menu_indent);
	      $action="NOP";
	      &doupdate();
	      last DO_STYLE;
	    };
	    /9/ && do {
	      # Failsafe: should not really get here
	      $action="NOP";
	      redo KEYWAIT;
	    };
	    $menu_sel_flag[$menu_cur_option]=1;
	    last DO_STYLE;
	  };
	  last KEYWAIT;
	};
	/ACCEPT/ && do {		# Return (enter)
	  $action="STOP";
	  if($menu_sel_style[$menu_cur_option]!=3) {
	    if($menu_sel_style[$menu_cur_option]==6) {
	      # edit an alpha field
	      &menu_edit($menu_cur_option,$menu_indent);
	      $action="NOP";
	      &menu_draw_active($menu_cur_option,$menu_indent);
	    }
	    if($menu_sel_style[$menu_cur_option]==7) {
	      # edit a numeric field
	      &menu_edit($menu_cur_option,$menu_indent,1);
	      $action="NOP";
	      &menu_draw_active($menu_cur_option,$menu_indent);
	    }
	  }
	  last KEYWAIT;
	};
	/JUMP/ && do {		# Jump to some option
	  menu_advice("$action not defined yet");
	  &doupdate();
	  last KEYWAIT;
	};
	/QUIT/ && do {		# Return (enter)
	  $ret="%UP%".$menu_sep;
	  $action="STOP";
	  last KEYWAIT;
	};
	/EXIT/ && do {		# Return (enter)
	  $ret="%EMPTY%".$menu_sep;
	  $action="STOP";
	  last KEYWAIT;
	};
	/HELP/ && do {		# Return (enter)
	  if(-e $menu_help_root.$menu_help) {
	    $help="";
	    open(IN,"<".$menu_help_root.$menu_help);
	    while(<IN>) {
	      $help=$help.$_;
	    }
	    close(IN);
	    &menu_show("Help File ".$menu_help_root.$menu_help,$help,"HELP");
	    # these get switched off by menu_show so do this
	    cbreak();               # permits keystroke examination
	    noecho();               # no input echo until enabled explicitly
	    curs_set(0);            # turn the cursor off
	    &menu_refresh();
	  } else {
	    beep();
	    &menu_advice("Help file ".$menu_help_root.$menu_help." not found");
	    &doupdate;
	  }
	  $action="NOP";
	  last KEYWAIT;
	};
	/REFS/ && do {		# Refresh screen
	  &menu_noutrefresh();
	  &menu_advice("Refreshed Screen");
	  &doupdate();
	  last KEYWAIT;
	};
	# button navigation
	/TAB/ && do {		# Next field
	  &menu_button_bar("TAB");
	  &doupdate();
	  last KEYWAIT;
	};
	/BACK/ && do {		# Previous field
	  &menu_button_bar("BACK");
	  &doupdate();
	  last KEYWAIT;
	};
	# Text editing - not relevant here
	/DEL/ && do {		# Delete right
	  menu_advice("$action not defined yet");
	  &doupdate();
	  last KEYWAIT;
	};
	/KILL/ && do {		# Kill line
	  menu_advice("$action not defined yet");
	  &doupdate();
	  last KEYWAIT;
	};
	/YANK/ && do {		# Yank buffer
	  menu_advice("$action not defined yet");
	  &doupdate();
	  last KEYWAIT;
	};
	/BUFF/ && do {		# Kill buffer
	  menu_advice("$action not defined yet");
	  &doupdate();
	  last KEYWAIT;
	};
	/INS/ && do {		# insert toggle
	  menu_advice("$action not defined yet");
	  &doupdate();
	  last KEYWAIT;
	};
	/BS/ && do {		# Backspace
	  menu_advice("$action not defined yet");
	  &doupdate();
	  last KEYWAIT;
	};
	/NOP/ && do {		# Jump to some option
	  #	menu_advice("doing nothing");
	  last KEYWAIT;
	};
	# default: assume a JUMP to a menu option
	# pressing a letter tries to jump to an entry beginning with that
	# letter; really only works for menu styles 0,8 or data fields
	$i=$menu_cur_option+1;
	$new_option=-1;
      CHECK_OPTION: {
	  # Scan next few items for a match
	  $j=ord(uc($action));
	  while($i<$menu_index) {
	    if(ord(uc($menu_sel_label[$i])) == $j) {
	      $new_option=$i;
	      last CHECK_OPTION;
	    }
	    $i++;
	  }
	  # Scan earlier items for a match
	  $i=0;
	  while($i<$menu_cur_option) {
	    if(ord(uc($menu_sel_label[$i])) == $j) {
	      $new_option=$i;
	      last CHECK_OPTION;
	    }
	    $i++;
	  }
	}; # end of option check
	if($new_option>=0) {
	  $menu_cur_option=$new_option;
	  $menu_top_option=$menu_cur_option;
	  &menu_draw_pane();
	  &doupdate();
	}
      };
    } until ($action eq "STOP");

    # We have made our selection so dump the menu windows
    &delwin($menu_pane);
  }
  # curses cookery
  nocbreak();               # permits keystroke examination
  echo();               # no input echo until enabled explicitly
  curs_set(1);            # turn the cursor on
  delwin($menu_window);

  $ret;

}
 
#**********
#  MENU_DRAW_INLAY
#
#  Function:	Draws a menu inlaid box to contain menu options
#		Overlays standard backdrop
#
#  Call format:	&menu_draw_inlay();
#
#  Arguments:   None
#
#  Returns:     Undetermined
#
#**********
sub menu_draw_inlay {

  my @words = ();
  my ($count,$line,$i);

# Draw relief boxes in window
  erase($menu_inlay);
  attrset($menu_inlay,$menu_attributes{"edge"});
  addch($menu_inlay,0,0, ACS_ULCORNER);
  hline($menu_inlay,ACS_HLINE, $menu_inlay_cols);

  move($menu_inlay,1,0);
  vline($menu_inlay,ACS_VLINE, $menu_inlay_lines-2);
  addch($menu_inlay,$menu_inlay_lines-1,0, ACS_LLCORNER);
  addch($menu_inlay,$menu_inlay_lines-3,0,ACS_LTEE);
  hline($menu_inlay,ACS_HLINE,$menu_inlay_cols-2);

  attrset($menu_inlay,$menu_attributes{"dull"});
  move($menu_inlay,$menu_inlay_lines-1,1);
  hline($menu_inlay,ACS_HLINE, $menu_inlay_cols-2);
  addch($menu_inlay, $menu_inlay_lines-1,$menu_inlay_cols-1,ACS_LRCORNER);

  addch($menu_inlay,0, $menu_inlay_cols-1, ACS_URCORNER);
  move($menu_inlay,1,$menu_inlay_cols-1);
  vline($menu_inlay,ACS_VLINE, $menu_inlay_lines-2);
  addch($menu_inlay,$menu_inlay_lines-3,$menu_inlay_cols-1,ACS_RTEE);

  # Draw the Menu title
  attrset($menu_inlay,$menu_attributes{"title"});
  move($menu_inlay,0,($menu_inlay_cols-length($menu_top_title)-2)/2);
  addstr($menu_inlay," $menu_top_title ");

  # Process any sub-titles like the title.
  attrset($menu_inlay,$menu_attributes{"dull"});
  if(length($menu_sub_title)>$menu_inlay_cols-4) {
    # Do multi-line subtitle
    @words=split(/ /,$menu_sub_title);
    $menu_sub_title_lines=1;
    $line=$words[0];
    for($i=1;$i<=$#words;$i++) {
      if(length($line." ".$words[$i])<$menu_inlay_cols-4) {
	$line=$line." ".$words[$i];
      } else {
	move($menu_inlay,$menu_sub_title_lines,2);
	addstr($menu_inlay,$line);
	$line=$words[$i];
	$menu_sub_title_lines++;
      }
    }
    move($menu_inlay,$menu_sub_title_lines,2);
    addstr($menu_inlay,$line);
    $line=$words[$i];
  } else {
    # Centre single line subtitle
    move($menu_inlay,1,1+($menu_inlay_cols-length($menu_sub_title)-2)/2);
    addstr($menu_inlay,"$menu_sub_title");
    $menu_sub_title_lines=1;
  }
}


#**********
#  MENU_DRAW_WINDOW
#
#  Function:	Draws a box to actually contain the menu items
#		Overlays standard inlay
#
#  Call format:	&menu_draw_window();
#
#  Arguments:   None
#
#  Returns:     undetermined
#
#**********
sub menu_draw_window {
  my $count;

  # First define window and draw border
  $menu_pane_y=$menu_inlay_y+1+$menu_sub_title_lines;
  $menu_pane_x=$menu_inlay_x+2;
  if($menu_hack25) {
	$menu_pane_lines=$menu_inlay_lines-3-$menu_sub_title_lines;
  } else {
	$menu_pane_lines=$menu_inlay_lines-4-$menu_sub_title_lines;
  }
  $menu_pane_cols=$menu_inlay_cols-4;
  $menu_pane_scroll=($menu_pane_cols/2)-2;

  $menu_window=newwin($menu_pane_lines,$menu_pane_cols,$menu_pane_y,$menu_pane_x);
  bkgd($menu_window,$menu_attributes{"text"});
  erase($menu_window);

  # Draw relief boxes in window
  attrset($menu_window,$menu_attributes{"dull"});
  addch($menu_window,0,0, ACS_ULCORNER);
  hline($menu_window,ACS_HLINE, $menu_pane_cols-2);

  move($menu_window,1,0);
  vline($menu_window,ACS_VLINE, $menu_pane_lines-2);
  addch($menu_window,$menu_pane_lines-1,0, ACS_LLCORNER);

  attrset($menu_window,$menu_attributes{"edge"});
  move($menu_window,$menu_pane_lines-1,1);
  hline($menu_window,ACS_HLINE, $menu_pane_cols-2);
  addch($menu_window, $menu_pane_lines-1,$menu_pane_cols-1,ACS_LRCORNER);

  addch($menu_window,0, $menu_pane_cols-1, ACS_URCORNER);
  move($menu_window,1,$menu_pane_cols-1);
  vline($menu_window,ACS_VLINE, $menu_pane_lines-2);

 }

#**********
#  MENU_DISPLAY
#
#  Function:	Display items in menu_sel_text array, allow selection, and
#		return appropriate selection-string.
#
#  Call format:	$sel = &menu_display("Prompt text",offset);
#
#  Arguments:   - Prompt text (for the bottom line of menu).
#		- start position of item pointer; must be tracked by user
#
#  Returns:     Selected action string (from second param on &menu_item)
#		%UP%    -- quit selected
#               %EMPTY% -- exit selected
#               otherwise gives current item (sometimes followed by
#               tokenised string; always terminated with $menu_sep
#               chop($sel) before use
#               For simple menus just returns selection value
#
#**********
sub menu_display {
  my ($menu_prompt,$menu_start_item) = @_;
  if(!$menu_start_item) {$menu_start_item=0; }

  my ($ret,$i);

  # Diverting to menu_navigate
  $menu_advice=$menu_prompt;             # set default message for this menu
  &menu_advice($menu_prompt);            # show advice
  $menu_top_option=0;
  $menu_cur_option=$menu_start_item;
  $ret=&menu_navigate();

  # Scans through the menu item list looking for items which have been
  # selected (test $menu_sel_flag) This will not work for style 8 items
  # since this field holds the offset value so for these item types
  # only return the current item if it coincides
  #
  # The full returned string may be prefixed with %UP%$menu_sep or %EMPTY%$menu_sep
  # followed by the text_labels of all items selected
  # break this out using split with pattern $Cmenu::menu_sep
  # For data fields, they will all be returned in order of definition
  # whether edited or not
  for($i=0;$i<$menu_index;$i++) {
    if($menu_sel_flag[$i]>0) {
      if(($menu_sel_style[$i]==7)||($menu_sel_style[$i]==6)) {
	$ret=$ret.$menu_sel_return[$i].$menu_sepn.$menu_sel_text[$i].$menu_sep;
      } else {
	$ret=$ret.$menu_sel_return[$i].$menu_sep;
      }
    }
  }
  $ret;
}

#**********
#  MENU_DRAW_LINE
#
#  Function:	Draws a menu item line in appropriate style
#
#  Call format:	$menu_draw_line(menu_item,indent)
#
#  Arguments:   - Menu item : pointer to menu item list
#               - indent from left edge of window (for centreing)
#
#  Returns:     nuffink
#
#**********
sub menu_draw_line {
  my ($m_item,$m_indent)=@_;
  my $i=0;
  my ($numtext);

  # Determine line number
  $i=$m_item-$menu_top_option;

 MENU_STYLE: for ($menu_sel_style[$m_item]) {
    /0/ && do {
      # default - text item
      # Display option text
      move($menu_pane,$i,$m_indent);
      attrset($menu_pane,$menu_attributes{"title"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      # Highlight first letter
      move($menu_pane,$i,$m_indent);
      attrset($menu_pane,$menu_attributes{"option"});
      addch($menu_pane,ord(ucfirst($menu_sel_label[$m_item])));
      last MENU_STYLE;
    };

    /1/ && do {
      # numbered style
      move($menu_pane,$i,$m_indent);
      attrset($menu_pane,$menu_attributes{"title"});
      $numtext=$m_item+1;
      if(length($numtext)==1) 
	{ $numtext=" ".$numtext; }
      addstr($menu_pane,$numtext);
      last MENU_STYLE;
    };

    /2/ && do {
      # radio button
      move($menu_pane,$i,$m_indent+$menu_item_pos-4);
      attrset($menu_pane,$menu_attributes{"option"});
      addch($menu_pane,"[");
      if($menu_sel_flag[$m_item]>0) {
	attrset($menu_pane,$menu_attributes{"title"});
	addch($menu_pane,"X");
	attrset($menu_pane,$menu_attributes{"option"});
      } else {
	addch($menu_pane," ");
      }
      addch($menu_pane,"]");
      last MENU_STYLE;
    };

    /3/ && do {
      # check list
      move($menu_pane,$i,$m_indent+$menu_item_pos-4);
      attrset($menu_pane,$menu_attributes{"option"});
      addch($menu_pane,"(");
      if($menu_sel_flag[$m_item]>0) {
	attrset($menu_pane,$menu_attributes{"title"});
	addch($menu_pane,"+");
	attrset($menu_pane,$menu_attributes{"option"});
      } else {
	addch($menu_pane," ");
      }
      addch($menu_pane,")");
      last MENU_STYLE;
    };

    /4/ && do {
      # left align data
      # Display option text
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"option"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };

    /5/ && do {
      # right align data
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"option"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };

    /6/ && do {
      # edit alpha
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"option"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };

    /7/ && do {
      # edit numeric
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"option"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };

    /8/ && do {
      # a type 0 item but with return data coming from fourth refernce
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"option"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };

    /9/ && do {
      # seperator
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"option"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };
  }

  if($menu_sel_style[$m_item]==5) {
    # Display item text right aligned
    move($menu_pane,$i,$m_indent+$menu_item_pos+$max_item_len-length($menu_sel_text[$m_item]));
    attrset($menu_pane,$menu_attributes{"text"});
    addstr($menu_pane,$menu_sel_text[$m_item]);
  } else {
    # Display item text left aligned (normal)
    move($menu_pane,$i,$m_indent+$menu_item_pos);
    attrset($menu_pane,$menu_attributes{"text"});
    addstr($menu_pane,$menu_sel_text[$m_item]);
  }
}

#**********
#  MENU_DRAW_ACTIVE
#
#  Function:	Draws active menu line in reverse style or with an arrow
#
#  Call format:	$sel = &menu_draw_active(menu_item,indent);
#
#  Arguments:   - the entry in the menu item list
#               - how far to indent from the left edge of window
#
#  Returns:     nothing
#
#**********
sub menu_draw_active {
  my ($m_item,$m_indent)=@_;
  my ($i,$numtext);
 
  # Calculate line number
  $i=$menu_cur_option-$menu_top_option;


 MENU_STYLE: for ($menu_sel_style[$menu_cur_option]) {
    /0/ && do {
      # default - text item
      # Display option text
      move($menu_pane,$i,$m_indent);
      attrset($menu_pane,$menu_attributes{"rtitle"});
      addstr($menu_pane,$menu_sel_label[$menu_cur_option]);
      # Highlight first letter
      move($menu_pane,$i,$m_indent);
      attrset($menu_pane,$menu_attributes{"roption"});
      addch($menu_pane,ord(ucfirst($menu_sel_label[$m_item])));
      last MENU_STYLE;
    };

    /1/ && do {
      # numbered style
      move($menu_pane,$i,$m_indent);
      attrset($menu_pane,$menu_attributes{"rtitle"});
      $numtext=$m_item+1;
      if(length($numtext)==1) 
	{ $numtext=" ".$numtext; }
      addstr($menu_pane,$numtext);
      last MENU_STYLE;
    };

    /2/ && do {
      # radio button
      move($menu_pane,$i,$m_indent+$menu_item_pos-4);
      attrset($menu_pane,$menu_attributes{"rtitle"});
      if($menu_sel_flag[$m_item]>0) {
	$numtext="[X]";
      } else {
	$numtext="[ ]";
      }
      addstr($menu_pane,$numtext);
      last MENU_STYLE;
    };

    /3/ && do {
      # check list
      move($menu_pane,$i,$m_indent+$menu_item_pos-4);
      attrset($menu_pane,$menu_attributes{"roption"});
      addch($menu_pane,"(");
      if($menu_sel_flag[$m_item]>0) {
	attrset($menu_pane,$menu_attributes{"rtitle"});
	addch($menu_pane,"+");
	attrset($menu_pane,$menu_attributes{"roption"});
      } else {
	addch($menu_pane," ");
      }
      addch($menu_pane,")");
      last MENU_STYLE;
    };

    /4/ && do {
      # left data
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"rtitle"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };

    /5/ && do {
      # right align data
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"rtitle"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };

    /6/ && do {
      # edit alpha
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"rtitle"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };

    /7/ && do {
      # edit numeric
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"rtitle"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };

    /8/ && do {
      # 
      # Display option text
      move($menu_pane,$i,$m_indent+$menu_item_pos-1-length($menu_sel_label[$m_item]));
      attrset($menu_pane,$menu_attributes{"rtitle"});
      addstr($menu_pane,$menu_sel_label[$m_item]);
      last MENU_STYLE;
    };

    /9/ && do {
      # seperator
      last MENU_STYLE;
    };
  }
  if($menu_sel_style[$m_item]==5) {
    # Display item text right aligned
    move($menu_pane,$i,$m_indent+$menu_item_pos+$max_item_len-length($menu_sel_text[$m_item]));
    attrset($menu_pane,$menu_attributes{"rtext"});
    addstr($menu_pane,$menu_sel_text[$m_item]);
  } else {
    # Display item text
    move($menu_pane,$i,$m_indent+$menu_item_pos);
    attrset($menu_pane,$menu_attributes{"rtext"});
    addstr($menu_pane,$menu_sel_text[$menu_cur_option]);
  }
}

#**********
#  MENU_CREATE_PANE
#
#  Function:	Create a window within the menu window to display items
#
#  Call format:	&menu_create_pane();
#
#  Arguments:   none
#
#  Returns:     undetermined
#
#**********
sub menu_create_pane {
  # Initialise menu pane and control variables
  $menu_pane=newwin($menu_pane_lines-2,$menu_pane_cols-2,$menu_pane_y+1,$menu_pane_x+1);
  bkgd($menu_pane,$menu_attributes{"text"});
  clear($menu_pane);
  idlok($menu_pane,1);
  scrollok($menu_pane,1);
  $menu_top_option=0;
  keypad($menu_pane,1);
  &menu_draw_pane();
}

#*********
# MENU_DRAW_PANE
#
# Function:  Draws the actual menu especially after a keystroke
#            Usually only necessary after big relocations of the menu cursor
#
# Input:     Nothing
#
# Returns:   Nothing 
#
#*********
sub menu_draw_pane {
  my ($i); 

  # Performs test to make sure the items are aligned correctly to use as much of the
  # screen as possible
  if(($menu_top_option+($menu_pane_lines-2))>$menu_index-1) { $menu_top_option=$menu_index-1-($menu_pane_lines-3); }
  if($menu_top_option<0) {$menu_top_option=0; }
  if($menu_cur_option>$menu_index-1) { $menu_cur_option=$menu_index-1; }
  if($menu_cur_option>=($menu_top_option+($menu_pane_lines-2))) {$menu_top_option=$menu_cur_option-($menu_pane_lines-3); }
  if($menu_top_option<0) {$menu_top_option=0; }
  if($menu_cur_option<$menu_top_option) { $menu_cur_option=$menu_top_option; }
  # Now draw the menu items
  clear($menu_pane);
  $i=$menu_top_option;
  while(($i<$menu_index)&&(($i-$menu_top_option)<$menu_pane_lines-2)) {
    &menu_draw_line($i,$menu_indent);
    $i++;
  }
  &menu_draw_active($menu_cur_option,$menu_indent);
  &noutrefresh($menu_pane);
}


#**********
# MENU_KEY_SEQ -- Collect characters until a sequence we recognize (or we
#		  know it cannot possibly fit any "magic" sequences.
#
#  Call format:	$sel = &menu_key_seq();
#
#  Arguments:   none
#
#  Returns:     either a single letter or a key stroke mneumonic for an action to do
#               in some cases it will return nothing if;
#                  - an invalid/unrecognised function key was pressed
#                  - the screen was resized
#               bum values like these should be ignored
#
#**********
sub menu_key_seq {
  my ($cwin) = @_;
  my ($possible,$ch);
  my ($collect,$action) = "";
  my ($resizing)=0;

  $possible = 0;	# Set number of possible matches 

  # Trapping resizing strings waiting for them to stop
 resize_trap:
  do {
    $collect="";
    $action="";
  seq_seek:
    while ($possible <$key_max) {
      $ch = &getch($cwin);
      $collect = $collect.$ch;
      # search for a valid keysequence first
      $action=$kseq{$collect};
      if($action) {
	last seq_seek;
      }
      # Check if just a single letter/number has been pressed
      # This indicates a menu option to jump to
      if(length($collect)==1) {
	# Did we press a SPACE?
	if(ord($collect)==32) {
	  $action="SPACE";
	  last seq_seek;
	}
	$_=$collect;
	if(/\w|\W/i) {
	  $action=$collect;
	  last seq_seek;
	}
      }
      $possible=length($collect);
    }

    # Catch window resizing and loop until resizing appears finished
    # then redraw the whole screen.
    if(($action eq "410")) {
      $resizing=1;
    } else {
      if($resizing==1) {
	#Resizing has occurred but hopefully stopped so change the screen
	&menu_refresh();
	$resizing=0;
      }

    }
  }   while($resizing==1); # end of resize trap

  if((length($collect)>1)&&($action eq '')) {
    &menu_advice("Command $collect not recognised");
    $action="NOP";
  }
  $action;
}

#**********
#  MENU_REFRESH
#
#  Function:	Redraws the whole display usually after a screen resize
#
#  Call format:	&menu_refresh();
#
#  Arguments:   None
#
#  Returns:     nuffink
#
#**********
sub menu_refresh {
  &menu_redraw_backdrop();
  &noutrefresh($menu_screen);
  &menu_draw_inlay();
  &redrawwin($menu_inlay);
  &menu_button_bar();
  &noutrefresh($menu_inlay);
  &delwin($menu_window);
  &menu_draw_window();
  &noutrefresh($menu_window);
  &delwin($menu_pane);
  &menu_create_pane();
  &doupdate();
}

# ##################################################################################
# Data entry routines
# ##################################################################################

#**********
#  MENU_EDIT_ALPHA
#
#  Function:	Edit an alphanumeric field
#
#  Call format:	&menu_edit_alpha();
#               assumes the current item
#
#  Returns:     nuffink
#
#**********
sub menu_edit {
  my ($m_item,$m_indent,$numbers) = @_;
  my ($item_line,$item_col,$item_len,$pos,$dec,$field,$ins,$menu_field,$action,$i);

  $item_line=$menu_pane_y+1+$m_item-$menu_top_option;
  $item_col=$menu_pane_x+1+$m_indent+$menu_item_pos;
  # Get the field information
  ($item_len,$dec) = split(/ /,$menu_sel_pos[$m_item]);

  if($item_len<1) {$item_len=length($menu_sel_text[$m_item]); }
  if(!$item_line) {$item_line=0; }
  if(!$item_col) {$item_col=0; }

  if(!$numbers) {$numbers=0; }

  # Initialise field
  $field=$menu_sel_text[$m_item];
  if(!$field) { $field=""; }         # Make sure something is defined
  $menu_field=newwin(1,$item_len,$item_line,$item_col);
  bkgd($menu_field,$menu_attributes{"advice"});

  # curses cookery
  curs_set(1);            # turn the cursor off
  $ins=1;                 # turn insert mode on
  $pos=length($field);

  # Now edit the field
  READ_KEY:  do {
      # Collect key sequences until something we recoginize 
      # (or we know we don't care)

      # Format numbers correctly
      if($numbers==1) {
	if(!$field) { $field=0; }
	if($dec==0) {
	  $field=sprintf("%d",$field);
	} else {
	  $field=sprintf("%f",$field);
	}
	if($pos>length($field)) { $pos=length($field); }
      }

      move($menu_field,0,0);
      erase($menu_field);
      addstr($menu_field,$field);
      move($menu_field,0,$pos);
      noutrefresh($menu_field);
      doupdate();

      $action = &menu_key_seq($menu_pane);

      # ------------------------------------------------------------------------------
      # Switch construct for dealing with key sequence input
      # ------------------------------------------------------------------------------
    EDITKEY: for ($action) {
	# General cursor movement
	/DOWN/ && do {		# down arrow
	  $action="ACCEPT";
	  redo EDITKEY;
	};
	/UP/ && do {		# Up arrow
	  $action="ACCEPT";
	  redo EDITKEY;
	};
	/LYNXL/ && do {		# Left arrow
	  $action="LEFT";
	};
	/LYNXR/ && do {		# Right arrow
	  $action="RITE";
	};
	/LEFT/ && do {		# Left arrow
	  $pos--;
	  if($pos<0) {$pos=0; }
	  last EDITKEY;
	};
	/RITE/ && do {		# Right arrow
	  $pos++;
	  if($pos>length($field)) {$pos=length($field); }
	  last EDITKEY;
	};
	# larger cursor motion
	/PREV/ && do {		# Page up
	  $action="ACCEPT";
	  redo EDITKEY;
	};
	/NEXT/ && do {		# Page down
	  $action="ACCEPT";
	  redo EDITKEY;
	};
	/HOME/ && do {		# Home
	  $pos=0;
	  last EDITKEY;
	};
	/END/ && do {		# End
	  $pos=length($field);
	  last EDITKEY;
	};
	/SPACE/ && do {		# button press
	  $action=" ";
	  redo EDITKEY;
	};
	/RET/ && do {		# button press
	  $action="ACCEPT";
	  redo EDITKEY;
	};
	/ACCEPT/ && do {		# Return (enter)
	  $action="STOP";
	  $menu_sel_text[$m_item]=$field;
	  $menu_sel_flag[$m_item]=1;
	  last EDITKEY;
	};
	/QUIT/ && do {		# Return (enter)
	  $action="STOP";
	  last EDITKEY;
	};
	/EXIT/ && do {		# Return (enter)
	  $action="STOP";
	  last EDITKEY;
	};
	/HELP/ && do {		# Return (enter)
	  menu_advice("$action not defined yet");
	  last EDITKEY;
	};
	/REFS/ && do {		# Refresh screen
	  &menu_advice("Refreshed Screen");
	  last EDITKEY;
	};
	# button navigation
	/TAB/ && do {		# Next field
	  $action="ACCEPT";
	  redo EDITKEY;
	};
	/BACK/ && do {		# Previous field
	  $action="ACCEPT";
	  redo EDITKEY;
	};
	/BS/ && do {		# Home
	  if($pos!=0) {
	    $field=substr($field,0,$pos-1).substr($field,$pos);
	    $pos--;
	    if($pos==0) {$pos=0; }
	  }
	  last EDITKEY;
	};
	/DEL/ && do {		# Delete right
	  if($pos<length($field)) {
	    $field=substr($field,0,$pos).substr($field,$pos+1);
	    if($pos>length($field)) {$pos=length($field); }
	  }
	  last EDITKEY;
	};
	/KILL/ && do {		# Kill line
	  $field="";
	  $pos=0;
	  &menu_advice("Field cleared");
	  last EDITKEY;
	};
	/YANK/ && do {		# Yank buffer
	  $field=$buffer;
	  $pos=length($field);
	  &menu_advice("Field recalled from buffer");
	  last EDITKEY;
	};
	/BUFF/ && do {		# Copy to buffer
	  $buffer=$field;
	  &menu_advice("Field copied to buffer");
	  last EDITKEY;
	};
	/INS/ && do {		# insert toggle
	  if($ins==1) {
	    &menu_advice("Overwrite mode On");
	    $ins=0;
	  } else {
	    $ins=1;
	    &menu_advice("Insert mode On");
	  }
	  last EDITKEY;
	};
	/NOP/ && do {		# Jump to some option
	  last EDITKEY;
	};
	# deal with a letter press or unknown key
	if(length($action)==1) {
	  if(($numbers==1) && (index("0123456789+-.",$action)<0)) {
	    # check for numeric only input
	    beep();
	    last EDITKEY;
	  }
	  study($field);
	  if($ins==1) {
	    # insert a character
	    if(length($field)>=$item_len) {
	      # ignore if field already full
	      beep();
	      last EDITKEY;
	    }
	    $i=substr($field,0,$pos).$action.substr($field,$pos);
	    $pos++;
	    if($pos>=$item_len) {$pos--; }
	  } else {
	    # replace text (overwrite)
	    $i=substr($field,0,$pos).$action.substr($field,$pos+1);
	    if($pos==length($field)) {$pos++; }
	    if($pos>=$item_len) {$pos--; }
	  }
	  $field=$i;
	}
      }; # end of option check
    } until ($action eq "STOP");

  # return screen to normal after field edit
  curs_set(0);            # turn the cursor off
  delwin($menu_field);
  move($menu_pane,$m_item-$menu_top_option,$m_indent);
  clrtoeol($menu_pane);
  &noutrefresh($menu_window);
}


# ##################################################################################
# ***************************************************************************
# Button Bar
# ~~~~~~~~~~
# A button bar can appear at the foot of each Menu. Button labels are
# user definable using the menu_button_set function
# Buttons perform
#   ACTION - select the current menu option
#   HELP   - display user provided help information
#   EXIT   - exit back from the current menu
# These functions are pre-set
# ***************************************************************************
# ##################################################################################

#**********
#  MENU_BUTTON_SET
#
#  Function:	Sets the text to be displayed in the 3 standard buttons
#
#  Call format:	&menu_button_set(button[0|1|2|3],"Button text");
#
#  Arguments:   - which button to affect 0=None 1=Okey 2=Help 3=Exit
#                 Setting of None causes messages to be shown in the
#                 button bar with the text used as default text
#               - Textual content of the button
#                 If content is empty the button will be switched off
#                 If all buttons are off mode changes as if NONE selected
#
#  Notes:       User code must keep track of what is going on, we don't
#**********
sub menu_button_set {
  my ($button,$button_text) = @_;
  my ($i);

  $menu_button[$button]=$button_text;

  # FAILSAFE: Check that some buttons are on
  $menu_buttons=0;
  for($i=1;$i<=3;$i++) {
    if(length($menu_button[$i])>0) {
      $menu_buttons++; 
    }
  }
}

#**********
#  MENU_BUTTON_BAR
#
#  Function:	Bounces the active button right or left
#
#  Call format:	&menu_button_bar(action);
#
#  Arguments:   action can be either TAB or BACK which bounces the active
#               button in the chosen direction. Bouncing wraps at both edges
#
#  Returns:     lateral thinking
#**********
sub menu_button_bar {
  my ($tab) = @_;
  my ($i,$j,$x);
  my (@b);

  # Change the active button
 ACTIVE_BUTTON: for ($tab) {
    /TAB/ && do {
      do {
	$menu_hot_button++;
	if($menu_hot_button>3) { $menu_hot_button=1; }
      } until(length($menu_button[$menu_hot_button])>0);
      last ACTIVE_BUTTON;
    };
    /BACK/ && do {
      do {
	$menu_hot_button--;
	if($menu_hot_button<1) { $menu_hot_button=3; }
      } until(length($menu_button[$menu_hot_button])>0);
      last ACTIVE_BUTTON;
    };
  };

  # Calculate position of buttons
 DO_BUTTONS: for ($menu_buttons) {
    /1/ && do {
      $b[1]=$menu_inlay_cols/2;
    };
    /2/ && do {
      $b[1]=$menu_inlay_cols/3;
      $b[2]=$menu_inlay_cols-$b[1];
    };
    /3/ && do {
      $b[1]=$menu_inlay_cols/4;
      $b[2]=$menu_inlay_cols/2;
      $b[3]=$menu_inlay_cols-$b[1];
    };
  }

  # clear the button bar and redraw it as required
  $j=1;
  for($i=1;$i<=3;$i++) {
    $x=length($menu_button[$i]);
    if($x!=0) {
      if($menu_hot_button==$i) {
	&menu_hot_button($b[$j]-1-$x/2,$menu_button[$i]);
      } else {
	&menu_draw_button($b[$j]-1-$x/2,$menu_button[$i]);
      }
      $j++;
    }
  }
  &noutrefresh($menu_inlay);
  &doupdate();
}

# Draw the active button
sub menu_hot_button {
  my ($h_indent,$text) = @_;
  my ($cap);
  
  # Pick out the capital letter
  $cap=ord(uc($text));
  &attrset($menu_inlay,$menu_attributes{"rtext"});
  &move($menu_inlay,$menu_inlay_lines-2,$h_indent);
  addstr($menu_inlay,"<");
  &attrset($menu_inlay,$menu_attributes{"rtitle"});
  addstr($menu_inlay,$text);
  &attrset($menu_inlay,$menu_attributes{"rtext"});
  addstr($menu_inlay,">");
  &attrset($menu_inlay,$menu_attributes{"roption"});
  &move($menu_inlay,$menu_inlay_lines-2,$h_indent+1);
  addch($menu_inlay,$cap);
}

# Draw an inactive button
sub menu_draw_button {
  my ($h_indent,$text) = @_;

  &attrset($menu_inlay,$menu_attributes{"button"});
  &move($menu_inlay,$menu_inlay_lines-2,$h_indent);
  addstr($menu_inlay,"<");
  addstr($menu_inlay,$text);
  addstr($menu_inlay,">");
}

# ##################################################################################
# Splash screen for Popups and Text displays
# ##################################################################################

#**********
#  MENU_POPUP
#
#  Function:	Pops up a single line text message
#               Can be used to keep users interested while a lengthy process
#               completes; popup remains on screen until destroyed by
#               calling the routine again with no message
#
#  Call format:	&menu_popup(message,title);   # create a popup
#               &menu_popup();                # destroy popup
#
#  Arguments:   - message - a text message to be displayed;
#                 should be single line only, will be truncated if too long
#                 If the message is empty an old popup will be destroyed
#               - title - title centred in the popup border
#                 defaults to "processing" if not provided
#
#  Returns:     nothing
#               
#  Notes:       popup may appear over a blank screen since the menu windows
#               may have been removed (not guaranteed)
#**********
sub menu_popup {
  my ($message,$ptitle) = @_;

  if(!$ptitle) {$ptitle="processing"; }

  &menu_advice(" ");

  if(!$message) {
    # no message so destroy the old popup
    # curses cookery
    echo();               # no input echo until enabled explicitly
    curs_set(1);            # turn the cursor on
    &delwin($menu_popup);
    &menu_redraw_backdrop();
  } else {
    # create a new popup
    noecho();               # no input echo until enabled explicitly
    curs_set(0);            # turn the cursor off
  
    while(length($message)>$menu_screen_cols-8) {
      chop $message;
    };
    # Initialise menu pane and control variables
    $menu_popup=newwin(3,$menu_screen_cols-6,($menu_screen_lines/2)-2,3);
    bkgd($menu_popup,$menu_attributes{"popup"});
    clear($menu_popup);
    &border($menu_popup,0,0,0,0,0,0,0,0);
    move($menu_popup,0,($menu_screen_cols-8-length($ptitle))/2);
    addstr($menu_popup," $ptitle ");

    move($menu_popup,1,($menu_screen_cols-6-length($message))/2);
    addstr($menu_popup,$message);

    &refresh($menu_popup);
    &doupdate();
  }
}

#**********
#  MENU_SHOW
#
#  Function:	Pops up a text message with a button bar
#               Used as a user confirmation advice before a process
#               is performed
#               Button bar defined according to current button settings
#               Help screen is called directly
#
#  Call format:	&menu_show(message);
#
#  Arguments:   - message - a text message to be displayed;
#                 can be multiline (left-just) or single (centred), choice
#                 depends on size of window
#
#  Returns:     a simple string either YES or NO
#               
#  Notes:       Uses Text::Wrap to fill the window if the text to be shown
#               is longer than a line - this allows some formatting to be 
#               performed
#                  \n   forces a line break
#               Check docs for Text::wrap for more info
#               At present only fills to current window depth and will lose
#               any additional text; no scrolling supported yet
#               
#               Useful as a debugging tool for your own scripts to see
#               what is going one since "print" will not work under
#               Curses. 
#               
#**********
sub menu_show {
  my ($temp_title,$message,$colour) = @_;
  my ($attributes,$work,$x,$i,$j);
  my ($menu_popup);
  my (@b);

  &menu_advice(" ");

  if(!$colour) { $colour="ERROR"; }
 SET_COLOR: for ($colour) {
    /WARN/ && do {
      $attributes=$menu_attributes{"warn"};
    };
    /HELP/ && do {
      $attributes=$menu_attributes{"help"};
    };
    /ERROR/ && do {
      $attributes=$menu_attributes{"error"};
    };
  };

  if(!$message) {
    # no message given so ignore the call
    return("NO");
  } else {
    # create a popup with button bar
    bkgd($menu_inlay,$attributes);
    erase($menu_inlay);
    &border($menu_inlay,0,0,0,0,0,0,0,0);
    move($menu_inlay,0,($menu_inlay_cols-length($temp_title)-2)/2);
    addstr($menu_inlay," $temp_title ");

    &noutrefresh($menu_inlay);
    # Initialise menu pane and control variables
    # First define window and draw border
    $menu_pane_y=$menu_inlay_y+1;
    $menu_pane_x=$menu_inlay_x+1;
    $menu_pane_lines=$menu_inlay_lines-3;
    $menu_pane_cols=$menu_inlay_cols-2;
    
    &noutrefresh($menu_inlay);

    $menu_popup=newwin($menu_pane_lines-2,$menu_pane_cols-2,$menu_pane_y,$menu_pane_x+1);
    bkgd($menu_popup,$attributes);
    erase($menu_popup);

    # curses cookery
    cbreak();               # permits keystroke examination
    noecho();               # no input echo until enabled explicitly
    curs_set(0);            # turn the cursor off
  
    if(length($message)<$menu_pane_cols) {
      move($menu_popup,$menu_pane_lines/2,($menu_pane_cols-length($message))/2);
      addstr($menu_popup,$message);
      &refresh($menu_popup);
    } else {
      $Text::Wrap::columns=$menu_pane_cols-2;
      addstr($menu_popup,wrap("","",$message));
      &refresh($menu_popup);
    }
    if($colour eq "HELP") {
      # We have to do this since HELP can be called while in a menu
      # when menu_show would otherwise trash the button labels
      move($menu_inlay,$menu_inlay_lines-2,($menu_inlay_cols/2)-7);
      &attrset($menu_inlay,$attributes|A_BOLD);
      addstr($menu_inlay,"<Press any Key>");
      &refresh($menu_inlay);
      getch($menu_inlay);
    } else {
      do {
	# Calculate position of buttons
      DO_BUTTONS: for ($menu_buttons) {
	  /1/ && do {
	    $b[1]=$menu_inlay_cols/2;
	  };
	  /2/ && do {
	    $b[1]=$menu_inlay_cols/3;
	    $b[2]=$menu_inlay_cols-$b[1];
	  };
	  /3/ && do {
	    $b[1]=$menu_inlay_cols/4;
	    $b[2]=$menu_inlay_cols/2;
	    $b[3]=$menu_inlay_cols-$b[1];
	  };
	}
	# Draw buttons
	$j=1;
	for($i=1;$i<=3;$i++) {
	  $x=length($menu_button[$i]);
	  if($x>0) {
	    # Draw Okay button
	    if($menu_hot_button==$i) {
	      # Make it hot
	      move($menu_inlay,$menu_inlay_lines-2,$b[$j]-($x/2)-1);
	      &attrset($menu_inlay,$attributes|A_BOLD);
	      addstr($menu_inlay,"<$menu_button[$i]>");
	    } else {
	      # make it cool
	      move($menu_inlay,$menu_inlay_lines-2,$b[$j]-($x/2)-1);
	      &attrset($menu_inlay,$attributes);
	      addstr($menu_inlay,"<$menu_button[$i]>");
	    }
	    $j++;
	  }
	}
	&refresh($menu_inlay);
	$work=&menu_key_seq($menu_inlay);
      CONFIRM: for ($work) {
	  /TAB/ && do {
	    $menu_hot_button++;
	    do {
	      $menu_hot_button++;
	      if($menu_hot_button>3) { $menu_hot_button=1; }
	    } until (length($menu_button[$menu_hot_button])>0);
	    $work="";
	    last CONFIRM;
	  };
	  /BACK/ && do {
	    do {
	      $menu_hot_button--;
	      if($menu_hot_button<1) { $menu_hot_button=$menu_buttons; }
	    } until (length($menu_button[$menu_hot_button])>0);
	    $work="";
	    last CONFIRM;
	  };
	  /RET/ && do {
	    if($menu_hot_button==1) { $work="YES"; }
	    if($menu_hot_button==2) { $work="HELP"; }
	    if($menu_hot_button==3) { $work="NO"; }
	    last CONFIRM;
	  };
	  $work="";
	};
      } until ($work ne "");
    }
    # curses cookery
    nocbreak();               # permits keystroke examination
    echo();               # no input echo until enabled explicitly
    curs_set(1);            # turn the cursor on
    &delwin($menu_popup);
    &menu_redraw_backdrop();
  }
  $work;
}


# ##################################################################################
# End of Module
# ##################################################################################

1;

__END__
# Below is the stub of documentation for the module.

=head1 NAME

Cmenu - Perl extension for menuing and data entry in perl scripts

=head1 SYNOPSIS

  use Cmenu;
  use Curses;
  use Text::Wrap;

  &menu_initialise($main_title,$advice);
  &menu_init($title,$sub-title,$topest,$menu_help);
   &menu_item($item_text,$item_label,$item_style,$item_data,$item_pos)
   &menu_item($item_text,$item_label,$item_style,$item_data,$item_pos)
    ...
   &menu_item($item_text,$item_label,$item_style,$item_data,$item_pos)

  $sel=&menu_display($advice,$start_item);

  &menu_button_set($button,$button_text);

  &menu_popup($title,$text);
   ...
  &menu_popup();

  &menu_show($title,$text,$colour);

  &menu_terminate($message);

=head1 DESCRIPTION

CMENU is a Perl Module designed to provide functions for the
creation of menus in perl scripts.

It follows on from perlmenu but uses a Curses interface for
screen manipulation. It also uses the Text::Wrap module to
process large chunks of text for display. These two modules
should be loaded by user scripts.

The sequence of menu processing is as follows;
  1. Initialise the module
    loop
      2. Define a menu structure 
      3. Define several menu options
      4. Call the menu
      5. Deal with the menu selections
    loop
  6. Terminate the module

The module also provide some extra functions.


=head2 menu_initialise

This routine initialises Curses and creates necessary structures
for the menu module. It accepts two parameters which may be empty;
  $main_title  A script-wide title displayed on all pages
  $advice      A short text advisory displayed at the foot
               of every screen (unless over-ridden by the
               module).
The routine returns nothing.

=head2 menu_init

The routine creates a graphic backdrop in the style of the 
command-line utility "dialog". It accepts 3 parameters
  $title        a menu title displayed at the top
  $sub_title    sub-title text used to give more description
  $menu_help    a help-file to be displayed when the Help key
                is pressed. The help file is located in a
                standard location as defined in the configuration
                file. (optional)

=head2 menu_item

Each line of a menu is created using this call.
  $item_text    The text to be displayed as the menu option
  $item_label   A text label which may be displayed beside
                the text
  $item_style   How the menu option should be drawn or behave
                Should be a number from 0 to 9
       0  (default) preceeds the text with a text label
          the label is returned if the item is selected
       1  use number instead of a text label; numbered in
          order of definition
       2  item is part of a radio list; radio lists allow
          only ONE item to be selected per menu
       3  item is part of a check list; check lists allow
          any number (inc. none) of items to be selected
       4  as for type 0 expect item label is rendered differently
          usually used to list data fields where the text is
          the contents of a field and the label is its meaning
       5  as for 4 except the item text is right-aligned
       6  as for 4 but if the item is selected, field contents
          can be edited
       7  as for 6 except field treated as a numeric value
       8  displayed as for 4 except an alternative reference
          (not the text label) is returned when selected
       9  spacer; leaves a space in the menu

   $item_data    Some item styles need extra information
       2  which item in a radio list is already active
       3  item in a check list already selected
       6  specifies the return value for the field
       7  as for 6
       8  as for 6

   $item pos     For edit fields only (6 + 7); specifies the
                 maximum length of a data field and decimal 
                 precision for numbers. Passed as a space
                 seperated list eg "30 2 0", length 30 with
                 2 decimal places

=head2 menu_display

Actually performs the menu display and navigation. Returns 
information relevant to the action selected. Accepts 2 parametrs;

  $menu_prompt   Displayed at the foot of the screen as advice
  $menu_start    Which item should be active from the start
                 This allows items other than the first declared
                 to be selected; useful when returning to a menu
                 after an earlier selection (optional)

This is the important call which returns the result of menu
navigation. Depending on the style of menu items defined, various results
will be returned. Generally all selections are a tokenised list seperated
by a standard character ($Cmenu::menu_sep - can be changed by user). For
simple menus, only the selected text label (0,1,4,5) or offset (8) will be
returned.

For radio and check lists (2 and 3) all the selected items will be returned
using each items text label

For edited data fields, more complex values are returned. All editable fields
on a menu will have a token (whether edited or not) returned. Each token has two
fields - the field label and the new field contents; these are seperated by
$Cmenu::menu_sepn.

Since any type of item can be included in a menu, return values may be
equally complex. For complex return values, tokens can be split out using
a command fragment such as

 chop($return_value=&menu_display("Menu Prompt",$start_on_menu_item));
 @selection=split(/$Cmenu::menu_sep/,$return_value);
 for($loop=1;$loop<=$#selection;$i++) {
   # deal with each token
   ($field_label,$field_content) = split(/$Cmenu::menu_sepn,$selection[$i]);
   # processing each field accordingly
   ...
   }

The first token returned ($selection[0]) is usually the key pressed to close the
menu was closed; this will rarely be a valid menu item - check it to make sure 
an "abort" was not requested.

=head2 menu_button_set

Each menu has up to 3 buttons which can be activated. Usually these give
options to either Accept a menu item or Abort the menu prematurely. A Help
facility may also be called.

This routine switches buttons on and off and, specifies the text label of the button
(button actions cannot be altered yielding "ACCEPT", "HELP" or "EXIT" although your 
scripts can interret these responses however you wish). The <TAB> key
traverses the buttons bar.

Parameters for this routine are;
  $button  a number 1, 2 or 3 specifying which button is to be set
  $label   the text label for the button; an empty string switches the button off

=head2 menu_popup

Allows a simple screen to pop-up if a lengthy process has been launched. The popup
has only one line of text to give an indication of what the system is doing; 
  To start a popup - call with $message
  To close a popup - call with NO message
Remember to close the popup or the menu display will get confused.

=head2 menu_show

Allows a variety of information to be shown on the screen; the display
generally replaces normal menu rendering until the user presses an approriate key.
The routines takes 3 parameters
  $title    the title of the display
  $message  the message to be displayed. If this is only one line it will be
            centred; if longer the external routine Text::wrap is used to
            manipulated the text to fit on the screen. Text formatting
            is quite primitive.
            The display cannot be scrolled if it exceeds the dimensions of
            the active window
  $colour   colour style to render the display chosen from HELP|WARN|ERROR
            HELP screens have an automatic button to continue; WARN and ERROR 
            can have multiple buttons (use menu_button_set to control these)

=head2 menu_terminate

Called as the script terminates to close down menu facilities and Curses.
The terminal should be left in a sane state. The $message parameter prints
to STDOUT as the script/routine finishes.

If a scripts aborts before calling this, the sanity of the tty will likely
get lost; use the command "reset" to restore sanity.

=head1 AUTHOR

Andy Ferguson andy@moil.demon.co.uk

=head1 FILES

cmenurc  configuration file to set terminal and screen defaults
          this file may be
             System Wide   - in /etc/Cmenu/.cmenurc
             User specific - ~/.cmenurc
             Run Specific  - ./cmenurc
          See the distributed file for contents.

vt100-wy60 A tic (terminfo) file for VT100 emulation on a Wyse 60
          terminal; this sets the functions keys appropriately

demo      A sample script showing how menus can be rendered with the module.

=head1 BUGS

* No continuation pages or checks for text displays overflowing the windows.
* Resize and Refresh functions can misbehave in spawned shells
* BACKTAB definition from Curses is lost so can only TAB forwards thru buttons

perl(1).

=cut
