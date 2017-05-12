package DBIx::Perform::UserInterface;

use strict;
use warnings;
use POSIX;
use Carp;
use Curses;    # to get KEY_*
use Curses::Application;
use DBIx::Perform::DButils;
use DBIx::Perform::Forms;
use DBIx::Perform::Widgets::ButtonSet;
use DBIx::Perform::SimpleList;
use DBIx::Perform::FieldList;
use DBIx::Perform::Messages;
use base 'Exporter';
use Data::Dumper;

our $VERSION = '0.695';

use constant 'KEY_DEL' => '330';

# $UserInterface methods
our @EXPORT_OK = qw(
  &new
  &parse_per_file
  &parse_xml_file
  &parse_yml_file
  &load_internal
  &run
  &capture_file_data
  &display_help_screen
  &clear_comment_and_error_display
  &display_comment
  &clear_display_comment
  &display_status
  &clear_display_status
  &display_error
  &clear_display_error
  &set_field
  &change_field_focus_on_screen
  &register_button_handler
  &button_push
  &change_buttons_to_label
  &change_label_to_buttons
  &change_modename
  &update_info_message
  &update_subform
  &set_field_display_bounds
  &set_field_bounds_on_screen
  &init_rowlists
  &get_current_rowlist
  &increment_global_rowlist
  &get_field_list
  &capture_master_detail
  &get_master_detail_table_names
  &go_to_table
  &get_number_of_tables
  &get_primary_table_name
  &get_current_table_name
  &get_table_number
  &increment_global_tablelist
  &update_table
  &update_table_number
  &update_table_name
  &get_current_form
  &get_screen_value
  &get_screen_subform_widget
  &old_set_screen_value
  &set_screen_value
  &change_mode_display
  &change_focus_to_button
  &change_focus_to_field_in_current_table
  &add_field_list_to_screens
  &redraw_subform
);

# 	LEGEND - the layout and names for the perform user interface
#
#	mode line:	mode name 	 | mode label or mode buttons
#	info line:	Info_messages | table number | table name
#	blank line
#	form area:	DBForm - multiple lines
#	comment line:	next to last from bottom of screen
#	error line:	bottom of screen

# default column values for user interface lines

our $MAXX = 80;
our $MAXY = 24;

our $MODENAME_SIZE  = 8;
our $MODENAME_START = 0;

our $MODELABEL_SIZE  = $MAXX - $MODENAME_SIZE - 3;
our $MODELABEL_START = $MODENAME_SIZE + 2;

our $MODEBUTTON_SIZE  = 3;                    # see your creartor - it's magic
our $MODEBUTTON_START = $MODENAME_SIZE + 2;

our $INFOMSG_SIZE  = 46;
our $INFOMSG_START = 0;

our $TABLENUM_SIZE  = 6;
our $TABLENUM_START = $INFOMSG_SIZE + 2;

our $TABLENAME_SIZE  = $MAXX - $INFOMSG_SIZE - $TABLENUM_SIZE - 2;
our $TABLENAME_START = $TABLENUM_START + $TABLENUM_SIZE;

our $Global_app_ref;
our %Button_handlers;

our $lang = $DBIx::Perform::Messages::languages{$ENV{LANG} || 'en_US'};
our $msgs = $DBIx::Perform::Messages::messages[$lang];
our $msgs_en = $DBIx::Perform::Messages::messages[0];
our @Button_names = @$msgs_en[3..16];
our @Button_labels = @$msgs[3..16];
our @Button_yn_names = @$msgs_en[17..18];
our @Buttons_yn = @$msgs[17..18];

our %Button_messages = (
    query  => $msgs->[19],
    add    => $msgs->[20],
    update => $msgs->[21],
    output => $msgs->[22],
);
our %Info_messages;
our %Runtime_error_messages;

our @Help_screens = @$msgs[0..1];

# When the user hits ESC from the subform, run one of the following
# based on the value of the button set.
#use vars '%MODESUBS';

our %Form = (
    TABORDER => [ 'ModeButtons', 'DBForm' ],
    TYPE     => '',              # but from DBIx::Perform::Forms
          #  There is some bug in the alt[f]base stuff in Curses::Forms.
    ALTFBASE => [ 'DBIx::Perform::Forms', 'DBIx::Perform::Widgets' ],
    ALTBASE  => [ 'DBIx::Perform::Forms', 'DBIx::Perform::Widgets' ],
    FOCUSED  => 'ModeButtons',
    WIDGETS  => {
        ModeName => {
            TYPE    => 'Label',
            COLUMNS => $MODENAME_SIZE,
            LINES   => 1,
            VALUE   => 'PERFORM: ',
            BORDER  => 0,
            X       => $MODENAME_START,
            Y       => 0,
        },
        ModeLabel => {
            TYPE    => 'Label',
            COLUMNS => $MODELABEL_SIZE,
            LINES   => 1,
            VALUE   => '',
            BORDER  => 0,
            X       => $MODELABEL_START,
            Y       => 0,
        },
        ModeButtons => {
            TYPE        => 'ButtonSet',
            LENGTH      => $MODEBUTTON_SIZE,
            PADDING     => 0,
            BORDER      => 0,
            X           => $MODEBUTTON_START,
            Y           => 0,
            FOCUSSWITCH => "\t\n",
            OnExit      => \&button_push,
            OnEntry     => \&button_push,
            LABELS      => \@Button_labels,
            NAMES       => \@Button_names,
            VALUE       => 0,
        },
        InfoMsg => {
            TYPE    => 'Label',
            COLUMNS => $INFOMSG_SIZE,
            LINES   => 1,
            VALUE   => $msgs->[23],     #'query' translated to $LANG
            BORDER  => 0,
            X       => $INFOMSG_START,
            Y       => 1,
        },
        TableNumber => {
            TYPE    => 'Label',
            COLUMNS => $TABLENUM_SIZE,
            LINES   => 1,
            VALUE   => '',
            BORDER  => 0,
            X       => $TABLENUM_START,
            Y       => 1,
        },
        TableName => {
            TYPE    => 'Label',
            COLUMNS => $TABLENAME_SIZE,
            LINES   => 1,
            VALUE   => '',
            BORDER  => 0,
            X       => $TABLENAME_START,
            Y       => 1,
        },
        Comment => {
            TYPE    => 'TextField',
            COLUMNS => $MAXX,
            LINES   => 1,
            VALUE   => '',
            BORDER  => 0,
            X       => 0,
            Y       => $MAXY - 2,
        },
        Error => {
            TYPE    => 'Label',
            COLUMNS => $MAXX,
            LINES   => 1,
            VALUE   => '',
            BORDER  => 0,

            #FOREGROUND	=> 'white',
            #BACKGROUND	=> 'black',
            X => 0,
            Y => $MAXY - 1,
        },
    },
);

our %Modesubs = (
    query  => \&DBIx::Perform::do_query,
    add    => \&DBIx::Perform::do_add,
    update => \&DBIx::Perform::do_update,
);

our %App = (
    FOREGROUND        => 'white',
    BACKGROUND        => 'black',
    MAINFORM          => { Dummy => 'DummyDef' },    # changed at runtime
    TITLEBAR          => 0,
    STATUSBAR         => 0,
    EXIT              => 0,
    form_name         => 'Run0',
    form_names        => [ 'Run0', 'Run1' ],         # set later
    form_name_indexes => { Run0 => 0 },              # also set later
    md_mode        => 'm',      # master/detail mode, "m" or "d".
    resume_command => undef,    # do the specified command after switching
                                # master/detail context or screens.
);

# UserInterface ctor
sub new {
    my $class = shift;

    {
	my $i = 23;
	foreach my $k (
    	qw( query next previous view add update remove table screen
	    current master detail output exit yes no)
  	)
	{
	    $Info_messages{$k} = @$msgs[$i];
	    $i++;
	}
	foreach my $k (
    	qw( no41. th26d th15. no47. no48. db16e er11d no16. da11r
            se09. se10. se11. no11d 1_8d  ro7d  ro7d2 ro6d  ro8d
            no14d ro10d ad21e fa39e th44s th47w ro54. so34. so35.
            th55e in61e th41. )
  	)
	{
            $Runtime_error_messages{$k} = @$msgs[$i];
	    $i++;
	}
    }

    bless my $self = {
        file_hash         => undef,    # may not need this
        app_hash          => \%App,
        app_object        => undef,
        form_hash         => \%Form,
        form_object       => undef,
        number_of_forms   => undef,
        global_field_list => undef,
        taborder          => undef,
        file_string       => undef,
        focus             => undef,    # tag we are focused on
        master_detail_list    => new DBIx::Perform::SimpleList,
        composite_join_list   => new DBIx::Perform::SimpleList,
        defined_table_names   => undef,
        attribute_table_names => undef,
        current_table_num     => 0,
        current_rowlist       => undef,                        # current rowlist
        screens               => undef,                        # array of hashes
        current_screen_index => undef,        # index of current screen in array
        rowlists             => undef,        # list of rowlists
        mode_subs            => \%Modesubs,   # bullshit
        button_handlers => \%Button_handlers,
        button_messages => \%Button_messages,
        error_messages  => \%Runtime_error_messages,
        info_messages   => \%Info_messages,
        button_labels   => \@Button_labels,
        buttons_yn      => \@Buttons_yn,
    } => ( ref $class || $class );

    return $self;
}

#		methods -----

sub parse_per_file {
    my $self     = shift;
    my $filename = shift;

    if ( !( $filename =~ /\.per$/ ) ) {
        die "Unknown file name extension on '$filename'";
    }
    open( PER_IN, "< $filename" )
      || die "Unable to open '$filename' for reading: $!";
    require "DBIx/Perform/DigestPer.pm";

    my ( $digest, $field_list ) = DBIx::Perform::DigestPer::digest( \*PER_IN );

    #die "File did not digest to a DBIx::Perform Spec: @{$digest}"
    #    unless $digest =~ /^\$form\s*=/;

    warn "In userinterface: finished digest" if $::TRACE;

    #exit;

    $self->{file_hash} = $self->load_internal( sub { eval $digest } );
    $self->{global_field_list} = $field_list;

    return $self->{file_hash};
}

sub parse_xml_file {
    my $self     = shift;
    my $filename = shift;

    if ( !( $filename =~ /\.xml$/ ) ) {
        $filename .= '.xml';

        #        die "Unknown file name extension on '$filename'";
    }
    require "DBIx/Perform/DigestPer.pm";

    my $retval = DBIx::Perform::DigestPer::digest_xml_file($filename);
    my @array  = @{$retval};

    my $digest     = $array[0]->[0];
    my $field_list = $array[0]->[1];

    die "File did not digest to a DBIx::Perform Spec"
      unless $digest =~ /\$form\s*=/;

    $self->{file_hash} = $self->load_internal( sub { eval $digest } );

    $self->{screens}             = $self->{file_hash}->{'screens'};
    $self->{defined_table_names} = $self->{file_hash}->{'tables'};

    my $fl = $self->{global_field_list} = $field_list;
    $self->{attribute_table_names} = $fl->get_attribute_table_names;
    $fl->init_displayonly_table_names;

    my $primary_table_name = $self->get_primary_table_name;

    $self->init_rowlists;

    my @taborder = $field_list->get_field_tags($primary_table_name);
    $self->{taborder} = \@taborder;

    return $self->{file_hash};
}

sub parse_yml_file {
    my $self     = shift;
    my $filename = shift;

    if ( !( $filename =~ /\.yml$/ ) ) {
        $filename .= '.yml';

        #        die "Unknown file name extension on '$filename'";
    }
    require "DBIx/Perform/DigestPer.pm";

    my $retval = DBIx::Perform::DigestPer::digest_yml_file($filename);
    my @array  = @{$retval};

    my $digest     = $array[0]->[0];
    my $field_list = $array[0]->[1];

    die "File did not digest to a DBIx::Perform Spec"
      unless $digest =~ /\$form\s*=/;

    $self->{file_hash} = $self->load_internal( sub { eval $digest } );

    $self->{screens}             = $self->{file_hash}->{'screens'};
    $self->{defined_table_names} = $self->{file_hash}->{'tables'};

    my $fl = $self->{global_field_list} = $field_list;
    $self->{attribute_table_names} = $fl->get_attribute_table_names;
    $fl->init_displayonly_table_names;

    my $primary_table_name = $self->get_primary_table_name;

    $self->init_rowlists;

    my @taborder = $field_list->get_field_tags($primary_table_name);
    $self->{taborder} = \@taborder;

    return $self->{file_hash};
}

sub load_internal {
    my $self = shift;
    my $sub  = shift;

    our $form;
    local ($form);
    &$sub();
    &$sub();

    return $form;
}

sub run {
    my $self = shift;

    my $file_hash = $self->{file_hash};
    if ( !defined($file_hash) ) {
        die "invalid \"form\" hash reference";
    }
    my %appdef = %{ $self->{app_hash} };
    if ( defined( my $minsize = $file_hash->{'screen'}{'MINSIZE'} ) ) {
        @appdef{ 'MINX', 'MINY' } = @$minsize;
    }
    $appdef{'instrs'} = $file_hash->{'instrs'};
    my $instrs = $appdef{'instrs'};

    # capture master and detail table names from instructions
    my $masters = $instrs && $$instrs{'MASTERS'};
    $self->capture_master_detail($masters);

    # capture composite join information from instructions
    # my $composites = $instrs && $$instrs{'COMPOSITES'};

    $appdef{'BACKGROUND'} = $ENV{'BGCOLOR'}
      if $ENV{'BGCOLOR'};
    $appdef{'FOREGROUND'} = $ENV{'FGCOLOR'}
      if $ENV{'FGCOLOR'};

    $self->{app_object} = new Curses::Application( \%appdef )
      or die "Unable to create application object";
    my $app = $self->{app_object};

    # sorry... see button_push
    $Global_app_ref = $app;

    my $field_list = $self->get_field_list;

    my $database = $DBIx::Perform::DB;
    $field_list->set_db_type_values( $database, $self );

    my $mwh = $app->mwh();    # main window handle.
    my ( $maxy, $maxx ) = $app->maxyx();

    #warn "max screen size = $maxx, $maxy\n";
    Curses::leaveok( curscr, 1 );
    Curses::raw();
    my $i = 0;

    # parse per file data into an array of form hashes - multiple forms occur
    my $array_of_forms =
      $self->capture_file_data( $file_hash, $maxy - 2, $maxx, \%appdef );

    my @formnames;
    foreach my $sfd ( @{$array_of_forms} ) {
        warn Data::Dumper->Dump( [$sfd], ['sfd'] ) if $::TRACE_DATA;
        my %runformdef = %{ $self->{form_hash} };
        my $defname    = "RunDef$i";
        my $formname   = "Run$i";

        @runformdef{qw(X Y LINES COLUMNS DERIVED SUBFORMS )} =
          ( 0, 0, $maxy, $maxx, 1, { 'DBForm' => $sfd } );
        push( @formnames, $formname );
        $app->addFormDef( $defname, {%runformdef} );
        $app->createForm( $formname, $defname );
        $i++;
    }
    $self->{number_of_forms} = $i;

    $app->setField( MAINFORM => { Run0 => 'RunDef0' } );
    $app->setField( form_names => [@formnames] );
    $app->setField( form_name_indexes =>
          +{ map { ( $formnames[$_], $_ ) } 0 .. $#formnames } );
    $app->draw();
    $app->{'number'} = 0;
    $self->update_table(0);

    $self->add_field_list_to_screens;

    $self->compute_joins_by_tag;

#optimization idea
#    $i--;
#    for (; $i >= 0; $i--) {
#        my $form = $app->getForm("Run$i");
#        my $subform = $form->getSubform('DBForm');
#        $self->{subforms}->[$i] = $subform;
#    }

    # runtime loop

    while ( !$app->getField('EXIT') ) {    # run until user exits.
        my $fname = $app->getField('form_name');
        my $form = $self->{form_object} = $app->getForm($fname);
        $self->set_field_bounds_on_screen;
        warn "run loop, form :$fname:\n" if $::TRACE;
        die "unable to create form" unless defined($form);

        my $resumecmd = $app->getField('resume_command');
        if ($resumecmd) {
            &$resumecmd($form);
            $app->setField( 'resume_command', undef );
        }

        $app->execForm($fname);
    }
}

# returns an array ref of forms; in a form with master/detail defined,
# the master form is assumed to be first.
sub capture_file_data    # previously cursese_formdefs
{
    my $self     = shift;
    my $formspec = shift;    # input file contents
    my $maxy     = shift;
    my $maxx     = shift;
    my $appdef   = shift;

    my $attrs = $formspec->{'attrs'};

    my $lineoffset = 0;                             # used for combining screens
    my @formdefs   = ();
    my $appbg      = $$appdef{'BACKGROUND'};
    my $deffldbg   = $ENV{'FIELDBGCOLOR'} || 'black';

    my $fl =
      $self->get_field_list;    # full list of field objects from the per file
        #my $primary_table_name = $self->get_primary_table_name;

    foreach my $screen ( @{ $self->{screens} } ) {
        my $widgets = $$screen{'WIDGETS'};
        my $fields  = $$screen{'FIELDS'};

        # lists of field_objects for each screen
        # may need to be ordered by taborder
        my $screen_list = $fl->create_subset($fields);
        my @taborder    = $self->{taborder};

        my %def = (
            X        => 0,
            Y        => 2,
            COLUMNS  => $maxx,
            LINES    => $maxy - 2,
            DERIVED  => 1,
            ALTFBASE => 'DBIx::Perform::Forms',
            ALTBASE  => 'DBIx::Perform::Widgets',
            TABORDER => \@taborder,                 # TBD
            md_mode  => 'm',                        # master/detail mode.
            editmode => '',
        );

        $screen_list->reset;
        while ( my $f = $screen_list->iterate_list ) {
            my ( $tag, $table, $col ) = $f->get_names;
            my $w        = $widgets->{$tag};
            my $comments = $f->{comments};

          #  This "trampoline" function gives field name to the real OnExit fcn.
            $w->{'OnExit'} = sub { &DBIx::Perform::OnFieldExit( $tag, @_ ); };
            $w->{'OnEnter'} = sub {
                &DBIx::Perform::OnFieldEnter(
                    $comments
                    ? sub { $self->display_comment($comments); }
                    : $self->display_comment(''),
                    $tag, @_
                );
            };

            # keys
            $w->{'FOCUSSWITCH'} = "\t\n\cp\cw\cc\ck\c[\cf\cb";
            $w->{'FOCUSSWITCH_MACROKEYS'} = [ KEY_UP, KEY_DOWN, KEY_DEL ];

            my $color = $f->{color} || $deffldbg;
            $w->{'BACKGROUND'} = $color;

            # setup the open/close brackets for the field
            $$widgets{"$tag.openbracket"} = +{
                TYPE    => 'Label',
                COLUMNS => 1,
                ROWS    => 1,
                Y       => $w->{'Y'},
                X       => $w->{'X'} - 1,
                VALUE   => "[",
            };

            $$widgets{"$tag.closebracket"} = +{
                TYPE    => 'Label',
                COLUMNS => 1,
                ROWS    => 1,
                Y       => $w->{'Y'},
                X       => $w->{'X'} + $w->{'COLUMNS'},
                VALUE   => "]",
            };
        }

        $def{'WIDGETS'} = {%$widgets}, push( @formdefs, {%def} );
    }
    return \@formdefs;
}

# display_help_screen _should_ use STDOUT, not STDERR, but STDOUT didn't
#   work well.
sub display_help_screen {
    my $self    = shift;
    my $textkey = shift;
    my $text    = $Help_screens[$textkey];
    my $app     = $self->{app_object};
    my ( $maxy, $maxx ) = $app->maxyx();
    my $y = $maxy - 2;
    my $key;

    Curses::endwin;
    Curses::raw;
    print STDERR "\n" x ($maxy+$maxy);
    $text .= "\n" x $y;
    do {
        print STDERR "\r\n\n";
        $text =~ s/(([^\n]*\n){$y})//;
        my $scr_of_text = $1;
        if ($text =~ /[^\n]/) {
            $scr_of_text .=
              "\nPress SPACE for more or any other key to leave help";
        }
        else {
            $scr_of_text .= "Press a key to leave help";
        }
        print STDERR "$scr_of_text";
        $key = getc(STDIN);
    } while ( $text =~ /[^\n]/ && $key eq " " );

    #make Curses redraw the screen
    Curses::refresh(curscr);
}

# clear the two status lines at the bottom
# of the screen: i.e. comment and error/status
sub clear_comment_and_error_display {
    my $self = shift;

    $self->clear_display_error;
    $self->clear_display_comment;

    return undef;
}

sub display_comment {
    my $self    = shift;
    my $message = shift;

    my $form = $self->{form_object};
    my $wid  = $form->getWidget('Comment');
    my $mwh  = $form->{MWH};

    $wid->setField( 'VALUE', $message );
    $wid->draw($mwh) if $mwh;

    return undef;
}

sub clear_display_comment {
    my $self = shift;

    my $message = "";

    my $form = $self->{form_object};
    my $wid  = $form->getWidget('Comment');
    my $mwh  = $form->{MWH};

    $wid->setField( 'VALUE', $message );
    $wid->draw($mwh) if $mwh;

    return undef;
}

sub display_status {
    my $self    = shift;
    my $message = shift;

    $message = $self->{error_messages}->{$message}
      if defined $message && length($message) <= 5;

    # don't draw if there is no message
    return if !defined $message;
    return if length($message) == 0;

    #    $message = ' ' . $message . '  ';

    my $len  = length($message);
    $len = $MAXX if $len > $MAXX;
    my $form = $self->{form_object};
    my $wid  = $form->getWidget('Error');
    my $mwh  = $form->{MWH};

    my $bg = lc $ENV{'BGCOLOR'} || 'black';
    my $fg = $bg =~ /black|blue/i ? 'white' : 'black';

    $wid->setField( 'VALUE',      $message );
    $wid->setField( 'COLUMNS',    $len );
    $wid->setField( 'FOREGROUND', $fg );
    $wid->setField( 'BACKGROUND', $bg );

    $wid->draw($mwh) if $mwh;

    return undef;
}

sub clear_display_status {
    my $self = shift;

    my $message = "";
    my $bg      = lc $ENV{'BGCOLOR'} || 'black';
    my $fg      = $bg;

    my $form = $self->{form_object};
    my $wid  = $form->getWidget('Error');
    my $mwh  = $form->{MWH};

    my $ov = $wid->getField('VALUE');

    # don't redraw if there is no message
    return if length($ov) == 0;

    $wid->setField( 'VALUE',      $message );
    $wid->setField( 'COLUMNS',    0 );
    $wid->setField( 'FOREGROUND', $fg );
    $wid->setField( 'BACKGROUND', $bg );

    $wid->draw($mwh) if $mwh;

    return undef;
}

sub display_error {
    my $self    = shift;
    my $message = shift;
    my $dontrev = shift;

    warn "entering display_error\n" if $::TRACE;

    $message = $self->{error_messages}->{$message}
      if defined $message && length($message) <= 5;

    # don't draw if there is no message
    return if !defined $message;
    return if length($message) == 0;

    #    $message = ' ' . $message . '  ';

    my $len  = length($message);
    $len = $MAXX if $len > $MAXX;
    my $form = $self->{form_object};
    my $wid  = $form->getWidget('Error');
    my $mwh  = $form->{MWH};

    $wid->setField( 'VALUE',   $message );
    $wid->setField( 'COLUMNS', $len );
    my $env = lc $ENV{'BGCOLOR'} || 'black';
    my $bg  = $env;
    unless ($dontrev) {
        $bg = $env =~ /black|blue/i ? 'white' : 'black';
    }
    my $fg = $bg =~ /black|blue/i ? 'white' : 'black';

    $wid->setField( 'FOREGROUND', $fg );
    $wid->setField( 'BACKGROUND', $bg );

    $wid->draw($mwh) if $mwh;

    warn "leaving display_error\n" if $::TRACE;
    return undef;
}

sub clear_display_error {
    warn "entering clear_display_error\n" if $::TRACE;
    my $self = shift;

    my $message = "";
    my $bg      = lc $ENV{'BGCOLOR'} || 'black';
    my $fg      = $bg;

    my $form = $self->{form_object};
    my $wid  = $form->getWidget('Error');
    my $mwh  = $form->{MWH};

    my $ov = $wid->getField('VALUE');

    # don't redraw if there is no message
    return if length($ov) == 0;

    $wid->setField( 'VALUE',      $message );
    $wid->setField( 'COLUMNS',    0 );
    $wid->setField( 'FOREGROUND', $fg );
    $wid->setField( 'BACKGROUND', $bg );

    $wid->draw($mwh) if $mwh;

    return undef;
}

sub set_field {
    my $self  = shift;
    my $name  = shift;
    my $value = shift;
    my $app   = $self->{app_object};

    return $app->setfield( $name, $value );
}

sub change_field_focus_on_screen {
    my $self  = shift;
    my $fo    = shift;
    my $index = shift;    # can be empty

    warn "entering change_field_focus_on_screen" if $::TRACE;

    my ( $tag, $table, $col ) = $fo->get_names;

    my $l  = $self->get_field_list;
    my $fl = $l->clone_list;

    my $ct   = $self->get_current_table_name;
    my $form = $self->get_current_form;

    my $subform = $form->getSubform('DBForm');
    my $mode    = $subform->getField('editmode');

    my @taborder = $fl->get_field_tags($ct);

    $index = 0 if !defined($index);
    my $match = undef;

    $fl->reset;
    while ( my $fvar = $fl->iterate_list ) {
        my $tg = $fvar->get_names;
        if ( defined($match) ) {
            if ( $fvar->allows_focus($mode) ) {
                $subform->setField( 'FOCUSED', $taborder[$index] );
                $self->{focus} = $taborder[$index];
                return $index;
            }
        }
        $match = 1 if $tg eq $tag;
        return undef if $index++ > $#taborder;    # or not
    }

    warn "leaving change_field_focus_on_screen" if $::TRACE;
    return undef;                                 # no match or focus
}

sub register_button_handler {
    my $self    = shift;
    my $button  = shift;
    my $handler = shift;

    my $bhandler = $self->{button_handlers}->{$button} = $handler;
}

sub update_text {
    my $form = shift;
    my $GlobalUi    = $DBIx::Perform::GlobalUi;
    my $wid         = $form->getWidget('ModeButtons');
    my $val         = $wid->getField('VALUE');
    my $names       = $wid->getField('NAMES');
#    my $labels      = $wid->getField('LABELS');
    my $thisname    = lc( $$names[$val] );
#    my $thislabel   = lc( $$labels[$val] );
    my $btn_handler = $Button_handlers{$thisname};

    $GlobalUi->display_comment("");
    $GlobalUi->clear_display_error;
    my $m   = $Info_messages{$thisname};
    my $wmm = $form->getWidget('InfoMsg');
    $wmm->setField( 'VALUE', $m );
    $wmm->setField( 'COLUMNS', length $m );
    return $btn_handler;
}

sub button_push {
    my $form = shift;
    my $key  = shift;

    my $GlobalUi    = $DBIx::Perform::GlobalUi;
    my $app         = $Global_app_ref;                   # sorry

    warn "TRACE: entering button_push\n" if $::TRACE;
    if ( $key eq KEY_RIGHT || $key eq KEY_LEFT || $key eq ' '
         || $key eq KEY_UP || $key eq KEY_DOWN ) {
        $form->setField( 'DONTSWITCH', 1 );
        update_text($form);
	return;
    }
    elsif ( $key =~ /\d/ ) {
        warn "TRACE: button_push, number key\n" if $::TRACE;
        $app->{'number'} *= 10;
        $app->{'number'} += $key;
        $form->setField( 'DONTSWITCH', 1 );
	return;
    }
    elsif ( $key eq "\cw" ) {
        $GlobalUi->display_help_screen(0);
        $form->setField( 'DONTSWITCH', 1 );
	return;
    }
    my $btn_handler = update_text($form);
    if ( $btn_handler && ref($btn_handler) eq 'CODE' ) {
        &$btn_handler( lc($key), $form );
        $app->{'number'} = 0;
    }
    warn "TRACE: leaving button_push\n" if $::TRACE;
}

# replace the buttons with a mode label
sub change_buttons_to_label {
    my $self = shift;
    my $str  = shift;

    warn "entering change_buttons_to_label\n" if $::TRACE;

    my $form = $self->{form_object};
    my $wid  = $form->getWidget('ModeButtons');

    $wid->setField( 'COLUMNS', 0 );

    $wid = $form->getWidget('ModeLabel');
    $str = substr($str, 0, 70);
    $wid->setField( 'VALUE',   $str );
    $wid->setField( 'COLUMNS', length $str );

    warn "leaving change_buttons_to_label\n" if $::TRACE;
    return undef;
}

# replace a mode label with mode buttons
sub change_label_to_buttons {
    my $self = shift;

    warn "entering change_label_to_buttons\n" if $::TRACE;

    my $form = $self->{form_object};
    my $wid  = $form->getWidget('ModeLabel');

    $wid->setField( 'VALUE',   '' );
    $wid->setField( 'COLUMNS', 0 );

    $self->change_modename($msgs->[2]); #msgs->[2]='perform' if LANG=en 
    warn "leaving change_label_to_buttons\n" if $::TRACE;
    return undef;
}

sub switch_buttons {
    my $self = shift;
    my $form = shift;

    warn "entering switch_buttons\n" if $::TRACE;

    my $wid    = $form->getWidget('ModeButtons');

    $wid->setField( 'NAMES', \@Button_yn_names );
    $wid->setField( 'LABELS', \@Buttons_yn );
    $self->change_modename( $msgs->[9] );  # 9 = 'remove'

    $wid  = $form->getWidget('InfoMsg');
    $wid->setField( 'VALUE', $msgs->[37] );  
    warn "leaving switch_buttons\n" if $::TRACE;
}

sub change_modename {
    my $self = shift;
    my $name = shift;

    warn "entering change_modename\n" if $::TRACE;

    my $form = $self->{form_object};

    $name = $name . ':  ';
    $name = uc($name);

    my $wid = $form->getWidget('ModeName');
    $wid->setField( 'VALUE', $name );
    $wid = $form->getWidget('ModeLabel');
    $wid->setField( 'X', length $name );

    warn "leaving change_modename\n" if $::TRACE;
    return undef;
}

sub update_info_message {
    return;
    my $self    = shift;
    my $form    = shift;
    my $message = shift;

    warn "entering update_info_message\n" if $::TRACE;

    my %info_msgs = %{ $self->{info_messages} };
    my $msg       = $info_msgs{$message};
    my $wid       = $form->getWidget('InfoMsg');

    $wid->setField( 'VALUE', $msg );

    warn "leaving update_info_message\n" if $::TRACE;
    return undef;
}

sub update_subform {
    my $self    = shift;
    my $subform = shift;

    my $mwh = $subform->{MWH};
    $subform->draw($mwh);

    return undef;
}

# setup bracket values for a tag widget
sub set_field_display_bounds {
    my $self  = shift;
    my $tag   = shift;
    my $lchar = shift;
    my $rchar = shift;

#warn "TRACE: entering set_field_display_bounds for $lchar $tag $rchar\n"
#  if $::TRACE;

    my $form    = $self->get_current_form;
    my $subform = $form->getSubform('DBForm');

    my $ostr = $tag . ".openbracket";
    my $cstr = $tag . ".closebracket";

    my $ow = $subform->getWidget($ostr);
    my $cw = $subform->getWidget($cstr);

    return if !defined($ow) || !defined($cw);

    $ow->setField( 'VALUE', $lchar );
    $cw->setField( 'VALUE', $rchar );

    #    warn "TRACE: leaving set_field_display_bounds\n" if $::TRACE;
    return undef;
}

sub set_field_bounds_on_screen {
    my $self = shift;

    warn "TRACE: entering set_field_bounds_on_screen\n" if $::TRACE;

    my $current_table = $self->get_current_table_name;

    my $app     = $self->{app_object};
    my $form    = $self->get_current_form;
    my $subform = $form->getSubform('DBForm');
    my $mode    = $subform->getField('editmode');

    my $pl = $self->get_field_list;
    my $fl = $pl->clone_list;

    $fl->reset;
    while ( my $f = $fl->iterate_list ) {
        my ( $tag, $table, $column ) = $f->get_names;
        $self->set_field_display_bounds( $tag, ' ', ' ' );
    }

    $fl->reset;
    while ( my $f = $fl->iterate_list ) {
        my ( $tag, $table, $column ) = $f->get_names;
        if ( $table eq $current_table ) {
            $self->set_field_display_bounds( $tag, '[', ']' )
              if $f->allows_focus($mode);
        }
    }
    warn "TRACE: leaving set_field_bounds_on_screen\n" if $::TRACE;
    return undef;
}

# rowlist support

sub init_rowlists {
    my $self = shift;

    warn "entering init_rowlists\n" if $::TRACE;

    my %tables = ();

#    $self->{rowlists} = new DBIx::Perform::SimpleList;

    # one rowlist per table
    my @tnames = @{ $self->{attribute_table_names} };
    for (my $i = 0; $i < @tnames; $i++) {
        my $t = $tnames[$i];
        my $r = new DBIx::Perform::SimpleList;
#        $self->{rowlists}->add_row($r);
        $tables{$t} = [$r, $i];
    }
#    $self->{current_rowlist} = $self->{rowlists}->current_row;

    $self->{rowlists} = \%tables;
    $self->{current_table_number} = 0;
    $self->{current_rowlist} = $self->{rowlists}->{$tnames[0]}[0];

    warn "leaving init_rowlists\n" if $::TRACE;
    return undef;
}

sub get_current_rowlist {
    my $self = shift;

    my $tbl = $self->get_current_table_name;
    return $self->{rowlists}->{$tbl}[0];
}

sub increment_global_rowlist {
    my $self = shift;

    my @tnames = @{ $self->{attribute_table_names} };
    my $n = $self->{current_table_number};
    $n++;
    $n = 0 if ($n >= @tnames);

    $self->{current_rowlist} = $self->{rowlists}->{$tnames[$n]}[0];
}

# field list wrapper

# we may want to isolate access someday

sub get_field_list {
    my $self = shift;

    return $self->{global_field_list};
}

# master and detail tables are associated with the runtime
# active table

sub capture_master_detail {
    my $self    = shift;
    my $masters = shift;

    return if !defined($masters);    # undef is okay

    foreach my $ma ($masters) {
        foreach my $ta (@$ma) {
            my $m = $ta->[0];
            my $d = $ta->[1];
            my %h;
            $h{$m} = $d;
            $self->{master_detail_list}->add_row_to_end( \%h );
        }
    }
}

sub get_master_detail_table_names {
    my $self  = shift;
    my $table = shift;

    my $tl = $self->{master_detail_list};
    my ( @masters, @details );

    $tl->reset;
    while ( my $hr = $tl->iterate_list ) {

        my %h      = %$hr;
        my @a      = keys(%h);
        my $master = $a[0];
        my $detail = $h{$master};

        # there may be multiple matches in $tl
        if ( $master eq $table || $detail eq $table ) {
            push @masters, $master;
            push @details, $detail;
        }
    }
    return ( \@masters, \@details );
}

# only call this if table exists
# beef this up if better is required.
sub go_to_table {
    my $self  = shift;
    my $table = shift;

    $self->{current_rowlist} = $self->{rowlists}->{$table}[0];
    $self->{current_table_number} = $self->{rowlists}->{$table}[1];
    $self->update_table($self->{current_table_number});
    return $table;

    my @tables = @{ $self->{attribute_table_names} };
    my $tab0   = $tables[0];
    my $ct     = $self->get_current_table_name;

    # sync global data to start of @tables
    foreach my $tab (@tables) {
        last if $ct eq $tab0;
        $self->increment_global_tablelist;
        $self->increment_global_rowlist;
        $ct = $self->get_current_table_name;
    }
    foreach my $tab (@tables) {
        return $tab
          if $tab eq $table;    # return on a match
                                # otherwise increment the global ds
        $self->increment_global_tablelist;
        $self->increment_global_rowlist;
    }
    return undef;
}

# tables are ordered by their appearance in the attribute section
# in the ".per" file

sub get_number_of_tables {
    my $self = shift;
    my $form = shift;

    my @tables = @{ $self->{attribute_table_names} };
    return $#tables;
}

sub get_primary_table_name {
    my $self = shift;
    my $form = shift;

    my @tnames = @{ $self->{attribute_table_names} };

    return $tnames[0];
}

sub get_current_table_name {
    my $self = shift;
    my $form = shift;

    my @tnames = @{ $self->{attribute_table_names} };
    my $tnum   = $self->{current_table_number};

    return $tnames[$tnum];
}

sub get_table_number {
    my $self = shift;
    my $form = shift;

    return $self->{current_table_number};
}

sub increment_global_tablelist {
    my $self = shift;

    my $form = $self->get_current_form;

    my $num = $self->get_table_number;
    my $max = $self->get_number_of_tables;

    ++$num;
    $num = 0 if $num > $max;

    # updates class and display
    $self->update_table($num);
}

sub update_table {
    my $self = shift;
    my $num  = shift;

    $self->update_table_number($num);
    $self->update_table_name($num);
}

# these two subs update the form

sub update_table_number {
    my $self         = shift;
    my $table_number = shift;

    my $form = $self->get_current_form;

    $self->{current_table_number} = $table_number;

    $table_number++;
    my $str = '** ' . $table_number . ': ';

    my $wid = $form->getWidget('TableNumber');
    $wid->setField( 'VALUE', $str );
}

sub update_table_name {
    my $self         = shift;
    my $table_number = shift;

    my $form   = $self->get_current_form;
    my @tnames = @{ $self->{attribute_table_names} };
    my $name   = $tnames[$table_number];

    $name = $name . ' table**';

    $self->{current_table_name} = $name;

    #  I don't know???
    #$self->set_field_bounds_on_screen;

    my $wid = $form->getWidget('TableName');
    $wid->setField( 'VALUE', $name );
}

sub get_current_form {
    my $self = shift;

    my $app = $self->{app_object};
    my $fn  = $app->getField('form_name');

    return $app->getForm($fn);
}

# screen support

# This assumes that any duplicate field tags
# are defined to always have the same value
# returns the value of the first instance of
# the field_tag parameter found in the global field_list.

sub get_screen_value {
    my $self      = shift;
    my $field_tag = shift;

    my $app = $self->{app_object};
    my $formn = $app->getField('form_names');

    my $i = 0;
    for (my $i = 0; $i < @$formn; $i++) {
        my $form = $app->getForm( 'Run' . $i );
        last if !defined($form);

        my $subform = $form->getSubform('DBForm');
#        my $subform = $self->{subforms}->[$i];
#        last if !defined $subform;
        my $w       = $subform->getWidget($field_tag);

        return $w->getField('VALUE')
          if defined($w);
    }
    return undef;
}

sub get_screen_subform_widget {
    my $self      = shift;
    my $field_tag = shift;

#    warn "entering get_screen_subform_widget\n" if $::TRACE;

    my $app = $self->{app_object};
    my $formn = $app->getField('form_names');
    my @w;
    my $subform;

    for (my $i = 0; $i < @$formn; $i++) {
        my $form = $app->getForm( 'Run' . $i );
        $subform = $form->getSubform('DBForm');
        my $wid = $subform->getWidget($field_tag);
        push @w, $wid if defined $wid;
    }

#    warn "leaving get_screen_subform_widget 2\n" if $::TRACE;
    return @w if @w;
    return undef;
}

=pod
# This assumes that any duplicate field tags
# are defined to always have the same value
# returns the assigned value of the first instance of
# the fiedl_tag parameter found in the global field_list.

sub old_set_screen_value {
    my $self      = shift;
    my $field_tag = shift;
    my $val       = shift;

    warn "entering set_screen_value\n" if $::TRACE;

    my $app = $self->{app_object};
    my $fl  = $self->{global_field_list}->clone_list;

    $fl->reset;
    while ( my $f = $fl->iterate_list ) {

        my $nof = $self->{number_of_forms};
        my $i   = 0;
        while ( $i < $nof ) {

            my $form = $app->getForm( "Run" . $i );

            my $subform = $form->getSubform('DBForm');
            my $w       = $subform->getWidget($field_tag);

            if ( defined($w) ) {
                $w->setField( 'VALUE', $val );
                warn "leaving set_screen_value 1\n" if $::TRACE;
                return;
            }
            $i++;
        }
    }
    warn "leaving set_screen_value 2\n" if $::TRACE;
    return undef;
}
=cut

sub set_screen_value {
    my $self      = shift;
    my $field_tag = shift;
    my $val       = shift;
    my $app       = $self->{app_object};

#warn "set_screen_val :$val:\n";
    my $scrns = DBIx::Perform::get_screen_from_tag($field_tag);

#    warn join (' , ', @$scrns) . "\n" if $::TRACE_DATA;
    foreach my $scr (@$scrns) {
        my $form    = $app->getForm("Run$scr");
        my $subform = $form->getSubform('DBForm');
#        my $subform = $self->{subforms}->[$scr];
        my $w       = $subform->getWidget($field_tag);
        $w->setField( 'VALUE', $val );
    }
}

sub redraw_subform {
warn "Entering redraw_subform\n" if $::TRACE;
    my $app = $DBIx::Perform::GlobalUi->{app_object};
    my $cf = $app->getField('form_name');
    my $form = $app->getForm($cf);
    my $subform = $form->getSubform('DBForm');
    my $mwh = $subform->{MWH};
    $subform->draw($mwh) if $mwh;
}

sub change_mode_display {
    my $self = shift;
    my $form = shift;
    my $mode = shift;

    warn "entering change_mode_display\n" if $::TRACE;

    die "Trouble changing mode display" if !defined($mode) || !defined($form);

    $mode = lc($mode);

    if ( $mode eq 'perform' )    # switching back to main form
    {
        $form->setField( 'EXIT', 1 );
        $self->change_modename($msgs->[2]);
        $self->change_label_to_buttons( $form, $mode );
        warn "leaving change_mode_display\n" if $::TRACE;
        return undef;
    }
    $form->setField( 'DONTSWITCH', 0 );
    my $str =  $self->{button_messages}->{$mode};
    my %translate_mode = ( query => 0, add => 4, update => 5 );
    my $i = $translate_mode{$mode} + 3;
    my $m = substr($msgs->[$i], 0, 8);

    $self->change_modename($m);
    $self->change_buttons_to_label($str);

    warn "leaving change_mode_display\n" if $::TRACE;
    return undef;
}

sub change_focus_to_button {
    my $self   = shift;
    my $form   = shift;
    my $button = shift;

    warn "entering change_focus_to_button\n" if $::TRACE;

    die "missing button parameter" if ( !defined($button) );

    $self->{form_object}->setField( 'EXIT',       1 );
    $self->{form_object}->setField( 'DONTSWITCH', 0 );
    $self->clear_display_error;
    $self->clear_display_comment;

    $self->change_mode_display( $form, $button );

    my $wid = $form->getWidget('ModeButtons');
    $wid->setField( 'LABELS', $self->{button_labels} );
    $wid->setField( 'NAMES', \@Button_names );

    $wid = $form->getWidget('InfoMsg');
    my $m = $self->{info_messages}->{remove};
    $wid->setField('VALUE', $m );

    warn "leaving change_focus_to_button\n" if $::TRACE;
    return undef;
}

sub change_focus_to_field_in_current_table {
    my $self = shift;
    my $tag  = shift;

    warn "entering change_focus_to_field_in_current_table\n" if $::TRACE;

    my $form    = $self->get_current_form;
    my $subform = $form->getSubform('DBForm');
    my $ct      = $self->get_current_table_name;
    my $mode    = $subform->getField('editmode');

    #my @taborder = DBIx::Perform::Forms::generate_form_taborder($ct, $mode);
    my @taborder = DBIx::Perform::Forms::temp_generate_taborder( $ct, $mode );
    my $limit = $#taborder;
    my $i;
    for ( $i = 0 ; $i <= $limit ; $i++ ) {
        if ( $tag eq $taborder[$i] ) {
            $self->{'focus'}    = $taborder[$i];
            $self->{'newfocus'} = $taborder[$i];
            $subform->setField( 'FOCUSED', $taborder[$i] );
            warn "leaving change_focus_to_field_in_current_table\n" if $::TRACE;
            return $self->{focus};
        }
    }
    warn "Unable to find field to change focus to in current table" if $::TRACE;

    warn "leaving change_focus_to_field_in_current_table\n" if $::TRACE;
    return undef;
}

sub add_field_list_to_screens {
    my $self       = shift;
    my @scrns      = @{ $self->{screens} };
    my $field_list = $self->{global_field_list};

    foreach my $scr (@scrns) {
        my $sf = $scr->{WIDGETS};

        $field_list->reset;
        while ( my $fo = $field_list->iterate_list ) {
            my ( $tag, $tab, $col ) = $fo->get_names;
            my @wid =
              $self->get_screen_subform_widget($tag);

            if ( defined( $sf->{$tag} ) ) {
                for (my $i = $#wid; $i >= 0; $i--) {
                    $sf->{$tag}->{'NAME'} = $tag;
                    $wid[$i]->setField( 'NAME', $tag );

                    # add "one-time" attribute info

                    # SIZE
                    $fo->{size} = $sf->{$tag}->{COLUMNS}
                      if !defined $fo->{subscript_ceiling}
                      || !defined $fo->{format}
                      || !defined $fo->{picture};

                    # REVERSE
                    my $reverse = $fo->{reverse};
                    if ( defined $reverse ) {
                        my $env = lc $ENV{'BGCOLOR'} || 'black';
                        my $bg = $env =~ /black|blue/i ? 'white' : 'black';
                        my $fg = $bg =~ /black|blue/i ? 'white' : 'black';

                        $wid[$i]->setField( 'FOREGROUND', $fg );
                        $wid[$i]->setField( 'BACKGROUND', $bg );
                    }
                }
            }
        }
    }

    warn Data::Dumper->Dump( [@scrns], ['scrns'] ) if $::TRACE_DATA;
    return undef;
}

#make a hash recording all the joins by field_tag.
sub compute_joins_by_tag {
    my $self       = shift;
    my $app        = $self->{app_object};
    my $fl = $self->{global_field_list};
    my %hash;
    my %joins_by_tag;

    $fl->reset;
    while ( my $fo = $fl->iterate_list ) {
        my ( $tag, $tab, $col ) = $fo->get_names;

        if ($hash{$tag}) {
            $joins_by_tag{$tag} = 1;
        }
        $hash{$tag} = 1;
    }
    $app->{joins_by_tag} = \%joins_by_tag;
#    return  %joins_by_tag;
}

1;
