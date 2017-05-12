#!/usr/bin/perl -w
use strict;
use File::Temp qw( :POSIX );
use lib "../lib";

#   make KEY_BTAB (shift-tab) working in XTerm
#   and also at the same time enable colors
#$ENV{TERM} = "xterm-vt220" if ($ENV{TERM} eq 'xterm');

my $debug = 0;
if (@ARGV and $ARGV[0] eq '-d') {
    my $fh = tmpfile();
    open STDERR, ">&fh";
    $debug = 1;
} else {
    # We do not want STDERR to clutter our screen.
    my $fh = tmpfile();
    open STDERR, ">&fh";
}

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Curses::UI;


# Create the root object.
my $cui = new Curses::UI ( 
    -clear_on_exit => 1, 
    -debug => $debug,
);

# Demo index
my $current_demo = 1;

# Demo windows
my %w = ();

# ----------------------------------------------------------------------
# Create a menu
# ----------------------------------------------------------------------

sub select_demo($;)
{
    my $nr = shift;
    $current_demo = $nr;
    $w{$current_demo}->focus;
}

my $file_menu = [
    { -label => 'Quit program',       -value => sub {exit(0)}        },
],

my $widget_demo_menu = [
    { -label => 'Label',              -value => sub{select_demo(1)}  },
    { -label => 'Buttons',            -value => sub{select_demo(2)}  },
    { -label => 'Checkbox',           -value => sub{select_demo(3)}  },
    { -label => 'Texteditor',         -value => sub{select_demo(4)}  },
    { -label => 'Listbox',            -value => sub{select_demo(5)}  },
    { -label => 'Popupmenu',          -value => sub{select_demo(6)}  },
    { -label => 'Progressbar',        -value => sub{select_demo(7)}  },
    { -label => 'Calendar',           -value => sub{select_demo(8)}  },
];

my $dialog_demo_menu = [
    { -label => 'Basic dialog',       -value => sub{select_demo(9)}  },
    { -label => 'Error dialog',       -value => sub{select_demo(10)} },
    { -label => 'Filebrowser dialog', -value => sub{select_demo(11)} },
    { -label => 'Progress dialog',    -value => sub{select_demo(12)} },
    { -label => 'Status dialog',      -value => sub{select_demo(13)} },
    { -label => 'Calendar dialog',    -value => sub{select_demo(14)} },
    { -label => 'Question dialog',    -value => sub{select_demo(15)} },
];

my $demo_menu = [
    { -label => 'Widget demos',       -submenu => $widget_demo_menu  },
    { -label => 'Dialog demos',       -submenu => $dialog_demo_menu  },
    { -label => '------------',       -value   => sub{}              },
    { -label => 'Next demo',          -value   => \&goto_next_demo   },
    { -label => 'Previous demo',      -value   => \&goto_prev_demo   },
];

my $menu = [
    { -label => 'File',               -submenu => $file_menu         },
    { -label => 'Select demo',        -submenu => $demo_menu         },
];

$cui->add('menu', 'Menubar', -menu => $menu);

# ----------------------------------------------------------------------
# Create the explanation window
# ----------------------------------------------------------------------

my $w0 = $cui->add(
    'w0', 'Window', 
    -border        => 1, 
    -y             => -1, 
    -height        => 3,
);
$w0->add('explain', 'Label', 
  -text => "CTRL+P: previous demo  CTRL+N: next demo  "
         . "CTRL+X: menu  CTRL+Q: quit"
);

# ----------------------------------------------------------------------
# Create the demo windows
# ----------------------------------------------------------------------

my %screens = (
    '1'  => 'Label',
    '2'  => 'Buttons',
    '3'  => 'Checkbox',
    '4'  => 'Texteditor',
    '5'  => 'Listbox',
    '6'  => 'Popupmenu',
    '7'  => 'Progressbar',
    '8'  => 'Calendar',
    '9'  => 'Basic dialog',
    '10' => 'Error dialog',
    '11' => 'Filebrowser dialog',
    '12' => 'Progress dialog',
    '13' => 'Status dialog',
    '14' => 'Calendar dialog',
    '15' => 'Question dialog',
);

my @screens = sort {$a<=>$b} keys %screens;

my %args = (
    -border       => 1, 
    -titlereverse => 0, 
    -padtop       => 2, 
    -padbottom    => 3, 
    -ipad         => 1,
);

while (my ($nr, $title) = each %screens)
{
    my $id = "window_$nr";
    $w{$nr} = $cui->add(
        $id, 'Window', 
        -title => "Curses::UI demo: $title ($nr/" . @screens . ")",
        %args
    );
}

# ----------------------------------------------------------------------
# Label demo
# ----------------------------------------------------------------------

$w{1}->add(
    undef, 'Label',
    -text => "A label is a widget which can be used to display\n"
           . "a piece of text. This text can be formatted. The\n"
           . "supported formats are shown below. It depends upon\n"
           . "your terminal if all formats are shown correctly."
);

$w{1}->add(undef,'Label',-text=>"dim font",-y=>5,-dim=>1 );
$w{1}->add(undef,'Label',-text=>"bold font",-y=>7,-bold=>1 );
$w{1}->add(undef,'Label',-text=>"reversed font",-y=>9,-reverse => 1 );
$w{1}->add(undef,'Label',-text=>"underlined font",-x=>15,-y=>5,-underline=>1 );
$w{1}->add(undef,'Label',-text=>"blinking font",-x=>15,-y=>7,-blink=>1 );

# ----------------------------------------------------------------------
# Buttons demo
# ----------------------------------------------------------------------

$w{2}->add(
    undef, 'Label',
    -text => "The buttons widget displays an array of buttons.\n"
           . "As you would have guessed, these buttons can be pressed.\n"
           . "Select a button using <TAB>, the arrow keys or <H> and <L>\n"
           . "and press a button using the <SPACE> or <ENTER> key."
);

$w{2}->add(
    'buttonlabel', 'Label',
    -y => 7,
    -width => -1,
    -bold => 1,
    -text => "Press a button please...",
);

sub button_callback($;)
{
    my $this = shift;
    my $label = $this->parent->getobj('buttonlabel');
    $label->text("You pressed: " . $this->get);
}

$w{2}->add(
    undef, 'Buttonbox',
    -y => 5,    
    -buttons => [
         {
            -label => "< Button 1 >",
        -value => "the first button", 
        -onpress => \&button_callback, 
        },{
            -label => "< Button 2 >", 
        -value => "the second button", 
        -onpress => \&button_callback, 
        },{
            -label => "< Button 3 >", 
        -value => "the third button", 
        -onpress => \&button_callback, 
        },    
    ],
);

# ----------------------------------------------------------------------
# Checkbox demo
# ----------------------------------------------------------------------

$w{3}->add(
    undef, 'Label',
    -text => "The checkbox can be used for selecting a true or false\n"
           . "value. If the checkbox is checked (a 'X' is inside it)\n"
           . "the value is true. <SPACE> and <ENTER> will toggle the\n"
           . "state of the checkbox, <Y> will check it and <N> will\n"
           . "uncheck it."
);

my $cb_no = "The checkbox says: I don't like it :-(";
my $cb_yes = "The checkbox says: I do like it! :-)";

$w{3}->add(
    'checkboxlabel', 'Label',
    -y       => 8,
    -width   => -1,
    -bold    => 1,
    -text    => "Check the checkbox please...",
);

$w{3}->add(
    undef, 'Checkbox',
    -y => 6,
    -checked => 0,
    -label => 'I like this Curses::UI demo so far!',
    -onchange => sub {
        my $cb = shift;
        my $label = $cb->parent->getobj('checkboxlabel'); 
        $label->text($cb->get ? $cb_yes : $cb_no);
    },
);

# ----------------------------------------------------------------------
# Texteditor demo
# ----------------------------------------------------------------------

$w{4}->add(
    undef, 'Label',
    -text => "The texteditor can be used for entering lines or blocks\n"
           . "of text. It also can be used in read-only mode as a\n"
           . "textviewer. Below you see some of the possibilities that\n"
           . "the texteditor widget offers."
);

$w{4}->add(
    'te1', 'TextEditor',
    -title => 'not wrapping',
    -y => 5, -width => 20, -border => 1,
    -padbottom => 4,
    -vscrollbar => 1,
    -hscrollbar => 1,
    -onChange => sub {
        my $te1 = shift;
        my $te2 = $te1->parent->getobj('te2');
        my $te3 = $te1->parent->getobj('te3');
        $te2->text($te1->get);
        $te3->text($te1->get);
        $te2->pos($te1->pos);
    },
);

$w{4}->add(
    'te2', 'TextEditor',
    -title => 'wrapping',
    -y => 5, -x => 21, -width => 20, -border => 1,
    -padbottom => 4,
    -vscrollbar => 1,
    -hscrollbar => 1,
    -wrapping => 1,
    -onChange => sub {
        my $te2 = shift;
        my $te1 = $te2->parent->getobj('te1');
        my $te3 = $te2->parent->getobj('te3');
        $te1->text($te2->get);
        $te3->text($te2->get);
        $te1->pos($te2->pos);
    },
);

$w{4}->add(
    'te3', 'TextViewer',
    -y => 5, -x => 42, -width => 20, -border => 1,
    -padbottom => 4,
    -title => "Read only",
    -vscrollbar => 1,
    -hscrollbar => 1,
);

$w{4}->add(
    undef, 'Label', -y => -3,
    -text => "Single line entry:",
    -width => 20,

);
$w{4}->add(
    undef, 'TextEntry',
    -sbborder => 1,
    -y => -3,
    -x => 21,
    -width => 20,
);

$w{4}->add(
    undef, 'Label', -y => -1,
    -text => "Password entry:",
    -width => 20,

);
$w{4}->add(
    undef, 'PasswordEntry',
    -sbborder => 1,
    -y => -1,
    -x => 21,
    -width => 20,
);

# ----------------------------------------------------------------------
# Listbox demo
# ----------------------------------------------------------------------

my $values = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ];
my $labels = {
    1  => 'One',     2  => 'Two',
    3  => 'Three',   4  => 'Four',
    5  => 'Five',    6  => 'Six',
    7  => 'Seven',   8  => 'Eight',
    9  => 'Nine',    10 => 'Ten',
};

$w{5}->add(
    undef, 'Label',
    -text => "The listbox can be used for selecting on or more options\n"
	   . "out of a predefined list of options. <SPACE> and <ENTER> will\n"
	   . "change the current selected option for a normal listbox and a\n"
	   . "radiobuttonbox, They will toggle the state of the active option in\n"
	   . "a multi-select listbox. In a multi-select listbox you can also\n"
	   . "use <Y> and <N> to check or uncheck options. Press </> for a\n"
	   . "'less'-like search through the list."
);

sub listbox_callback()
{
    my $listbox = shift;
    my $label = $listbox->parent->getobj('listboxlabel');
    my @sel = $listbox->get;
    @sel = ('<none>') unless @sel;
    my $sel = "selected: " . join (", ", @sel);
    $label->text($listbox->title . " $sel");
}

$w{5}->add(
    undef, 'Listbox',
    -y          => 8,
    -padbottom  => 2,
    -values     => $values,
    -labels     => $labels,
    -width      => 20,
    -border     => 1,
    -title      => 'Listbox',
    -vscrollbar => 1,
    -onchange   => \&listbox_callback,
);

$w{5}->add(
    undef, 'Listbox',
    -y          => 8,
    -padbottom  => 2,
    -x          => 21,
    -values     => $values,
    -labels     => $labels,
    -width      => 20,
    -border     => 1,
    -multi      => 1,
    -title      => 'Multi-select',
    -vscrollbar => 1,
    -onchange   => \&listbox_callback,
);

$w{5}->add(
    undef, 'Radiobuttonbox',
    -y          => 8,
    -padbottom  => 2,
    -x          => 42,
    -values     => $values,
    -labels     => $labels,
    -width      => 20,
    -border     => 1,
    -title      => 'Radiobuttonbox',
    -vscrollbar => 1,
    -onchange   => \&listbox_callback,
);

$w{5}->add(
    'listboxlabel', 'Label',
    -y => -1,
    -bold => 1,
    -text => "Select any option in one of the listboxes please....",
    -width => -1,
);

# ----------------------------------------------------------------------
# Popupmenu
# ----------------------------------------------------------------------

$w{6}->add(
    undef, 'Label',
    -text => "The popmenu is much like a standard listbox. The difference is\n"
           . "that only the currently selected value is visible (or ---- if\n"
	   . "no value is yet selected). The list of possible values will be\n"
	   . "shown as a separate popup windows if requested.\n"
	   . "Press <ENTER> or <CURSOR-RIGHT> to open the popupbox and use\n"
	   . "those same keys to select a value (or use <CURSOR-LEFT> to close\n"
	   . "the popup listbox without selecting a value from it). Press\n"
	   . "</> in the popup for a 'less'-like search through the list."
);

$w{6}->add(
    undef, 'Popupmenu',
    -y          => 9,
    -values     => $values,
    -labels     => $labels,
    -width      => 20,
    -onchange   => sub {
        my $pm = shift;
	my $lbl = $pm->parent->getobj('popupmenulabel');
	my $val = $pm->get;
	$val = "<undef>" unless defined $val;
	my $lab = $pm->{-labels}->{$val};
	$val .= " (label = '$lab')" if defined $lab;
	$lbl->text($val);
	$lbl->draw;
    },
);

$w{6}->add(
    undef, 'Label', -y => 9, -x => 21,
    -text       => "--- selected --->"
);

$w{6}->add(
    'popupmenulabel', 'Label',
    -y => 9, -x => 39, -width => -1,
    -bold => 1,
    -text       => "none"
);

# ----------------------------------------------------------------------
# Progressbar
# ----------------------------------------------------------------------

$w{7}->add( 
    'progressbarlabel', 'Label',
    -x => -1, -y => 3, -width => 10, -border => 1,
    -text => "the time"
);

$w{7}->add(
    undef, 'Label',
    -text => "The progressbar can be used to provide some progress information\n"
           . "to the user of a program. Progressbars can be drawn in several\n"
	   . "ways (see below for a couple of examples). In this example, I\n"
	   . "just built a kind of clock (the values for the bars are \n"
	   . "depending upon the current time)."
);

$w{7}->add( undef, "Label", -y => 7, -text => "Showing value");
$w{7}->add( 'p1', 'Progressbar', -max => 24, 
            -x => 15, -y => 6,  -showvalue    => 1 );

$w{7}->add( undef, "Label", -y => 10, -text => "No centerline");
$w{7}->add( 'p2', 'Progressbar', -max => 60, 
            -x => 15, -y => 9, -nocenterline => 1 );

$w{7}->add( undef, "Label", -y => 13, -text => "No percentage");
$w{7}->add( 'p3', 'Progressbar', -max => 60, 
            -x => 15, -y => 12, -nopercentage => 1 );

sub progressbar_timer_callback($;)
{
    my $cui = shift;
    my @l = localtime;
    $w{7}->getobj('p1')->pos($l[2]);
    $w{7}->getobj('p2')->pos($l[1]);
    $w{7}->getobj('p3')->pos($l[0]);
    $w{7}->getobj('progressbarlabel')->text(
         sprintf("%02d:%02d:%02d", @l[2,1,0])
    );
}

$cui->set_timer(
    'progressbar_demo',
    \&progressbar_timer_callback, 1
);
$cui->disable_timer('progressbar_demo');

$w{7}->onFocus( sub{$cui->enable_timer  ('progressbar_demo')} );
$w{7}->onBlur(  sub{$cui->disable_timer ('progressbar_demo')} );

# ----------------------------------------------------------------------
# Calendar
# ----------------------------------------------------------------------

$w{8}->add(
    undef, 'Label',
    -text => "The calendar can be used to select a date, somewhere between\n"
           . "the years 0 and 9999. It honours the transition from the\n"
	   . "Julian- to the Gregorian calender in 1752."
);

$w{8}->add(
    undef, 'Label',
    -y => 5, -x => 27,
    -text => "Use your cursor keys (or <H>, <J>, <K> and <L>)\n"
           . "to walk through the calender. Press <ENTER>\n"
	   . "or <SPACE> to select a date. Press <SHIFT+J> to\n"
	   . "go one month forward and <SHIFT+K> to go one\n"
	   . "month backward. Press <SHIFT+L> or <N> to go one\n"
	   . "year forward and <SHIFT+H> or <P> to go one year\n"
	   . "backward. Press <T> to go to today's date. Press\n"
	   . "<C> to go to the currently selected date."
);

$w{8}->add(
    'calendarlabel', 'Label',
    -y => 14, -x => 27,
    -bold => 1,
    -width => -1,
    -text => 'Select a date please...'
);

$w{8}->add(
    'calendar', 'Calendar',
    -y => 4, -x => 0,
    -border => 1,
    -onchange => sub {
        my $cal = shift;
	my $label = $cal->parent->getobj('calendarlabel'); 
	$label->text("You selected the date: " . $cal->get);
    },
);

# ----------------------------------------------------------------------
# Dialog::Basic
# ----------------------------------------------------------------------

$w{9}->add(
    undef, 'Label',
    -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
           . "The basic dialog is one of them. It consists of a dialog\n"
	   . "showing a message and one or more buttons. Press the\n"
	   . "buttons to see some examples of this."
);


$w{9}->add(
    undef, 'Buttonbox',
    -y => 7,    
    -buttons => [
         { 
	   -label => "< Example 1 >",
	   -onpress => sub {
	       shift()->root->dialog("As basic as it gets")
	   } 
	 },{ 
	   -label => "< Example 2 >",
	   -onpress => sub {
	       shift()->root->dialog(
	           -message => "Basic, but carrying a\n"
		             . "title this time.",
                   -title   => 'Dialog::Basic demo',
	       );
	   } 
	 },{ 
	   -label => "< Example 3 >",
	   -onpress => sub {
	       my $b = shift();
	       my $value = $b->root->dialog(
	           -message => "Basic, but carrying a\n"
		             . "title and multiple buttons.",
                   -buttons => ['ok','cancel', 'yes', 'no'],
                   -title   => 'Dialog::Basic demo',
	       );
	       $b->root->dialog(
	           -message => "The value for that\n"
		             . "button was: $value",
		   -title   => "Value?"
	       );
	   } 
         }
    ],
);

# ----------------------------------------------------------------------
# Dialog::Error
# ----------------------------------------------------------------------

$w{10}->add(
    undef, 'Label',
    -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
           . "The Error dialog is one of them. It consists of a dialog\n"
	   . "showing an errormessage, an ASCII art exclamation sign\n"
	   . "and one or more buttons. Press the buttons to see some\n"
	   . "examples of this."
);

$w{10}->add(
    undef, 'Buttonbox',
    -y => 7,    
    -buttons => [
         { 
	   -label => "< Example 1 >",
	   -onpress => sub {
	       shift()->root->error("Some error occurred, I guess...")
	   } 
	 },{ 
	   -label => "< Example 2 >",
	   -onpress => sub {
	       shift()->root->error(
	           -message => "Unfortunately this program is\n"
		             . "unable to cope with the enless\n"
			     . "stream of bugs the programmer\n"
			     . "has induced!!!!",
                   -title   => 'Serious trouble',
	       );
	   } 
	 },{ 
	   -label => "< Example 3 >",
	   -onpress => sub {
	       my $b = shift();
	       my $value = $b->root->error(
	           -message => "General error somewhere in the program\n"
		             . "Are you sure you want to continue?",
                   -buttons => ['yes', 'no'],
                   -title   => 'Vague problem detected',
	       );
	       $b->root->dialog(
	           -message => "You do " . ($value?'':'not ')
		             . "want to continue.",
		   -title   => "What did you answer?"
	       );
	   } 
         }
    ],
);

# ----------------------------------------------------------------------
# Dialog::Filebrowser
# ----------------------------------------------------------------------

$w{11}->add(
    undef, 'Label',
    -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
           . "The Filebrowser dialog is one of them. Using this dialog\n"
	   . "it is possible to select a file anywhere on the file-\n"
	   . "system. Press the buttons below for a demo"
);

$w{11}->add(
    undef, 'Buttonbox',
    -y => 7,    
    -buttons => [
         { 
	   -label => "< Load file >",
	   -onpress => sub {
	      my $cui = shift()->root;
	      my $file = $cui->loadfilebrowser(
	          -title => "Select some file",
		  -mask  => [
		      ['.',      'All files (*)'      ],
                      ['\.txt$', 'Text files (*.txt)' ],
		      ['\.pm$',  'Perl modules (*.pm)'],
		  ],
              );
	      $cui->dialog("You selected the file:\n$file")
	         if defined $file;
	   }
         },{ 
	   -label => "< Save file (is fake) >",
	   -onpress => sub {
	      my $cui = shift()->root;
	      my $file = $cui->savefilebrowser("Select some file");
	      $cui->dialog("You selected the file:\n$file")
	         if defined $file;
	   }
         }
    ]
);

# ----------------------------------------------------------------------
# Dialog::Progress
# ----------------------------------------------------------------------

$w{12}->add(
    undef, 'Label',
    -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
           . "The Progress dialog is one of them. Using this dialog\n"
	   . "it is possible to present some progress information to\n"
	   . "the user. Press the buttons below for a demo."
);

$w{12}->add(
    undef, 'Buttonbox',
    -y => 7,    
    -buttons => [
         { 
	   -label => "< Example 1 >",
	   -onpress => sub {
		$cui->progress(
		    -min => 0,
		    -max => 700,
		    -title => 'Progress dialog without a message',
		    -nomessage => 1,
		);

		for my $pos (0..700) {
		    $cui->setprogress($pos);
		}
		sleep 1;
		$cui->noprogress;
	   }
         },{ 
	   -label => "< Example 2 >",
	   -onpress => sub {
	        my $msg = "Counting from 0 to 700...\n";
		$cui->progress(
		    -min => 0,
		    -max => 700,
		    -title => 'Progress dialog with a message',
		    -message => $msg,
		);

		for my $pos (0..700) {
		    $cui->setprogress($pos, $msg . $pos . " / 700");
		}
		$cui->setprogress(undef, "Finished counting!");
		sleep 1;
		$cui->noprogress;
	   }
         }
    ]
);

# ----------------------------------------------------------------------
# Dialog::Status
# ----------------------------------------------------------------------

$w{13}->add(
    undef, 'Label',
    -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
           . "The Status dialog is one of them. Using this dialog\n"
	   . "it is possible to present some status information to\n"
	   . "the user. Press the buttons below for a demo."
);

$w{13}->add(
    undef, 'Buttonbox',
    -y => 7,    
    -buttons => [
         { 
	   -label => "< Example 1 >",
	   -onpress => sub {
		$cui->status("This is a status dialog...");
		sleep 1;
		$cui->nostatus;
	   }
         },{ 
	   -label => "< Example 2 >",
	   -onpress => sub {
		$cui->status("A status dialog can contain\n"
		           . "more than one line, but that is\n"
			   . "about all that can be told about\n"
			   . "status dialogs I'm afraid :-)"
                );
		sleep 3;
		$cui->nostatus;
	   }
         }
    ]
);

# ----------------------------------------------------------------------
# Dialog::Calendar
# ----------------------------------------------------------------------

$w{14}->add(
    undef, 'Label',
    -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
           . "The calendar dialog is one of them. Using this dialog\n"
	   . "it is possible to select a date."
);

$w{14}->add( undef,  'Label', -y => 7, -text => 'Date:' );
$w{14}->add( 
    'datelabel', 'Label', 
    -width => 10, 
    -y => 7, 
    -x => 6, 
    -text => 'none',
);

$w{14}->add(
    undef, 'Buttonbox',
    -y => 7,    
    -x => 17,
    -buttons => [
         { 
	   -label => "< Set date >",
	   -onpress => sub { 
	       my $label = shift()->parent->getobj('datelabel');
	       my $date = $label->get;
	       print STDERR "$date\n";
	       $date = undef if $date eq 'none';
	       my $return = $cui->calendardialog(-date => $date);
	       $label->text($return) if defined $return;
	   }
         },{
	   -label => "< Clear date >",
	   -onpress => sub {
	       my $label = shift()->parent->getobj('datelabel');
	       $label->text('none');
	   }
	 }
    ]
);

# ----------------------------------------------------------------------
# Dialog::Question
# ----------------------------------------------------------------------

$w{15}->add(
    undef, 'Label',
    -text => "Curses::UI has a number of ready-to-use dialog windows.\n"
           . "The question dialog is one of them. Using this dialog\n"
	   . "it is possible to prompt the user to enter an answer.",
);

$w{15}->add(
    undef, 'Buttonbox',
    -y => 7,    
    -buttons => [
         { 
	   -label => "< Example 1 >",
	   -onpress => sub {
               my $button = shift;
	       my $feeling = $button->root->question("How awesome are you?");
               if ($feeling) {
                   $button->root->dialog("You answered '$feeling'");
               }
               else {
                   $button->root->dialog("Question cancelled.");
               }
	   } 
	 },{ 
	   -label => "< Example 2 >",
	   -onpress => sub {
               my $button = shift;
	       my $feeling = $button->root->question(
	           -question => "How does coffee make you feel?",
                   -title    => 'Dialog::Question example',
	       );
               if ($feeling) {
                   $button->root->dialog("You answered '$feeling'");
               }
               else {
                   $button->root->dialog("Question cancelled.");
               }
	   } 
	 },{ 
	   -label => "< Example 3 >",
	   -onpress => sub {
               my $button = shift;
	       my $feeling = $button->root->question(
	           -question => "How does coffee make you feel?",
                   -title    => 'Dialog::Question example',
                   -answer   => "Really good.",
	       );
               if ($feeling) {
                   $button->root->dialog("You answered '$feeling'");
               }
               else {
                   $button->root->dialog("Question cancelled.");
               }
	   } 
         }
    ],
);


# ----------------------------------------------------------------------
# Setup bindings and focus 
# ----------------------------------------------------------------------

# Bind <CTRL+Q> to quit.
$cui->set_binding( sub{ exit }, "\cQ" );

# Bind <CTRL+X> to menubar.
$cui->set_binding( sub{ shift()->root->focus('menu') }, "\cX" );

sub goto_next_demo()
{
    $current_demo++;
    $current_demo = @screens if $current_demo > @screens;
    $w{$current_demo}->focus;
}
$cui->set_binding( \&goto_next_demo, "\cN" );

sub goto_prev_demo()
{
    $current_demo--;
    $current_demo = 1 if $current_demo < 1;
    $w{$current_demo}->focus;
}

$cui->set_binding( \&goto_prev_demo, "\cP" );

$w{$current_demo}->focus;


# ----------------------------------------------------------------------
# Get things rolling...
# ----------------------------------------------------------------------

$cui->mainloop;

