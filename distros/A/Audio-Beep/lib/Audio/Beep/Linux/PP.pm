package Audio::Beep::Linux::PP;

$Audio::Beep::Linux::PP::VERSION = 0.11;

use strict;
use Carp;
use IO::File;
use constant KIOCSOUND          =>  0x4B2F;     #from linux/kd.h
use constant CLOCK_TICK_RATE    =>  1193180;    #a magic number - see NOTES

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub play {
    my $self = shift;
    my ($freq, $duration) = @_;
    my $console;
    local $SIG{INT} = sub { _sigint( $console ) };
    $console = IO::File->new("/dev/console", O_WRONLY) 
        or confess "Cannot open console: $!";
    ioctl($console, KIOCSOUND, int(CLOCK_TICK_RATE / $freq)) 
        or confess "Call to ioctl failed: $!";
    select undef, undef, undef, $duration / 1000;
    ioctl($console, KIOCSOUND, 0)
        or confess "Call to ioctl failed: $!";
    $console->close;
    return 1;
}

sub rest {
    my $self = shift;
    my ($duration) = @_;
    select undef, undef, undef, $duration / 1000;
    return 1;
}

sub _sigint {
    my $console = shift;
    if (defined $console) {
        ioctl($console, KIOCSOUND, 0)
            or confess "Call to ioctl failed: $!";
        $console->close;
    }
    exit;
}

=head1 NAME

Audio::Beep::Linux::PP - PurePerl implementation of an Audio::Beep player

=head1 SYNOPSIS

    my $player = Audio::Beep::Linux::PP->new();

=head1 USAGE

The C<new> class method will return you a new player object.
No other option is available right now.

=head1 NOTES

You need to be root to play something using this module. 
Otherwise your script should be SUID root (but i won't suggest that).
Or you could own the tty where you execute this, but it cannot be an xterm.
It's better to install the B<beep> program by Johnathan Nightingale and 
then SUID that small program.
This module is just a rewriting of the core function of the B<beep> program.
I took everything from there so credit goes again to Johnathan Nightingale.
As this is a PurePerl module i had to do some assumption, like the 
KIOCSOUND constant to be 0x4B2F (which may not be your case).
The CLOCK_TICK_RATE is also taken from B<beep>.
Follows what you can read there:

 I don't know where this number comes from, I admit that freely.  A 
 wonderful human named Raine M. Ekman used it in a program that played
 a tune at the console, and apparently, it's how the kernel likes its
 sound requests to be phrased.  If you see Raine, thank him for me.  

 June 28, email from Peter Tirsek (peter at tirsek dot com):

 This number represents the fixed frequency of the original PC XT's
 timer chip (the 8254 AFAIR), which is approximately 1.193 MHz. This
 number is divided with the desired frequency to obtain a counter value,
 that is subsequently fed into the timer chip, tied to the PC speaker.
 The chip decreases this counter at every tick (1.193 MHz) and when it
 reaches zero, it toggles the state of the speaker (on/off, or in/out),
 resets the counter to the original value, and starts over. The end
 result of this is a tone at approximately the desired frequency. :)

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright 2003-2004 Giulio Motta L<giulienk@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
