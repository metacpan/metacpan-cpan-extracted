# Brenton Chapin, Martin Baer, et. al.
package DBIx::Perform::Widgets::ButtonSet;

use strict;
use base qw(Curses::Widgets::ButtonSet);
use Curses;    # for KEY_foo constants.
use Curses::Widgets;
use base 'Exporter';

our $VERSION = '0.692';

sub _conf {
    my $self  = shift;
    my %stuff = @_;
    $stuff{TABORDER} = "\n"
      unless exists $stuff{TABORDER};
    $stuff{ACTIVATEKEY} = "\n";
    $self->SUPER::_conf(%stuff);
}

# Process input a keystroke at a time.
# Usage:  $self->input_key($key);
sub input_key {
    my $self = shift;
    my $in   = shift;
    my $conf = $self->{CONF};
    my ( $value, $hz ) = @$conf{qw(VALUE HORIZONTAL)};
    my @labels = @{ $$conf{LABELS} };
    my $num    = scalar @labels;        # 9 or 5

    # handle single letter shortcuts in the labels
    my @tmpl1 = @labels;
    my %char1 = map { ( lc( substr( $tmpl1[$_], 0, 1 ) ), $_ ) } 0 .. $#labels;
    my $ival  = $char1{ lc($in) };

    if ( defined($ival) ) {             # handle shortcut character
        $value = $ival;
        $$conf{EXIT} = 1;
    }
    elsif ($hz) {
        if ( $in eq KEY_RIGHT || $in eq ' ' ) {
            ++$value;
            $value = 0 if $value >= $num;
        }
        elsif ( $in eq KEY_LEFT ) {
            --$value;
            $value = ( $num - 1 ) if $value < 0;
        }
        elsif ( $in eq KEY_DOWN ) {
            $value = $$conf{LINEEND};
            $value = 0 if $value >= $num;
        }
        elsif ( $in eq KEY_UP ) {
            $value = $$conf{LINEBEGIN};
        }
        elsif ( $in !~ /[\d\cw]/ ) {
            beep;
        }
    }
    else {
        if ( $in eq KEY_UP ) {
            --$value;
            $value = ( $num - 1 ) if $value == -1;
        }
        elsif ( $in eq KEY_DOWN or $in eq ' ' ) {
            ++$value;
            $value = 0 if $value == $num;
        }
        else {
            beep;
        }
    }
    $$conf{VALUE} = $value;
}

sub execute {
    my $self  = shift;
    my $mwh   = shift;
    my $conf  = $self->{CONF};
    my $func  = $$conf{'INPUTFUNC'} || \&scankey;
    my $regex = $$conf{'FOCUSSWITCH'};
    my $key;

    $self->draw( $mwh, 1 );

    while (1) {
        $key = &$func($mwh);

        # change focus
        if ( defined $key ) {
            if ( defined $regex ) {
                return $key
                  if ( $key =~ /^[$regex]/
                    || ( $regex =~ /\t/ && $key eq KEY_STAB ) );
            }
            $self->input_key($key);
        }

        return $key if ( ( $key eq KEY_RIGHT ) || ( $key eq KEY_LEFT ) 
                         || $key eq ' ' );
        return $key if ( $key =~ /[\d\cw]/ );

        $self->draw( $mwh, 1 );
        if ( $conf->{EXIT} ) {
            $conf->{EXIT} = undef;
            return $conf->{ACTIVATEKEY};    # pretend we got the "go" key.
        }
    }
}

sub _content {
}

sub _cursor {
    my $self   = shift;
    my $dwh    = shift;
    my $conf   = $self->{CONF};
    my @labels = @{ $$conf{LABELS} };
    my ( $length, $hz ) = @$conf{qw(LENGTH HORIZONTAL)};
    my ( $y, $x ) = ( 0, 0 );
    my ($offset);
    my $i;
    my $bute;    # button end -- last column occupied by button
    my $b_line = "";
    my ( $lw, $lh );    #line width, height

    getmaxyx( $stdscr, $lh, $lw );

    # Enforce a sane cursor position
    if ( $$conf{VALUE} >= @labels ) {
        $$conf{VALUE} = @labels - 1;
    }
    elsif ( $$conf{VALUE} < 0 ) {
        $$conf{VALUE} = 0;
    }

    # Calculate the cell offset
    $offset = $$conf{BORDER} ? 1 : ( $$conf{PADDING} ? $$conf{PADDING} : 0 );

    # Set the coordinates
    if ($hz) {
        if ( $$conf{BORDER} ) {
            $offset =
                $$conf{VALUE}
              ? $$conf{VALUE} * $length + $$conf{VALUE} * $offset
              : 0;
        }
        else {
            $length = length( @labels[ $$conf{VALUE} ] ) + 2;
            $i      = 0;
            my $lb = 0;
            $bute   = $offset;
            foreach (@labels) {
                $bute += length($_) + 2;
                if ( $bute > $lw - 4 - $$conf{X} ) {
                    if ( $i > $$conf{VALUE} ) {
                        if ( $i < @labels ) {
                            $b_line .= " ...";
                        }
                        last;
                    }
                    $bute   = 7 + length($_);
                    $offset = 5;
                    $b_line = " ... ";
                    $$conf{LINEBEGIN} = $lb;
                    $lb = $i;
                }
                $i++;
                if ( $i <= $$conf{VALUE} ) {
                    $offset = $bute;
                }
                $b_line .= ' ' . $_ . ' ';
            }
            $$conf{LINEEND} = $i;
#FIX: next line is a hack to get around having to run through the entire
# list to figure out what LINEBEGIN should really be.  Works as long
# as the menu <= 2 lines.
            $$conf{LINEBEGIN} = $i if !$lb;
            $dwh->addstr( 0, 0, $b_line );
        }
        $x = $offset;
    }
    else {
        $offset = $$conf{VALUE} ? $$conf{VALUE} + $$conf{VALUE} * $offset : 0;
        $y = $offset;
    }

    # Display the cursor
    $dwh->chgat( $y, $x, $length, A_STANDOUT,
        select_colour( @$conf{qw(FOREGROUND BACKGROUND)} ), 0 );

    # Restore the default settings
    $self->_restore($dwh);
}

1;
