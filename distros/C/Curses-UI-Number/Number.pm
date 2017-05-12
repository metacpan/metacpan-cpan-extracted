package Curses::UI::Number;

# Pragmas.
use base qw(Curses::UI::Label);
use strict;
use warnings;

# Modules.
use Curses::UI::Common qw(keys_to_lowercase);
use Curses::UI::Label;
use Encode qw(decode_utf8);
use Readonly;

# Constants.
Readonly::Scalar our $BLANK_PIXEL => q{  };
Readonly::Scalar our $EMPTY_STR => q{};
Readonly::Scalar our $PIXELS => 14;
Readonly::Scalar our $PIXELS_ON_LINE => 3;

# Version.
our $VERSION = 0.06;

# Constructor.
sub new {
	my ($class, %userargs) = @_;
	keys_to_lowercase(\%userargs);
	my %args = (
		'-num' => undef,
		'-char' => decode_utf8('█'),
		%userargs,
	);

	# Text.
	$args{'-text'} = _text($args{'-char'}, $args{'-num'});

	# Create the widget.
	my $self = $class->SUPER::new(%args);

	# Layout.
	$self->layout;

	# Return object.
	return $self;
}

# Get or set number.
sub num {
	my ($self, $number) = @_;
	if (defined $number) {
		$self->{'-num'} = $number;
		$self->{'-text'} = _text($self->{'-char'}, $number);
	}
	return $self->{'-num'};
}

# Return structure of pixels.
sub _num {
	my $number = shift;
	return [
		[1,1,1,1,0,1,1,0,1,1,0,1,1,1,1], # 0
		[0,0,1,0,0,1,0,0,1,0,0,1,0,0,1], # 1
		[1,1,1,0,0,1,1,1,1,1,0,0,1,1,1], # 2
		[1,1,1,0,0,1,1,1,1,0,0,1,1,1,1], # 3
		[1,0,1,1,0,1,1,1,1,0,0,1,0,0,1], # 4
		[1,1,1,1,0,0,1,1,1,0,0,1,1,1,1], # 5
		[1,1,1,1,0,0,1,1,1,1,0,1,1,1,1], # 6
		[1,1,1,0,0,1,0,0,1,0,0,1,0,0,1], # 7
		[1,1,1,1,0,1,1,1,1,1,0,1,1,1,1], # 8
		[1,1,1,1,0,1,1,1,1,0,0,1,1,1,1], # 9
	]->[$number];
}

# Convert number to text.
sub _text {
	my ($char, $number) = @_;
	my $text = $EMPTY_STR;
	my $num_ar = _num($number);
	foreach my $i (0 .. $PIXELS) {
		if ($num_ar->[$i]) {
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

Curses::UI::Number - Create and manipulate number widgets.

=head1 CLASS HIERARCHY

 Curses::UI::Widget
    |
    +----Curses::UI::Label
            |
            +----Curses::UI::Number

=head1 SYNOPSIS

 use Curses::UI;
 my $win = $cui->add('window_id', 'Window');
 my $number = $win->add(
         'mynum', 'Curses::UI::Number',
         -num => 5,
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

=item * C<-num> < NUMBER >

 Number.
 Default value is undef.

=item * C<-char> < CHARACTER >

 Character for Curses::UI::Number drawing.
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

=item * C<num([$number])>

 Get or set number.
 Returns number (0 - 9).

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
         undef, 'Curses::UI::Number',
         '-num' => 5,
 );
 
 # Binding for quit.
 $win->set_binding(\&exit, "\cQ", "\cC");
 
 # Loop.
 $cui->mainloop;

 # Output like:
 # ██████
 # ██
 # ██████
 #     ██
 # ██████

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

 # Add number.
 my $num = $win->add(
         undef, 'Curses::UI::Number',
         '-border' => 1,
         '-num' => 0,
 );
 
 # Binding for quit.
 $win->set_binding(\&exit, "\cQ", "\cC");

 # Time.
 $cui->set_timer(
         'timer',
         sub {
                 my $act = $num->num;
                 $act += 1;
                 if ($act > 9) {
                         $act = 0;
                 }
                 $num->num($act);
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
 # │██████│
 # │██  ██│
 # │██████│
 # └──────┘

=head1 DEPENDENCIES

L<Curses::UI::Common>,
L<Curses::UI::Label>,
L<Curses::UI::Widget>,
L<Encode>.

=head1 SEE ALSO

=over

=item L<Task::Curses::UI>

Install the Curses::UI modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Curses-UI-Number>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 BSD 2-Clause License

=head1 DEDICATION

To Czech Perl Workshop 2014 and their organizers.

=head1 VERSION

0.06

=cut
