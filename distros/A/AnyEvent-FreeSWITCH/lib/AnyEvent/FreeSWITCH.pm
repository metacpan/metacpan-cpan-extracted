package AnyEvent::FreeSWITCH;

use 5.006;
use AnyEvent;
use Object::Event;
use ESL;
use Carp;
use strict;
use warnings;

our @ISA = qw/Object::Event/;

=head1 NAME

AnyEvent::FreeSWITCH - The great new AnyEvent::FreeSWITCH!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use AnyEvent::FreeSWITCH;

    my $foo = AnyEvent::FreeSWITCH->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new {
    my ($this, %args) = @_;    
    my $class = ref($this) || $this;
    my $self = bless(\%args, $class);
    
    $self->{host}     ||= '127.0.0.1';
    $self->{port}     ||= '8021';
    $self->{password} ||= 'ClueCon';
    $self->{events}   ||= 'all';
    
    return $self;
}

=head2 connect

=cut

sub connect {
    my $self = shift;
    
    $self->{esl} = new ESL::ESLconnection(
	$self->{host},
	$self->{port},
	$self->{password},
	);
    if ( $self->is_connected() ) {
	$self->event('connected');
	$self->{io} = AnyEvent->io(
	    fh => $self->{esl}->socketDescriptor(),
	    poll => "r",
	    cb => sub { $self->recv_events(); },
	    );
    } else {
	$self->event('error_connection');
    }
    
    $self->{esl}->events('plain', $self->{events});

}

=head2 recv_events

=cut

sub recv_events {
    my $self = shift;

    my $e = $self->{esl}->recvEventTimed(0);

    if( defined $e ) {
	$self->event('recv_event', $e->getType(), $e->serialize('json'));
	$self->event('event_'. $e->getType(), $e->serialize('json'));
    } 
}

=head2 is_connected

=cut

sub is_connected {
    my $self = shift;

    return $self->{esl}->connected();
}

=head2 api

=cut

sub api {
    my $self = shift;
    my $command = shift;
    my $args = shift;
    
    if ( not $self->is_connected() ) {
	$self->event('connection_error', "Error trying to run api command: $command $args");
	return undef;
    }
    
    my $e = $self->{esl}->api($command, $args);
    return $e->getBody();
}

=head1 AUTHOR

William King, C<< <william.king at quentustech.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-anyevent-freeswitch at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-FreeSWITCH>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::FreeSWITCH


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-FreeSWITCH>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-FreeSWITCH>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyEvent-FreeSWITCH>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-FreeSWITCH/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 William King.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/bsd-license.php>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of William King's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of AnyEvent::FreeSWITCH
