#
# This is a FAKE Curses.pm
# Uses to test Curses::UI
# 2003 (c) by Marcus Thiesen
# marcus@cpan.org
# with some stolen code from the original
# Curses.pm

package Curses;

$VERSION = 1.06;

use Carp;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);

sub new      {
    my $pkg = shift;
    my ($nl, $nc, $by, $bx) = (@_,0,0,0,0);

    unless ($_initscr++) { initscr() }
    return newwin($nl, $nc, $by, $bx);
}

sub DESTROY  { }

sub printw   { addstr(sprintf shift, @_) }

$LINES = 25;
$COLS = 80;
$stdscr = $Curses;
$curscr = $Curses;
$COLORS = "";
$COLOR_PAIRS = "";

@EXPORT = qw(
    printw

    LINES $LINES COLS $COLS stdscr $stdscr curscr $curscr COLORS $COLORS
    COLOR_PAIRS $COLOR_PAIRS

    addch echochar addchstr addchnstr addstr addnstr attroff attron attrset
    standend standout attr_get attr_off attr_on attr_set chgat COLOR_PAIR
    PAIR_NUMBER beep flash bkgd bkgdset getbkgd border box hline vline
    erase clear clrtobot clrtoeol start_color init_pair init_color
    has_colors can_change_color color_content pair_content delch deleteln
    insdelln insertln getch ungetch has_key KEY_F getstr getnstr getyx
    getparyx getbegyx getmaxyx inch inchstr inchnstr initscr endwin
    isendwin newterm set_term delscreen cbreak nocbreak echo noecho
    halfdelay intrflush keypad meta nodelay notimeout raw noraw qiflush
    noqiflush timeout typeahead insch insstr insnstr instr innstr
    def_prog_mode def_shell_mode reset_prog_mode reset_shell_mode resetty
    savetty getsyx setsyx curs_set napms move clearok idlok idcok immedok
    leaveok setscrreg scrollok nl nonl overlay overwrite copywin newpad
    subpad prefresh pnoutrefresh pechochar refresh noutrefresh doupdate
    redrawwin redrawln scr_dump scr_restore scr_init scr_set scroll scrl
    slk_init slk_set slk_refresh slk_noutrefresh slk_label slk_clear
    slk_restore slk_touch slk_attron slk_attrset slk_attr slk_attroff
    slk_color baudrate erasechar has_ic has_il killchar longname termattrs
    termname touchwin touchline untouchwin touchln is_linetouched
    is_wintouched unctrl keyname filter use_env putwin getwin delay_output
    flushinp newwin delwin mvwin subwin derwin mvderwin dupwin syncup
    syncok cursyncup syncdown getmouse ungetmouse mousemask enclose
    mouse_trafo mouseinterval BUTTON_RELEASE BUTTON_PRESS BUTTON_CLICK
    BUTTON_DOUBLE_CLICK BUTTON_TRIPLE_CLICK BUTTON_RESERVED_EVENT
    use_default_colors assume_default_colors define_key keybound keyok
    resizeterm resize getmaxy getmaxx flusok getcap touchoverlap new_panel
    bottom_panel top_panel show_panel update_panels hide_panel panel_window
    replace_panel move_panel panel_hidden panel_above panel_below
    set_panel_userptr panel_userptr del_panel set_menu_fore menu_fore
    set_menu_back menu_back set_menu_grey menu_grey set_menu_pad menu_pad
    pos_menu_cursor menu_driver set_menu_format menu_format set_menu_items
    menu_items item_count set_menu_mark menu_mark new_menu free_menu
    menu_opts set_menu_opts menu_opts_on menu_opts_off set_menu_pattern
    menu_pattern post_menu unpost_menu set_menu_userptr menu_userptr
    set_menu_win menu_win set_menu_sub menu_sub scale_menu set_current_item
    current_item set_top_row top_row item_index item_name item_description
    new_item free_item set_item_opts item_opts_on item_opts_off item_opts
    item_userptr set_item_userptr set_item_value item_value item_visible
    menu_request_name menu_request_by_name set_menu_spacing menu_spacing
    pos_form_cursor data_ahead data_behind form_driver set_form_fields
    form_fields field_count move_field new_form free_form set_new_page
    new_page set_form_opts form_opts_on form_opts_off form_opts
    set_current_field current_field set_form_page form_page field_index
    post_form unpost_form set_form_userptr form_userptr set_form_win
    form_win set_form_sub form_sub scale_form set_field_fore field_fore
    set_field_back field_back set_field_pad field_pad set_field_buffer
    field_buffer set_field_status field_status set_max_field field_info
    dynamic_field_info set_field_just field_just new_field dup_field
    link_field free_field set_field_opts field_opts_on field_opts_off
    field_opts set_field_userptr field_userptr field_arg form_request_name
    form_request_by_name

    ERR OK ACS_BLOCK ACS_BOARD ACS_BTEE ACS_BULLET ACS_CKBOARD ACS_DARROW
    ACS_DEGREE ACS_DIAMOND ACS_HLINE ACS_LANTERN ACS_LARROW ACS_LLCORNER
    ACS_LRCORNER ACS_LTEE ACS_PLMINUS ACS_PLUS ACS_RARROW ACS_RTEE ACS_S1
    ACS_S9 ACS_TTEE ACS_UARROW ACS_ULCORNER ACS_URCORNER ACS_VLINE
    A_ALTCHARSET A_ATTRIBUTES A_BLINK A_BOLD A_CHARTEXT A_COLOR A_DIM
    A_INVIS A_NORMAL A_PROTECT A_REVERSE A_STANDOUT A_UNDERLINE COLOR_BLACK
    COLOR_BLUE COLOR_CYAN COLOR_GREEN COLOR_MAGENTA COLOR_RED COLOR_WHITE
    COLOR_YELLOW KEY_A1 KEY_A3 KEY_B2 KEY_BACKSPACE KEY_BEG KEY_BREAK
    KEY_BTAB KEY_C1 KEY_C3 KEY_CANCEL KEY_CATAB KEY_CLEAR KEY_CLOSE
    KEY_COMMAND KEY_COPY KEY_CREATE KEY_CTAB KEY_DC KEY_DL KEY_DOWN KEY_EIC
    KEY_END KEY_ENTER KEY_EOL KEY_EOS KEY_EXIT KEY_F0 KEY_FIND KEY_HELP
    KEY_HOME KEY_IC KEY_IL KEY_LEFT KEY_LL KEY_MARK KEY_MAX KEY_MESSAGE
    KEY_MIN KEY_MOVE KEY_NEXT KEY_NPAGE KEY_OPEN KEY_OPTIONS KEY_PPAGE
    KEY_PREVIOUS KEY_PRINT KEY_REDO KEY_REFERENCE KEY_REFRESH KEY_REPLACE
    KEY_RESET KEY_RESTART KEY_RESUME KEY_RIGHT KEY_SAVE KEY_SBEG
    KEY_SCANCEL KEY_SCOMMAND KEY_SCOPY KEY_SCREATE KEY_SDC KEY_SDL
    KEY_SELECT KEY_SEND KEY_SEOL KEY_SEXIT KEY_SF KEY_SFIND KEY_SHELP
    KEY_SHOME KEY_SIC KEY_SLEFT KEY_SMESSAGE KEY_SMOVE KEY_SNEXT
    KEY_SOPTIONS KEY_SPREVIOUS KEY_SPRINT KEY_SR KEY_SREDO KEY_SREPLACE
    KEY_SRESET KEY_SRIGHT KEY_SRSUME KEY_SSAVE KEY_SSUSPEND KEY_STAB
    KEY_SUNDO KEY_SUSPEND KEY_UNDO KEY_UP KEY_MOUSE BUTTON1_RELEASED
    BUTTON1_PRESSED BUTTON1_CLICKED BUTTON1_DOUBLE_CLICKED
    BUTTON1_TRIPLE_CLICKED BUTTON1_RESERVED_EVENT BUTTON2_RELEASED
    BUTTON2_PRESSED BUTTON2_CLICKED BUTTON2_DOUBLE_CLICKED
    BUTTON2_TRIPLE_CLICKED BUTTON2_RESERVED_EVENT BUTTON3_RELEASED
    BUTTON3_PRESSED BUTTON3_CLICKED BUTTON3_DOUBLE_CLICKED
    BUTTON3_TRIPLE_CLICKED BUTTON3_RESERVED_EVENT BUTTON4_RELEASED
    BUTTON4_PRESSED BUTTON4_CLICKED BUTTON4_DOUBLE_CLICKED
    BUTTON4_TRIPLE_CLICKED BUTTON4_RESERVED_EVENT BUTTON_CTRL BUTTON_SHIFT
    BUTTON_ALT ALL_MOUSE_EVENTS REPORT_MOUSE_POSITION NCURSES_MOUSE_VERSION
    E_OK E_SYSTEM_ERROR E_BAD_ARGUMENT E_POSTED E_CONNECTED E_BAD_STATE
    E_NO_ROOM E_NOT_POSTED E_UNKNOWN_COMMAND E_NO_MATCH E_NOT_SELECTABLE
    E_NOT_CONNECTED E_REQUEST_DENIED E_INVALID_FIELD E_CURRENT
    REQ_LEFT_ITEM REQ_RIGHT_ITEM REQ_UP_ITEM REQ_DOWN_ITEM REQ_SCR_ULINE
    REQ_SCR_DLINE REQ_SCR_DPAGE REQ_SCR_UPAGE REQ_FIRST_ITEM REQ_LAST_ITEM
    REQ_NEXT_ITEM REQ_PREV_ITEM REQ_TOGGLE_ITEM REQ_CLEAR_PATTERN
    REQ_BACK_PATTERN REQ_NEXT_MATCH REQ_PREV_MATCH MIN_MENU_COMMAND
    MAX_MENU_COMMAND O_ONEVALUE O_SHOWDESC O_ROWMAJOR O_IGNORECASE
    O_SHOWMATCH O_NONCYCLIC O_SELECTABLE REQ_NEXT_PAGE REQ_PREV_PAGE
    REQ_FIRST_PAGE REQ_LAST_PAGE REQ_NEXT_FIELD REQ_PREV_FIELD
    REQ_FIRST_FIELD REQ_LAST_FIELD REQ_SNEXT_FIELD REQ_SPREV_FIELD
    REQ_SFIRST_FIELD REQ_SLAST_FIELD REQ_LEFT_FIELD REQ_RIGHT_FIELD
    REQ_UP_FIELD REQ_DOWN_FIELD REQ_NEXT_CHAR REQ_PREV_CHAR REQ_NEXT_LINE
    REQ_PREV_LINE REQ_NEXT_WORD REQ_PREV_WORD REQ_BEG_FIELD REQ_END_FIELD
    REQ_BEG_LINE REQ_END_LINE REQ_LEFT_CHAR REQ_RIGHT_CHAR REQ_UP_CHAR
    REQ_DOWN_CHAR REQ_NEW_LINE REQ_INS_CHAR REQ_INS_LINE REQ_DEL_CHAR
    REQ_DEL_PREV REQ_DEL_LINE REQ_DEL_WORD REQ_CLR_EOL REQ_CLR_EOF
    REQ_CLR_FIELD REQ_OVL_MODE REQ_INS_MODE REQ_SCR_FLINE REQ_SCR_BLINE
    REQ_SCR_FPAGE REQ_SCR_BPAGE REQ_SCR_FHPAGE REQ_SCR_BHPAGE REQ_SCR_FCHAR
    REQ_SCR_BCHAR REQ_SCR_HFLINE REQ_SCR_HBLINE REQ_SCR_HFHALF
    REQ_SCR_HBHALF REQ_VALIDATION REQ_NEXT_CHOICE REQ_PREV_CHOICE
    MIN_FORM_COMMAND MAX_FORM_COMMAND NO_JUSTIFICATION JUSTIFY_LEFT
    JUSTIFY_CENTER JUSTIFY_RIGHT O_VISIBLE O_ACTIVE O_PUBLIC O_EDIT O_WRAP
    O_BLANK O_AUTOSKIP O_NULLOK O_PASSOK O_STATIC O_NL_OVERLOAD
    O_BS_OVERLOAD
);

sub newwin{
    return bless {}, "Curses";
}

sub derwin{
    return newwin;
}

sub getbegxy{ $_[1] = 1; $_[2] = 2; }
sub getbegyx{ $_[1] = 1; $_[2] = 2; }
sub getmaxyx{ $_[1] = 24; $_[2] = 80; }

sub getch{
# ok, I got a problem here ... mess with the internals
    my $badboy = caller();
    no strict 'refs';
    #    print STDERR "getch called for $badboy\n";
    *{$badboy . "::get_key"} = sub(;$) { 
	$foo = rand 2; #there is a deep dispute in curses UI
	               #about if get_key returns a string or
	               #a number --- so make it random :-)
        return "-1" if $foo >= 1; };
    return -1;
}

sub AUTOLOAD {
    my $N = $AUTOLOAD;
       $N =~ s/^.*:://;

    #print "Autoload: $N\n";
    # export this?
    if (grep /$N/, @EXPORT) {
	# Mouse needs an extra handler (actually, it must return
	# something other than the other
	if ($N eq "KEY_MOUSE") {
	    *{"Curses::$N"} = sub { return "no key mouse"; }; #cache++
	    return "no key mouse";
	}

	*{"Curses::$N"} = sub { return -1; }; #cache++
	return -1;
    }

    croak "Curses constant '$N' is not defined in the Curses::UI fakelib";
}


1;
