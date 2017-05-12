package Audio::Play;
our $VERSION = '1.000';

use AutoLoader;
require Audio::Data;

# DynaLoader is for derived classes to simplify auto-generated sub-class.pm

require DynaLoader;
@ISA = qw(AutoLoader DynaLoader);

require "Audio/Play/$^O.pm";

sub new
{
 my $class = shift;
 return "Audio::Play::$^O"->new(@_);
}

sub rate 
{ 
 my $self = shift;
 croak("Cannot set rate") if @_;
 return 8000; 
}

sub DESTROY 
{ 
}

sub speaker
{
 my $self = shift;
 carp("Cannot set speaker") if @_;
 return 1;
}

sub headphone
{
 my $self = shift;
 carp("Cannot set headphone") if @_;
 return 0;
}

sub volume 
{
 my $self = shift;
 carp("Cannot set volume") if @_;
 return 1.0;
}

sub flush
{

}

1;
__END__

=head1 NAME 

Audio::Play - interface for B<Audio::Data> to hardware

=head1 SYNOPSIS 

  use Audio::Data;
  use Audio::Play;
  
  $audio = Audio::Data->new(...)
  
  $svr = Audio::Play->new;
  
  $svr->play($audio);
  
=head1 DESCRIPTION 

B<Audio::Play> is an wrapper class which loads B<Audio::Play::$^O> i.e.
a per-platform driver.

Each class provides the following interface:

=over 4

=item $svr = $class->new([$wait])

Create the server and return an object.
I<$wait> is supposed to determine whether to wait for device 
(and for how long) but is currently not really working for 
many devices.

=item $svr->rate($rate)

Set sample rate (if possible) to $rate.

=item $rate = $svr->rate;

Return sample rate.

=item $svr->play($audio[,$gain])

Play $audio via the hardware. Should take steps to match hardware 
and data's sampling rate.

=item $svr->gain($mult)

Set gain (if possible).

=item $svr->flush

Wait for playing to complete.

=item $svr->DESTROY 

Destructor flushes and closes hardware.

=back 4

=head1 AUTHOR 

Nick Ing-Simmons <Nick@Ing-Simmons.net>,
but sub-modules have been collected from wide variety of places.    

=cut 


