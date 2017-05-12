package Curses::UI::Time;

# Pragmas.
use Curses::UI::Widget;
use base qw(Curses::UI::ContainerWidget);
use strict;
use warnings;

# Modules.
use Curses;
use Curses::UI::Common qw(keys_to_lowercase);
use Curses::UI::Label;
use Curses::UI::Number;
use Encode qw(decode_utf8);
use Readonly;

# Constants.
Readonly::Scalar our $COLON => decode_utf8(<<'END');
    
 ██ 
    
 ██ 
    
END
Readonly::Scalar our $DASH => q{-};
Readonly::Scalar our $HEIGHT_BASE => 5;
Readonly::Scalar our $HEIGHT_DATE => 7;
Readonly::Scalar our $YEAR_ADD => 1900;
Readonly::Scalar our $WIDTH_BASE => 32;
Readonly::Scalar our $WIDTH_COLON => 4;
Readonly::Scalar our $WIDTH_DATE => 10;
Readonly::Scalar our $WIDTH_NUM => 6;
Readonly::Scalar our $WIDTH_SEC => 52;
Readonly::Scalar our $WIDTH_SPACE => 1;

# Version.
our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, %userargs) = @_;
	keys_to_lowercase(\%userargs);
	my %args = (
		'-colon' => 1,
		'-date' => 0,
		'-fg' => -1,
		'-time' => time,
		'-second' => 0,
		%userargs,
		-focusable => 0,
	);

	# Width and height.
	if ($args{'-date'}) {
		$args{'-height'} = height_by_windowscrheight($HEIGHT_DATE,
			%args);
	} else {
		$args{'-height'} = height_by_windowscrheight($HEIGHT_BASE,
			%args);
	}
	if ($args{'-second'}) {
		$args{'-width'} = width_by_windowscrwidth($WIDTH_SEC, %args);
	} else {
		$args{'-width'} = width_by_windowscrwidth($WIDTH_BASE, %args);
	}

	# Create the widget.
	my $self = $class->SUPER::new(%args);

	# Parse time.
	my ($sec, $min, $hour, $day, $mon, $year) = $self->_localtime($self->{'-time'});

	# Widgets.
	my $x = 0;
	$self->add(
		'hour1', 'Curses::UI::Number',
		'-fg' => $self->{'-fg'},
		'-num' => (substr $hour, 0, 1),
		'-x' => $x,
	);
	$x += $WIDTH_NUM + $WIDTH_SPACE;
	$self->add(
		'hour2', 'Curses::UI::Number',
		'-fg' => $self->{'-fg'},
		'-num' => (substr $hour, 1, 1),
		'-x' => $x,
	);
	$x += $WIDTH_NUM + $WIDTH_SPACE;
	$self->add(
		'colon1', 'Label',
		'-fg' => $self->{'-fg'},
		'-hidden' => ! $self->{'-colon'},
		'-text' => $COLON,
		'-x' => $x,
	);
	$x += $WIDTH_COLON + $WIDTH_SPACE;
	$self->add(
		'min1', 'Curses::UI::Number',
		'-fg' => $self->{'-fg'},
		'-num' => (substr $min, 0, 1),
		'-x' => $x,
	);
	$x += $WIDTH_NUM + $WIDTH_SPACE;
	$self->add(
		'min2', 'Curses::UI::Number',
		'-fg' => $self->{'-fg'},
		'-num' => (substr $min, 1, 1),
		'-x' => $x,
	);
	if ($self->{'-second'}) {
		$x += $WIDTH_NUM + $WIDTH_SPACE;
		$self->add(
			'colon2', 'Label',
			'-fg' => $self->{'-fg'},
			'-hidden' => ! $self->{'-colon'},
			'-text' => $COLON,
			'-x' => $x,
		);
		$x += $WIDTH_COLON + $WIDTH_SPACE;
		$self->add(
			'sec1', 'Curses::UI::Number',
			'-fg' => $self->{'-fg'},
			'-num' => (substr $sec, 0, 1),
			'-x' => $x,
		);
		$x += $WIDTH_NUM + $WIDTH_SPACE;
		$self->add(
			'sec2', 'Curses::UI::Number',
			'-fg' => $self->{'-fg'},
			'-num' => (substr $sec, 1, 1),
			'-x' => $x,
		);
	}
	if ($self->{'-date'}) {
		my $date_x = ($self->width - $WIDTH_DATE) / 2;
		$self->add(
			'date', 'Label',
			'-text' => (join $DASH, $year, $mon, $day),
			'-fg' => $self->{'-fg'},
			'-x' => $date_x,
			'-y' => $HEIGHT_DATE - 1,
		);
	}

	# Layout.
	$self->layout;

	# Return object.
	return $self;
}

# Get or set colon flag.
sub colon {
	my ($self, $colon) = @_;
	if (defined $colon) {
		$self->{'-colon'} = $colon;
		if ($colon) {
			$self->getobj('colon1')->show;
		} else {
			$self->getobj('colon1')->hide;
		}
		if ($self->{'-second'}) {
			if ($colon) {
				$self->getobj('colon2')->show;
			} else {
				$self->getobj('colon2')->hide;
			}
		}
	}
	return $self->{'-colon'};
}

# Get or set time.
sub time {
	my ($self, $time) = @_;
	if (defined $time) {
		$self->{'-time'} = $time;
		my ($sec, $min, $hour, $day, $mon, $year)
			= $self->_localtime($time);
		$self->getobj('hour1')->num(substr $hour, 0, 1);
		$self->getobj('hour2')->num(substr $hour, 1, 1);
		$self->getobj('min1')->num(substr $min, 0, 1);
		$self->getobj('min2')->num(substr $min, 1, 1);
		if ($self->{'-second'}) {
			$self->getobj('sec1')->num(substr $sec, 0, 1);
			$self->getobj('sec2')->num(substr $sec, 1, 1);
		}
		if ($self->{'-date'}) {
			$self->getobj('date')->text(join $DASH, $year, $mon,
				$day);
		}
	}
	return $self->{'-time'};
}

# Get prepared time and date fields.
sub _localtime {
	my ($self, $time) = @_;
	my ($sec, $min, $hour, $day, $mon, $year) = localtime $time;
	$sec = sprintf '%02d', $sec;
	$min = sprintf '%02d', $min;
	$hour = sprintf '%02d', $hour;
	$day = sprintf '%02d', $day;
	$mon = sprintf '%02d', ($mon + 1);
	$year = sprintf '%04d', ($year + $YEAR_ADD);
	return ($sec, $min, $hour, $day, $mon, $year);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Curses::UI::Time - Create and manipulate time widgets.

=head1 CLASS HIERARCHY

 Curses::UI::Widget
 Curses::UI::ContainerWidget
    |
    +----Curses::UI::ContainerWidget
       --Curses::UI::Label
       --Curses::UI::Number
            |
            +----Curses::UI::Time

=head1 SYNOPSIS

 use Curses::UI;
 my $win = $cui->add('window_id', 'Window');
 my $time = $win->add(
         'mynum', 'Curses::UI::Time',
         -time => 1400609240,
 );
 $time->draw;

=head1 DESCRIPTION

Curses::UI::Time is a widget that shows a time in graphic form.

=head1 STANDARD OPTIONS

C<-parent>, C<-x>, C<-y>, C<-width>, C<-height>, 
C<-pad>, C<-padleft>, C<-padright>, C<-padtop>, C<-padbottom>,
C<-ipad>, C<-ipadleft>, C<-ipadright>, C<-ipadtop>, C<-ipadbottom>,
C<-title>, C<-titlefullwidth>, C<-titlereverse>, C<-onfocus>,
C<-onblur>.

For an explanation of these standard options, see 
L<Curses::UI::Widget|Curses::UI::Widget>.

=head1 WIDGET-SPECIFIC OPTIONS

=over 8

=item * C<-colon> < NUMBER >

 View colon flag.
 Default value is '1'.

=item * C<-date> < DATE_FLAG >

 View date flag.
 Default value is 0.

=item * C<-fg> < CHARACTER >

 Foreground color.
 Possible values are defined in Curses::UI::Color.
 Default value is '-1'.

=item * C<-time> < TIME >

 Time.
 Default value is actual time.

=item * C<-second> < SECOND_FLAG >

 View second flag.
 Default value is 0.

=back

=head1 STANDARD METHODS

C<layout>, C<draw>, C<intellidraw>, C<focus>, C<onFocus>, C<onBlur>.

For an explanation of these standard methods, see
L<Curses::UI::Widget|Curses::UI::Widget>.

=head1 WIDGET-SPECIFIC METHODS

=over 8

=item * C<new(%parameters)>

 Constructor.
 Create widget with volume in graphic form, defined by -volume number.
 Returns object.

=item * C<colon()>

 Get or set colon flag.
 Returns colon flag.

=item * C<time()>

 Get or set time (and date with -date => 1).
 Returns time in seconds.

=back

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Curses::UI;

 # Object.
 my $cui = Curses::UI->new;
 
 # Main window.
 my $win = $cui->add('window_id', 'Window');
 
 # Add volume.
 $win->add(
         undef, 'Curses::UI::Time',
         '-time' => 1400609240,
 );
 
 # Binding for quit.
 $win->set_binding(\&exit, "\cQ", "\cC");
 
 # Loop.
 $cui->mainloop;

 # Output like:
 # ██████ ██████      ██████ ██████
 #     ██ ██  ██  ██  ██  ██     ██
 # ██████ ██  ██      ██  ██     ██
 # ██     ██  ██  ██  ██  ██     ██
 # ██████ ██████      ██████     ██

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Curses::UI;

 # Object.
 my $cui = Curses::UI->new(
         -color_support => 1,
 );
 
 # Main window.
 my $win = $cui->add('window_id', 'Window');

 # Add time.
 my $time = $win->add(
         undef, 'Curses::UI::Time',
         '-border' => 1,
         '-second' => 1,
         '-time' => time,
 );
 
 # Binding for quit.
 $win->set_binding(\&exit, "\cQ", "\cC");

 # Timer.
 $cui->set_timer(
         'timer',
         sub {
                 $time->time(time);
                 $cui->draw(1);
                 return;
         },
         1,
 );
 
 # Loop.
 $cui->mainloop;

 # Output like:
 # ┌────────────────────────────────────────────────────┐
 # │    ██     ██      ██████ ██████          ██ ██████ │
 # │    ██     ██  ██  ██  ██ ██  ██  ██      ██ ██  ██ │
 # │    ██     ██      ██  ██ ██  ██          ██ ██████ │
 # │    ██     ██  ██  ██  ██ ██  ██  ██      ██     ██ │
 # │    ██     ██      ██████ ██████          ██ ██████ │
 # └────────────────────────────────────────────────────┘

=head1 EXAMPLE3

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Curses::UI;

 # Object.
 my $cui = Curses::UI->new(
         -color_support => 1,
 );
 
 # Main window.
 my $win = $cui->add('window_id', 'Window');

 # Add time.
 my $time = $win->add(
         undef, 'Curses::UI::Time',
         '-border' => 1,
         '-date' => 1,
         '-second' => 1,
         '-time' => time,
 );
 
 # Binding for quit.
 $win->set_binding(\&exit, "\cQ", "\cC");

 # Timer.
 $cui->set_timer(
         'timer',
         sub {
                 $time->time(time);
                 $cui->draw(1);
                 return;
         },
         1,
 );
 
 # Loop.
 $cui->mainloop;

 # Output like:
 # ┌────────────────────────────────────────────────────┐
 # │    ██     ██      ██████ ██████      ██  ██ ██████ │
 # │    ██     ██  ██  ██  ██ ██  ██  ██  ██  ██ ██  ██ │
 # │    ██     ██      ██  ██ ██  ██      ██████ ██  ██ │
 # │    ██     ██  ██  ██  ██ ██  ██  ██      ██ ██  ██ │
 # │    ██     ██      ██████ ██████          ██ ██████ │
 # │                                                    │
 # │                      2014-05-24                    │
 # └────────────────────────────────────────────────────┘

=head1 DEPENDENCIES

L<Curses>,
L<Curses::UI::Common>,
L<Curses::UI::Label>,
L<Curses::UI::Number>,
L<Curses::UI::Widget>,
L<Encode>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Curses::UI>

Install the Curses::UI modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Curses-UI-Time>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 BSD 2-Clause License

=head1 DEDICATION

To Czech Perl Workshop 2014 and their organizers.

tty-clock program.

=head1 VERSION

0.05

=cut
