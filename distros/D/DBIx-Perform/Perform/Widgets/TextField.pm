# Brenton Chapin, Martin Baer et. al ...
package DBIx::Perform::Widgets::TextField;

use base 'Curses::Widgets::TextField';

use Curses;
use Curses::Widgets;

use constant 'KEY_DEL' => '330';    # dunno why not in Curses.

use 5.6.0;

our $VERSION = '0.695';

Curses::define_key( "\c[[Z", KEY_STAB );    # for some reason not recognized.

our $OVERWRITE = 1;

our $KEY_ESC = "\c[";
our $KEY_RET = "\n";
our $KEY_TAB = "\t";

# focus switch table isn't working
sub is_FSKEY {
    my $self = shift;
    my $in   = shift;

    return undef
      if ( $in ne $KEY_TAB
        && $in ne $KEY_RET
        && $in ne $KEY_ESC
        && $in ne KEY_UP
        && $in ne KEY_DOWN
        && $in ne KEY_LEFT
        && $in ne KEY_RIGHT
        && $in ne KEY_BACKSPACE
        && $in ne "\cH" );

    return 1;
}

# Validates and initialises a new TextField object.
# Overriding Curses::Widgets::TextField::_conf
sub _conf {

    my $self = shift;
    my %conf = (
        NAME        => undef,
        CAPTION     => undef,
        COLUMNS     => 10,
        LINES       => 1,
        MAXLENGTH   => 255,
        MASK        => undef,
        VALUE       => '',
        INPUTFUNC   => \&scankey,
        BORDER      => 1,
        FOCUSSWITCH => "\t\n",
        CURSORPOS   => 0,
        TEXTSTART   => 0,
        PASSWORD    => 0,
        READONLY    => 0,
        @_
    );
    my @required = qw(X Y);
    my $err      = 0;

    # Check for required arguments
    foreach (@required) { $err = 1 unless exists $conf{$_} }

    # Make sure no errors are returned by the parent method
    $err = 1 unless $self->SUPER::_conf(%conf);

    return $err == 0 ? 1 : 0;
}

sub input_key {

    # Process input a keystroke at a time.

    my $self = shift;
    my $in   = shift;
    my $conf = $self->{CONF};
    my $mask = $$conf{MASK};
    my $tag  = $$conf{NAME};

    my $GlobalUi = $DBIx::Perform::GlobalUi;
    my $table    = $GlobalUi->get_current_table_name;
    my $fl       = $GlobalUi->get_field_list;
    my $fo       = $fl->get_field_object( $table, $tag );
    my $form     = $GlobalUi->get_current_form;
    my $subform  = $form->getSubform('DBForm');
    my $mode     = $subform->getField('editmode');

    $fo->{size} = $$conf{COLUMNS}
      if !defined $fo->{subscript_ceiling}
      || !defined $fo->{format}
      || !defined $fo->{picture};

    my ($shift) =
      grep { $$conf{attrs}{$_} } qw(UPSHIFT DOWNSHIFT);
    my ( $value, $pos, $ro ) = @$conf{qw(VALUE CURSORPOS READONLY)};

    $max   = 80;
    $max   = $fo->{size} if $mode ne 'query';

    if (defined $fo->{picture}) {
        my ($pic, $rc) = $fo->do_picture('');
        $value .= substr($pic, length($value));
    }

    my @string = split( //, $value );

    # Process special keys
    if ( $in eq "\cX" ) {    # ctrl-x = delete char forward
        return if $ro;
        my ($val2, $rc) = $fo->do_picture($value, 1);
        my $len = length($val2);
        my $pos2 = $pos;
        if (defined $fo->{picture}) {
            my $partpic = substr($fo->{picture}, 0, $pos);
            $pos2 = $partpic =~ tr/[AX#]//;
        }
        @string = split( //, $val2 );
        if ( $pos2 < $len && $len > 0 ) {
            splice( @string, $pos2, 1 );
            $val2 = join '', @string;
            $fo->set_value($val2);
            ($value, $rc) = $fo->do_picture($val2);
        }
        else {
            beep;
        }
    }
    elsif ( $in eq KEY_UP || $in eq KEY_DOWN ) {
        $$conf{'EXIT'} = 1;
    }
    elsif ( $in eq KEY_RIGHT ) {
        do {
            if ( $pos >= length($value) || $pos >= $max-1) {
                $pos = 0;
                $$conf{'EXIT'} = 1;
            }
	    $pos++;
        } while ($fo->is_picture_char($pos));
    }
    elsif ( $in eq KEY_LEFT or $in eq KEY_BACKSPACE or $in eq "\cH" ) {
        do {
            if ( --$pos < 0 ) {
                $pos = 0;
                $$conf{'EXIT'} = 1;
            }
        } while ($fo->is_picture_char($pos));
    }
    elsif ( $in eq KEY_HOME ) {
        $pos = 0;
        while ($fo->is_picture_char($pos)) { $pos++; }
    }
    elsif ( $in eq KEY_END ) {
        $pos = length($value);
        while ($fo->is_picture_char($pos)) { $pos--; }
    }
    elsif ( $in eq "\cD" ) {    # clear to end of field
        splice( @string, $pos, $#string - $pos + 1 );
        $value = join( '', @string );
        my ($val2, $rc) = $fo->do_picture($value, 1);
        $fo->set_value($val2);
    }
    elsif ( $in eq "\cA" ) {
        $OVERWRITE = !$OVERWRITE;
    }
    else                        # Process the other keys
    {
        return if $ro || $in !~ /^[[:print:]]$/;
        return if defined $self->is_FSKEY($in);

        # Exit if it's a non-printing character
        unless ( $in =~ /^[\w\W]$/ ) {
            $pos = 0;
            return;
        }

        if ($$conf{FIRSTKEY} && $fo->is_any_numeric_db_type) {
            my $pos2 = $pos;
            if (defined $fo->{picture}) {
                my $partpic = substr($fo->{picture}, 0, $pos);
                $pos2 = $partpic =~ tr/[AX#]//;
            }
            $value = substr($value, 0, $pos2);
            $fo->set_value($value);
        }
        $$conf{FIRSTKEY} = 0;

        # UPSHIFT / DOWNSHIFT attributes
        $in = $fo->handle_shift_attributes($in);

        # PICTURE attribute
        # this is executed here and in onExit (below)
        my $rc;
        ( $in, $pos, $rc ) = $fo->handle_picture_attribute( $in, $pos );
        if ( $rc != 0 ) { beep; return; }

        # Append to the end if the cursor's at the end
        my $autonext = $fo->{autonext};
        my $vlen     = length($value);
        if ( $pos == $vlen ) {

            # Reject if we're already at the max length
            if ( $vlen >= $max && !defined $autonext ) {
                beep;
                return;
            }
            $value .= $in;
        }
        elsif ($OVERWRITE) {
            splice( @string, $pos, 1, $in );
            $value = join( '', @string );
        }
        else { #if ( $pos > 0 ) {
            my ($val2, $rc) = $fo->do_picture($value, 1);
            @string = split( //, $val2 );
            my $pos2 = $pos;
            if (defined $fo->{picture}) {
                my $partpic = substr($fo->{picture}, 0, $pos);
                $pos2 = $partpic =~ tr/[AX#]//;
            }
            @string =
              ( @string[ 0 .. ( $pos2 - 1 ) ], $in,
                @string[ $pos2 .. $#string ] );
            $val2 = join( '', @string );
            ($value, $rc) = $fo->do_picture($val2);
        }
        my ($val2, $rc) = $fo->do_picture($value, 1);
        $fo->set_value($val2);

        # Increment the cursor's position
        #++$pos;
        my $len = length($value);

        if ( $len >= $max && defined $autonext ) {
            @$conf{qw(VALUE CURSORPOS)} = ( $value, $pos );
            $$conf{'EXIT'} = 1;
            beep;
            return;
        }
        do {
            ++$pos;
        } while ($fo->is_picture_char( $pos ));
    }

    # Save the changes
    @$conf{qw(VALUE CURSORPOS)} = ( $value, $pos );
}

#  Overriding Curses::Widgets::execute
sub execute {
    my $self   = shift;
    my $mwh    = shift;
    my $conf   = $self->{CONF};
    my $func   = $$conf{'INPUTFUNC'} || \&scankey;
    my $fskeys = $$conf{'FOCUSSWITCH'};
    my $mkeys  = $$conf{'FOCUSSWITCH_MACROKEYS'};
    my $key;

    my ( $val, $pos, $rc );

    warn "TRACE: entering Curses::Widgets::execute\n" if $::TRACE;
    warn Data::Dumper->Dump( [$self], ['widget_obj'] ) if $::TRACE_DATA;

    $mkeys = [$mkeys] if ( defined($mkeys) && ref($mkeys) ne 'ARRAY' );
    my $regex =
      $mkeys
      ? ( "([$fskeys]|" . join( '|', @$mkeys ) . ")" )
      : "[$fskeys]";

    $self->draw( $mwh, 1 );

    $$conf{FIRSTKEY} = 1;

    $key = "\t";    #default keypress, for AUTONEXT
    while (1) {
        last if $$conf{'EXIT'};    # ADDED
        $key = &$func($mwh);
        if ( defined $key ) {
            undef $rc;

            # replace with KEY_FSTAB when available
            if ( defined $self->is_FSKEY($key) ) {
                $rc = $self->_onExit;
            }
            else { $rc = 0; }
            if ( defined $regex ) {
                last
                  if (
                    ( $key =~ /^$regex/ && $rc == 0 )
                    || (   $fskeys =~ /\t/
                        && $key eq KEY_STAB
                        && defined $self->is_FSKEY($key)
                        && $rc == 0 )
                  );
            }
            $self->input_key($key);
        }
        my $value = $$conf{VALUE};
        if (length($value) > $$conf{COLUMNS}) {
            $$conf{'EXIT'} = 1;
            last;
        }
        $self->draw( $mwh, 1 );
    }

#    $$conf{CURSORPOS} = 0; # removed so 'overflow' field can get cursor pos
    warn "TRACE: leaving Curses::Widgets::execute\n" if $::TRACE;
    return $key;
}

sub _content {
    my $self   = shift;
    my $dwh    = shift;
    my $cursor = shift;
    my $conf   = $self->{CONF};
    my $fo     = $$conf{FieldObj};
    my ( $pos, $ts, $value, $border, $col ) =
      @$conf{qw(CURSORPOS TEXTSTART VALUE BORDER COLUMNS)};

    my $seg;

    # Trim the value if it exceeds the maximum length
    $value = substr( $value, 0, $$conf{MAXLENGTH} ) if $$conf{MAXLENGTH};

    # Adjust the cursor position and text start if it's out of whack
    if ( $pos > length($value)+1 ) {
        $pos = length($value)+1;
    }
    elsif ( $pos < 0 ) {
        $pos = 0;
    }
    if ( $pos > $ts + $$conf{COLUMNS} - 1 ) {
        $ts = $pos - $$conf{COLUMNS};
    }
    elsif ( $pos < $ts ) {
        $ts = $pos;
    }
    $ts = 0 if $ts < 0;

    # Write the widget value (adjusting for horizontal scrolling)
    $seg = substr( $value, $ts, $$conf{COLUMNS} );
    $seg = '*' x length($seg) if $$conf{PASSWORD};
#    $seg .= ' ' x ( $$conf{COLUMNS} - length($seg) );
    $dwh->addstr( 0, 0, $seg );
    $dwh->attroff(A_BOLD);

    # Save the textstart, cursorpos, and value in case it was tweaked
    @$conf{qw(TEXTSTART CURSORPOS VALUE)} = ( $ts, $pos, $value );

}

sub _cursor {
    my $self = shift;
    my $dwh  = shift;
    my $conf = $self->{CONF};

    # Display the cursor
    my $cpos = $$conf{CURSORPOS} - $$conf{TEXTSTART};
    my $attr = A_STANDOUT;
    if ( $cpos > $$conf{COLUMNS} ) {
        $cpos--;
        $attr = A_REVERSE;
    }
    $dwh->chgat( 0, $cpos, 1, $attr,
        select_colour( @$conf{qw(FOREGROUND BACKGROUND)} ), 0 )
      unless $$conf{READONLY};

    # Restore the default settings
    $self->_restore($dwh);
}

# This is new - handles runtime behavior of text fields
sub _onExit {
    $self = shift;

    my $conf     = $self->{CONF};
    my $tag      = $$conf{NAME};
    my $rc       = undef;
    my $GlobalUi = $DBIx::Perform::GlobalUi;
    my $table    = $GlobalUi->get_current_table_name;
    my $fl       = $GlobalUi->get_field_list;
    my $fo       = $fl->get_field_object( $table, $tag );
    my $form     = $GlobalUi->get_current_form;
    my $subform  = $form->getSubform('DBForm');
    my $mode     = $subform->getField('editmode');

    return unless defined $fo;
    my ( $value, $pos ) = @$conf{qw(VALUE CURSORPOS )};
    ($value, $rc) = $fo->do_picture($value, 1) if $mode !~ /^q/i;
    $value = $fo->get_value if defined $self->{value};

    return ( $value, $pos, 0 )
      if length($value) == 0;

    # db field  may need numeric values
#    my $need_number = $fo->is_any_numeric_db_type;
#    my $is_number   = $fo->is_number($value);

#    if ( !$is_number && $need_number ) {
#        $GlobalUi->display_error('er11d');
#        return ( $value, $pos, -1 );
#    }

    ($value, $rc) = $fo->format_value_for_display( $value ) if $mode !~ /^q/i;
    $GlobalUi->set_screen_value( $tag, $value);
    return $rc;
}

1;

