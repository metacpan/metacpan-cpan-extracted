package Acme::KeyboardMarathon;
$Acme::KeyboardMarathon::VERSION = '1.27';

use Carp;
use Data::Dumper;
use Math::BigInt;

use integer;
use warnings;
use strict;

sub new {
  my @args = @_;
  my $class = shift @args;
  my $self = {};
  bless($self,$class);

  croak("Odd number of arguments") if @args%2;
  my %args = @args;
  my $layout = delete $args{layout} || 'qwerty';
  croak("Unsupported layout $layout")
    unless $layout =~ /^(?:qwerty|dvorak)\z/;

  croak "Unknown options: " . join ", ", keys(%args) if keys %args;

  # all measures in 100ths of a cm

  my $depress_distance = 25;
  my $shift_distance = 200;

  # horizontal distances

  $self->{k} = {};

  no warnings 'qw';
  map { $self->{k}->{$_} = 550 } ( '\\', '|' );
  map { $self->{k}->{$_} = 500 } ( qw/6 ^ ` ~/ );
  map { $self->{k}->{$_} = 450 } ( qw/= +/ );
  map { $self->{k}->{$_} = 400 } ( qw/] 1 2 3 4 7 8 9 0 5 - _ ! @ # $ % & * ( ) }/ );
  map { $self->{k}->{$_} = 350 } ( qw/B b/ );
  map { $self->{k}->{$_} = 230 } ( qw/[ {/ );
  map { $self->{k}->{$_} = 200 } ( qw/Q q W w G g H h E e R r T t Y y U u I i O o P p Z z X x C c V v N n M m , < > . \/ ? ' "/ );
  map { $self->{k}->{$_} =   0 } ( qw/A a S s D d F f J j K k L l ; :/ );

  if ($layout eq 'dvorak') {
    map { $self->{k}->{$_} = 550 } ( '\\', '|' );
    map { $self->{k}->{$_} = 500 } ( qw/6 ^ ` ~/ );
    map { $self->{k}->{$_} = 450 } ( qw/] }/ );
    map { $self->{k}->{$_} = 400 } ( qw/+ = 1 2 3 4 7 8 9 0 5 [ { ! @ # $ % & * ( )/ );
    map { $self->{k}->{$_} = 350 } ( qw/X x/ );
    map { $self->{k}->{$_} = 230 } ( qw/? \// );
    map { $self->{k}->{$_} = 200 } ( qw/" ' < , I i D d > . P p Y y F f G g C c R r L l : ; Q q J j K k B b M m W w V v Z z - _/ );
    map { $self->{k}->{$_} =   0 } ( qw/A a O o E e U u H h T t N n S s/ );
  }

  $self->{k}->{"\n"} = 400;
  $self->{k}->{"\t"} = 230;
  $self->{k}->{' '}  =   0;

  # Add the depress distance
  for my $key ( keys %{$self->{k}} ) {
    $self->{k}->{$key} += $depress_distance;
  }

  # Add shift distance
  for my $key ( qw/! @ # $ % ^ & * ( ) _ + < > ? : " { } | ~ '/, 'A' .. 'Z' ) {
    $self->{k}->{$key} += $shift_distance;
  }

  # override
  $self->{k}->{"\a"} = 0; # alarm
  $self->{k}->{"\b"} = 0; # backspace
  $self->{k}->{"\e"} = 0; # escape
  $self->{k}->{"\f"} = 0; # form feed
  $self->{k}->{"\r"} = 0; # carriage return

  return $self;
}

# split is 2m27.476s for 9.3megs of text (9754400 chars)
sub distance {
  my $k = shift->{k};

  my $bint = Math::BigInt->bzero;
  my $int  = 0;

  for my $i (0 .. $#_) {
    croak "FAR OUT! A REFERENCE: $_[$i]" if ref $_[$i];

    for ( split '', $_[$i] ) {
      unless ( defined $k->{$_} ) {
        carp 'WHOAH! I DON\'T KNOW WHAT THIS IS: [' . sprintf('%2.2x',ord($_)) . " : $_] assigning it a 2.5 cm distance\n";

        $k->{$_} = 250;
      }

      $int += $k->{$_};

      # Hold the value in a native int until it reaches an unsafe limit.
      # Then add to the BigInt, this avoids repeated slow calls to badd.
      #
      # To play it safe, this value is the max signed 32bit int minus
      # the max distance a key can be (| - 550), i.e.
      #   2 ** 31 - 551 = 2_147_483_097
      if ( $int >= 2_147_483_097 ) {
        $bint->badd($int);

        $int = 0;
      }
    }
  }

  # Add whatever remaining value we have in the native int.
  $bint->badd($int);

  $bint->bdiv(100);

  return $bint->bstr;
}

# substr is 2m30.419s
#sub distance {
#  my $self = shift @_;
#  my $distance = Math::BigInt->bzero();
#  for my $i (0 .. $#_) {
#    croak "FAR OUT! A REFERENCE: $_[$i]" if ref $_[$i];
#    my $length = length($_[$i]) - 1;
#    for my $s ( 0 .. $length ) {
#      my $char = substr($_[$i],$s,1);
#      unless ( defined $self->{k}->{$char} ) {
#        carp "WHOAH! I DON'T KNOW WHAT THIS IS: [$char] at $s assigning it a 2.5 cm distance\n";
#        $self->{k}->{$char} = 250;
#      }
#      $distance += $self->{k}->{$char};
#    }
#  }
#  $distance /= 100;
#  return $distance->bstr();
#}

# Regex is 2m32.690s
#sub distance {
#  my $self = shift @_;
#  my $distance = Math::BigInt->bzero();
#  for my $i (0 .. $#_) {
#    croak "FAR OUT! A REFERENCE: $_[$i]" if ref $_[$i];
#    while ( $_[$i] =~ /(.)/gs ) {
#      my $char = $1;
#      unless ( defined $self->{k}->{$char} ) {
#        carp "WHOAH! I DON'T KNOW WHAT THIS IS: [$char] assigning it a 2.5 cm distance\n";
#        $self->{k}->{$char} = 250;
#      }
#      $distance += $self->{k}->{$char};
#    }
#  }
#  $distance /= 100;
#  return $distance->bstr();
#}


1;
__END__

=head1 NAME

Acme::KeyboardMarathon - How far have your fingers ran?

=head1 SYNOPSIS

  use Acme::KeyboardMarathon;    

  my $akm = new Acme::KeyboardMarathon;

  my $distance_in_cm = $akm->distance($bigtext);

NB: Included in this distribution is an example script (marathon.pl) that can
be used to calculate distance from files provided as arguments:

  $> ./marathon.pl foo.txt bar.txt baz.txt
  114.05 m

=head1 DESCRIPTION

Acme::KeyboardMarathon will calculate the approximate distance traveled by
your fingers to type a given string of text.

This is useful to see just how many meter/miles/marathons your fingers have
ran for you to type your latest piece of code or writing.

=head1 METHODOLOGY

In proper typing, for all but the "home row" letters, our fingers must travel
a short horizontal distance to reach the key. For all keys, there is also a
short distance to press the key downward. 

Measurements were take on a standard-layout IBM type-M keyboard to the nearest 
1/3rd of a centimeter for both horizontal and vertical (key depth) travel
by the finger.

Additionally, use of the shift key was tracked and its distance was included
for each calculation.

This produces an index of "distance traveled" for each possible key-press, 
which is then used to calculate the "total distance traveled" for a given
piece of text.

=head1 BUGS AND LIMITATIONS

* This module calculates the linear distance traversed by adding vertical 
and horizontal motion of the finger. The motion traversed is actually an 
arc, and while that calculation would be more accurate, this is an 
Acme module, after all. Send me a patch with the right math if you're bored.

* I assume there are no gaps between your keys. This means all those stylish 
Mac keyboard folks are actually doing more work than they're credited for. 
But I'm ok with that.

* I assume you actually use standard home row position. Just like Mavis Beacon 
told you to.

* I assume you return to home row after each stroke and don't take shortcuts to
the next key. Lazy typists!

* I assume that you never make mistakes and never use backspaces while typing.
We're all perfect, yes?

* I assume that you do not type via the use of copy and paste. Especially not
using copy and paste from Google. Right? RIGHT?!?!??

* I'VE NEVER HEARD OF CAPS LOCK. YOU PRESSED THAT SHIFT KEY AND RETURNED TO 
HOME ROW FOR EVERY CAPITAL LETTER!!!!!!!

* I am a horrible American barbarian and have only bothered with the keys that
show up on my American barbarian keyboard. I'll add the LATIN-1 things with 
diacritics later, so I can feel better while still ignoring UTF's existence.

=head1 BUGS AND SOURCE

	Bug tracking for this module: https://rt.cpan.org/Dist/Display.html?Name=Acme-KeyboardMarathon

	Source hosting: http://www.github.com/bennie/perl-Acme-KeyboardMarathon

=head1 VERSION

	Acme::KeyboardMarathon v1.27 (2022/01/07)

=head1 COPYRIGHT

	(c) 2012-2022, Evelyn Klein <evelykay@gmail.com> & Phillip Pollard <bennie@cpan.org>

=head1 LICENSE

This source code is released under the "Perl Artistic License 2.0," the text of
which is included in the LICENSE file of this distribution. It may also be
reviewed here: http://opensource.org/licenses/artistic-license-2.0

=head1 AUTHORSHIP

Evelyn Klein <evelykay@gmail.com> & Phillip Pollard <bennie@cpan.org>

As much as I wish I could be fully blamed for this, I must admit that
Mrs. Evelyn Klein came up with the awesome idea, took the time to make the
measurements, and wrote the original code in Python. I just made sure it 
was less readable, in Perl.

A significant boost in speed via a patch from James Raspass <jraspass@gmail.com>

Additional patches from Mark A. Smith. <jprogrammer082@gmail.com>

Non-judgemental support for DVORAK keyboards added anonymously by RT user
'spro^^*%*^6ut#@&$%*c in https://rt.cpan.org/Ticket/Display.html?id=117203