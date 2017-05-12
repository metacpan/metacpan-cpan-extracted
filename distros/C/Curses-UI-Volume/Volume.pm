package Curses::UI::Volume;

# Pragmas.
use Curses::UI::Widget;
use base qw(Curses::UI::ContainerWidget);
use strict;
use warnings;

# Modules.
use Curses;
use Curses::UI::Common;
use Curses::UI::Label;
use Encode qw(decode_utf8);
use Readonly;

# Constants.
Readonly::Scalar our $FULL_BLOCK => decode_utf8('█');
Readonly::Scalar our $LEFT_SEVEN_EIGHTS_BLOCK => decode_utf8('▉');
Readonly::Scalar our $LEFT_THREE_QUARTERS_BLOCK => decode_utf8('▊');
Readonly::Scalar our $LEFT_FIVE_EIGHTS_BLOCK => decode_utf8('▋');
Readonly::Scalar our $LEFT_HALF_BLOCK => decode_utf8('▌');
Readonly::Scalar our $LEFT_THREE_EIGHTS_BLOCK => decode_utf8('▍');
Readonly::Scalar our $LEFT_ONE_QUARTER_BLOCK => decode_utf8('▎');
Readonly::Scalar our $LEFT_ONE_EIGHTH_BLOCK => decode_utf8('▏');

# Version.
our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, %userargs) = @_;
	keys_to_lowercase(\%userargs);
	my %args = (
		'-bg' => 'black',
		'-fg' => 'white',
		'-volume' => 0,
		%userargs,
		'-volume_width' => undef,
		'-focusable' => 0,
	);

	# Height and width.
	$args{'-height'} = height_by_windowscrheight(1, %args);
	if (! exists $args{'-width'}) {
		$args{'-width'} = width_by_windowscrwidth(3, %args);
	}

	# Check volume.
	$args{'-volume'} = _check_volume($args{'-volume'});

	# Create the widget.
	my $self = $class->SUPER::new(%args);

	# Volume effective area.
	$self->{'-volume_width'} = $self->width;
	if ($self->{'-border'} || $self->{'-sbborder'}) {
		$self->{'-volume_width'} -= 2;
	}

	# Main volume.
	$self->add(
		'volume', 'Label',
		'-bg' => $self->{'-bg'},
		'-fg' => $self->{'-fg'},
		'-text' => $self->_volume($self->{'-volume'}),
		'-width' => $args{'-width'},
	);

	# Layout.
	$self->layout;

	# Return object.
	return $self;
}

# Get or set volume.
sub volume {
	my ($self, $volume) = @_;
	if (defined $volume) {
		$volume = _check_volume($volume);
		$self->{'-volume'} = $volume;
		$self->getobj('volume')->text($self->_volume($volume));
	}
	return $self->{'-volume'};
}

# Check volume.
sub _check_volume {
	my $volume = shift;
	if (int($volume) != $volume) {
		$volume = 0;
	}
	if ($volume > 100) {
		$volume = 100;
	}
	if ($volume < 0) {
		$volume = 0;
	}
	return $volume;
}

# Set text label.
sub _volume {
	my ($self, $volume) = @_;
	my $parts = $self->{'-volume_width'} * 8;
	my $vol_parts = $volume / 100 * $parts;
	my $vol_blocks = int($vol_parts / 8);
	my $vol_other = $vol_parts % 8;
	my $other_char = '';
	if ($vol_other == 1) {
		$other_char = $LEFT_ONE_EIGHTH_BLOCK;
	} elsif ($vol_other == 2) {
		$other_char = $LEFT_ONE_QUARTER_BLOCK;
	} elsif ($vol_other == 3) {
		$other_char = $LEFT_THREE_EIGHTS_BLOCK;
	} elsif ($vol_other == 4) {
		$other_char = $LEFT_HALF_BLOCK;
	} elsif ($vol_other == 5) {
		$other_char = $LEFT_FIVE_EIGHTS_BLOCK;
	} elsif ($vol_other == 6) {
		$other_char = $LEFT_THREE_QUARTERS_BLOCK;
	} elsif ($vol_other == 7) {
		$other_char = $LEFT_SEVEN_EIGHTS_BLOCK;
	}
	return ($FULL_BLOCK x $vol_blocks).$other_char;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Curses::UI::Volume - Create and manipulate volume widgets.

=head1 CLASS HIERARCHY

 Curses::UI::Containter
 Curses::UI::Widget
    |
    +----Curses::UI::ContainerWidget
            |
            +----Curses::UI::Volume

=head1 SYNOPSIS

 use Curses::UI;
 my $win = $cui->add('window_id', 'Window');
 my $volume = $win->add(
         'myvolume', 'Curses::UI::Volume',
         -volume => 50,
 );
 $volume->draw;

=head1 DESCRIPTION

Curses::UI::Volume is a widget that shows a volume number in graphic form.
Precision is 8 stays in one character.

=head1 STANDARD OPTIONS

C<-parent>, C<-x>, C<-y>, C<-width>, C<-height>,
C<-pad>, C<-padleft>, C<-padright>, C<-padtop>, C<-padbottom>,
C<-ipad>, C<-ipadleft>, C<-ipadright>, C<-ipadtop>, C<-ipadbottom>,
C<-title>, C<-titlefullwidth>, C<-titlereverse>, C<-onfocus>,
C<-onblur>.

For an explanation of these standard options, see
L<Curses::UI::Widget|Curses::UI::Widget>.

=head1 REMOVED OPTIONS

C<-text>.

=head1 WIDGET-SPECIFIC OPTIONS

=over 8

=item * C<-bg> < COLOR >

 Background color.
 Possible values are defined in Curses::UI::Color.
 Default value is 'black'.

=item * C<-fg> < COLOR >

 Foreground color.
 Possible values are defined in Curses::UI::Color.
 Default value is 'white'.

=item * C<-volume> < PERCENT_NUMBER >

 If PERCENT_NUMBER is set, text on the label will be drawn as volume level for this percent number.
 Volume number is checked for 0 - 100% value.
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

=item * C<volume([$volume])>

 Get or set volume number.
 In set mode volume number is checked for 0 - 100% value.
 Returns volume number (0-100%).

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
         undef, 'Curses::UI::Volume',
         '-volume' => 50,
 );

 # Binding for quit.
 $win->set_binding(\&exit, "\cQ", "\cC");

 # Loop.
 $cui->mainloop;

 # Output like:
 # █▌

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

 # Add volume.
 my $vol = $win->add(
         undef, 'Curses::UI::Volume',
         '-border' => 1,
         '-volume' => 0,
         '-title' => 'foo',
         '-width' => 10,
 );

 # Binding for quit.
 $win->set_binding(\&exit, "\cQ", "\cC");

 # Time.
 $cui->set_timer(
         'timer',
         sub {
                 my $act = $vol->volume;
                 $act += 5;
                 if ($act > 100) {
                         $act = 0;
                 }
                 $vol->volume($act);
                 return;
         },
         1,
 );

 # Loop.
 $cui->mainloop;

 # Output like:
 # ┌ foo ───┐
 # │▊       │
 # └────────┘

=head1 DEPENDENCIES

L<Curses>,
L<Curses::UI::Common>,
L<Curses::UI::ContainerWidget>,
L<Curses::UI::Label>,
L<Curses::UI::Widget>,
L<Encode>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Curses::UI>

Install the Curses::UI modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Curses-UI-Volume>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.02

=cut
