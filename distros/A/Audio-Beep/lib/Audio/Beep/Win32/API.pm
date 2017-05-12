package Audio::Beep::Win32::API;

$Audio::Beep::Win32::API::VERSION = 0.11;

use strict;
use Carp;
use Win32::API;

sub new {
    my $class = shift;
    my $player = Win32::API->new('kernel32', 'Beep', 'NN', 'N') 
        or croak "Cannot initialize " . __PACKAGE__ . " object";
    return bless {
        player  => $player
    }, $class;
}

sub play {
    my $self = shift;
    my ($freq, $duration) = @_;
    return $self->{player}->Call(sprintf("%.0f", $freq), $duration);
}

sub rest {
    my $self = shift;
    my ($duration) = @_;
    Win32::Sleep( $duration );
    return 1;
}

=head1 NAME

Audio::Beep::Win32::API - Audio::Beep player using Win32 API call

=head1 SYNOPSIS

    my $player = Audio::Beep::Win32::API->new();

=head1 NOTES

This player makes a call to the Windows API. 
It works only on NT, 2000 or XP. 
Windows 95/98/ME have this API call but does another thing 
(plays a standard beep).

Requires Win32::API module. You can find sources on CPAN.
Some PPM precompiled packages can be found at L<http://dada.perl.it/PPM/>

=head1 BUGS

This module is not thoroughly tested. Please report any bug you may find.

=head1 COPYRIGHT

Copyright 2003-2004 Giulio Motta L<giulienk@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
