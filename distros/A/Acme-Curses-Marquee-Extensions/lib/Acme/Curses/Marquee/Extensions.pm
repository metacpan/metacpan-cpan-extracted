package Acme::Curses::Marquee::Extensions;
use strict;
use warnings;
require 5.006;

use base 'Acme::Curses::Marquee';
our $VERSION = 0.04;

use Text::FIGlet 2.00;
use Curses qw(A_BLINK);          #Don't clobber scroll!    XXX
use Term::ANSIColor;             #Many curses don't have color
use Every;

sub import{
  use Acme::Curses::Marquee::EVIL; #XXX Pass along vertical
}

sub new{
  my $class = shift;
  my %args = (
	      active => 0,
	      winh   => 25,
	      winw   => 80,
	      winx   => 0,
	      winy   => 0,
	      @_ );

  $args{srctxt} = delete($args{text});

  #Instantiate the font(s)
  my $font;
  if( ref($args{font}) eq 'ARRAY' ){
    local($_);

    $args{_fonts} = $args{font};
    $args{_fontSec} = pop @{$args{_fonts}} if $args{_fonts}->[-1] =~ /^\d+/;

    $font = $args{_font}->{ $args{font}=$_ } = font({}, $_, '-0') for
      reverse @{$args{_fonts}};
  }
  else{
    $font = $args{_font}->{$args{font}} = font({}, $args{font}, '-0');
  }

  #For text's rendering
  $args{height} = $font->{_header}->[1];
  $args{width}  = $args{winw};

  #Set up the display
  $args{winy} ||= int($args{winh}/2 - $args{height}/2);
  $args{win} = new Curses($args{height},$args{winw},$args{winy},$args{winx});

  my $self = bless \%args, $class;
  $self->text($self->{srctxt}) if (defined $self->{srctxt});

  return $self;
}

sub font {
  $_[0]->{_font}->{$_[1]} = Text::FIGlet->new(-f=>$_[1]);
  delete($_[0]->{_sweep});
  return $_[-1] eq '-0' ? $_[0]->{_font}->{$_[1]} : shift->SUPER::font(@_);
}

sub sweep{
  my($self, $state) = @_;

  if( $state == -1 && $self->{offset} == int($self->{txtlen}/2) ){
    $self->{txtlen} = $self->{_sweep};
  }

  if( $state ){
    return if exists($self->{_sweep});
    $self->{offset} = $self->{_sweep} = $self->{txtlen};
    $self->{txtlen}+= $self->{width};
  }
  else{
#    $self->{offset} = 0;
    $self->{txtlen} = delete($self->{_sweep});
  }
}

{
  my $i = 0;
  sub scroll{
    my $self = shift;
    #XXX offset would work if we could account for one wrap-around...
#   if( defined($self->{_fonts}) && ($self->{offset} == $self->{txtlen}) ){
    if( defined($self->{_fonts}) && every seconds=>$self->{_fontSec}||45 ){
      #XXX reposition vertically iff auto-centered
      $self->font( $self->{_fonts}->[ ++$i %scalar(@{ $self->{_fonts} }) ]);
    }
    $self->SUPER::scroll;
  }
}

{
  my $i = 0;
  my $rainbow = [qw/red yellow/,'bold yellow',qw/green cyan blue magenta/];
  sub colors{
    my($self, %p) = @_;
    my @colors = @{$p{colors}||$rainbow};
    if( every seconds=>$p{delay}||5 ){
      print color $colors[$i++%scalar @colors];
    }
  }
}

#XXX
sub blink{
  print color 'blink';
}

1;
__END__

=pod

=head1 NAME

Acme::Curses::Marquee::Extensions - Extensions for Acme::Curses::Marquee

=head1 SYNOPSIS

  use Package::Alias ACME => 'Acme::Curses::Marquee::Extensions';
  use Acme::Curses::Marquee::Extensions;
  use Term::ReadKey 'GetTerminalSize';
  use Time::HiRes 'usleep';

  my ($x, $y) = GetTerminalSize;
  my $m = ACME->new(winw => $x, winh => $y,
                    font => [qw/doh caligraphy fraktur/],
                    text => 'Hello World!' );
  while( 1 ){
    $m->scroll( usleep 75_000 );
  }

=head1 DESCRIPTION

Inherits all methods of L<Acme::Curses::Marquee>, except for C<new>,
which is among those outlined below.

This module also performs a little slight of hand to remove the
parent class's dependency on a figlet binary (in your path).

=head2 new( I<%params> )

=over

=item winw

The width of the window. Defaults to 80.

=item winh

The height of the window. Defaults to 25.

=item winx

Location of the origin's abscissa. Defaults to 0.

=item winy

Location of the origin's ordinate. Defaults to (winh - fontHeight)/2
i.e; vertically centered.

=item font

Figfont to use, defaults to standard.

This also accepts an arrayref, which can be a list of fonts to rotate through.
If cycling fonts, the last element of the arrayref may be a number indicating
the number of seconds between transitions. Otherwise, this occurs every 45 sec.

For the time being, you probably want to use fonts of the similar heights,
and list the tallest first.

=item text

The text to render.

=back

=head2 colors(delay=>I<seconds>, colors=>I<[colors]>)

=over

=item delay

The number of seconds between color changes. Defaults to 5.

=item colors

An arrayref of colors to cycle through. Defaults to a rainbow i.e;
'red', 'yellow', 'bold yellow', 'green', 'cyan', 'blue', 'magenta'
See L<Term::ANSIColor> for legal values.

=back

=head2 sweep( I<toggle> )

True values enable a left-to-right sweep-in of the message before scrolling.
Set once, and left enabled, sweeping will result in a sort of "Knight Rider"
effect. A toggle of I<-1> will use this effect only once, as a fade-in.

Note that you can change your sweep state at any time, though the interval
should exceed the time it takes for the message to scroll e.g;

  use Every;
  ...
  $m->sweep(1);
  while( 1 ){
    do{exists$m->{_sweep}?$m->sweep(0):$m->sweep(1)} if every seconds=>60;
    ...
  }

=head1 ENVIRONMENT

See L<Text::FIGlet>.

=head1 FILES

See L<Text::FIGlet>.

=head1 CAVEATS

Unfortunately many curses don't implement color, so we use L<Term::ANSIColor>.

=head1 AUTHOR

Jerrad Pierce E<lt>jpierce@cpan.orgE<gt>

=head1 LICENSE

=over

=item * Thou shalt not claim ownership of unmodified materials.

=item * Thou shalt not claim whole ownership of modified materials.

=item * Thou shalt grant the indemnity of the provider of materials.

=item * Thou shalt use and dispense freely without other restrictions.

=back

Or if you truly insist, you may use and distribute this under ther terms
of Perl itself (GPL and/or Artistic License).

=cut
