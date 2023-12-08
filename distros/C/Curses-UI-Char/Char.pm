package Curses::UI::Char;

use base qw(Curses::UI::Label);
use strict;
use warnings;

use Curses::UI::Common qw(keys_to_lowercase);
use Curses::UI::Label;
use Readonly;
use Unicode::UTF8 qw(decode_utf8);

Readonly::Scalar our $BLANK_PIXEL => q{  };
Readonly::Scalar our $EMPTY_STR => q{};
Readonly::Scalar our $PIXELS => 14;
Readonly::Scalar our $PIXELS_ON_LINE => 3;

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, %userargs) = @_;

	keys_to_lowercase(\%userargs);
	my %args = (
		'-char' => undef,
		'-fill' => decode_utf8('█'),
		%userargs,
	);

	# Text.
	$args{'-text'} = _text($args{'-fill'}, $args{'-char'});

	# Create the widget.
	my $self = $class->SUPER::new(%args);

	# Layout.
	$self->layout;

	return $self;
}

# Get or set character.
sub char {
	my ($self, $char) = @_;

	if (defined $char) {
		$self->{'-char'} = $char;
		$self->{'-text'} = _text($self->{'-fill'}, $char);
	}

	return $self->{'-char'};
}

# Return structure of pixels.
sub _char {
	my $char = shift;

	my $index = ord($char) - 65;

	return [
		[0,1,0,1,0,1,1,1,1,1,0,1,1,0,1], # A
		[1,1,0,1,0,1,1,1,0,1,0,1,1,1,0], # B
		[0,1,1,1,0,0,1,0,0,1,0,0,0,1,1], # C
		[1,1,0,1,0,1,1,0,1,1,0,1,1,1,0], # D
		[1,1,1,1,0,0,1,1,0,1,0,0,1,1,1], # E
		[1,1,1,1,0,0,1,1,0,1,0,0,1,0,0], # F
		[0,1,1,1,0,0,1,0,1,1,0,1,0,1,1], # G
		[1,0,1,1,0,1,1,1,1,1,0,1,1,0,1], # H
		[0,1,0,0,1,0,0,1,0,0,1,0,0,1,0], # I
		[0,0,1,0,0,1,0,0,1,1,0,1,0,1,0], # J
		[1,0,1,1,0,1,1,1,0,1,0,1,1,0,1], # K
		[1,0,0,1,0,0,1,0,0,1,0,0,1,1,1], # L
		[1,0,1,1,1,1,1,0,1,1,0,1,1,0,1], # M
		[1,0,0,1,1,0,1,1,0,1,0,1,1,0,1], # N
		[0,1,0,1,0,1,1,0,1,1,0,1,0,1,0], # O
		[1,1,0,1,0,1,1,1,0,1,0,0,1,0,0], # P
		[0,1,0,1,0,1,1,0,1,1,0,1,0,1,1], # Q
		[1,1,0,1,0,1,1,1,0,1,0,1,1,0,1], # R
		[0,1,1,1,0,0,0,1,0,0,0,1,1,1,0], # S
		[1,1,1,0,1,0,0,1,0,0,1,0,0,1,0], # T
		[1,0,1,1,0,1,1,0,1,1,0,1,1,1,1], # U
		[1,0,1,1,0,1,1,0,1,1,0,1,0,1,0], # V
		[1,0,1,1,0,1,1,0,1,1,1,1,1,0,1], # W
		[1,0,1,1,0,1,0,1,0,1,0,1,1,0,1], # X
		[1,0,1,1,0,1,0,1,0,0,1,0,0,1,0], # Y
		[1,1,1,0,0,1,0,1,0,1,0,0,1,1,1], # Z
	]->[$index];
}

# Convert number to text.
sub _text {
	my ($char, $number) = @_;

	my $text = $EMPTY_STR;
	my $char_ar = _char($number);
	foreach my $i (0 .. $PIXELS) {
		if ($char_ar->[$i]) {
			$text .= $char x 2;
		} else {
			$text .= $BLANK_PIXEL;
		}
		if ($i != $PIXELS && ($i + 1) % $PIXELS_ON_LINE == 0) {
			$text .= "\n";
		}
	}

	return $text;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Curses::UI::Char - Create and manipulate character widgets.

=head1 CLASS HIERARCHY

 Curses::UI::Widget
    |
    +----Curses::UI::Label
            |
            +----Curses::UI::Char

=head1 SYNOPSIS

 use Curses::UI;

 my $win = $cui->add('window_id', 'Window');
 my $number = $win->add(
         'mynum', 'Curses::UI::Char',
         -char => 5,
 );
 $number->draw;

=head1 DESCRIPTION

Curses::UI::Number is a widget that shows a number in graphic form.

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

=item * C<-char> < CHARACTER >

Character..

Default value is undef.

=item * C<-fill> < CHARACTER >

Character for Curses::UI::Char drawing.

Default value is '█'.

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

=item * C<char([$character])>

Get or set character.

Returns character (A - Z).

=back

=head1 EXAMPLE1

=for comment filename=curses_ui_alpha.pl

 use strict;
 use warnings;

 use Curses::UI;

 # Object.
 my $cui = Curses::UI->new;
 
 # Main window.
 my $win = $cui->add('window_id', 'Window');
 
 # Add volume.
 $win->add(
         undef, 'Curses::UI::Char',
         '-char' => 'A',
 );
 
 # Binding for quit.
 $win->set_binding(\&exit, "\cQ", "\cC");
 
 # Loop.
 $cui->mainloop;

 # Output like:
 #   ██
 # ██  ██
 # ██████
 # ██  ██
 # ██  ██

=head1 EXAMPLE2

=for comment filename=curses_ui_timer.pl

 use strict;
 use warnings;

 use Curses::UI;

 # Object.
 my $cui = Curses::UI->new(
         -color_support => 1,
 );
 
 # Main window.
 my $win = $cui->add('window_id', 'Window');

 # Add number.
 my $char = $win->add(
         undef, 'Curses::UI::Char',
         '-border' => 1,
         '-char' => 'A',
 );
 
 # Binding for quit.
 $win->set_binding(\&exit, "\cQ", "\cC");

 # Time.
 $cui->set_timer(
         'timer',
         sub {
                 my $act = ord($char->char) - 65;
                 $act += 1;
                 if ($act > 25) {
                         $act = 0;
                 }
                 $char->char(chr($act + 65));

                 return;
         },
         1,
 );
 
 # Loop.
 $cui->mainloop;

 # Output like:
 # ┌──────┐
 # │██████│
 # │██  ██│
 # │██  ██│
 # │██  ██│
 # │██████│
 # └──────┘

=head1 DEPENDENCIES

L<Curses::UI::Common>,
L<Curses::UI::Label>,
L<Curses::UI::Widget>,
L<Unicode::UTF8>.

=head1 SEE ALSO

=over

=item L<Task::Curses::UI>

Install the Curses::UI modules.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Curses-UI-Char>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2015-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
