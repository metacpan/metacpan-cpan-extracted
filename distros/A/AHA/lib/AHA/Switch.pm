=head1 NAME

AHA::Switch - Object representing an AHA managed switch/actor

=head1 SYNOPSIS
    
    # Parent object for doing the HTTP communication
    my $aha = new AHA("fritz.box","s!cr!t");
 
    # Switch represented by the $ain which can be a name or a real AIN 
    my $switch = new AHA::Switch($aha,$ain)

    # Obtain all switches from a list operation
    for my $switch (@{$aha->list()}) {
        say $switch->name(),": ",$switch->is_on();
    }
    
=head1 DESCRIPTION

This module represents an actor/switch for the AVM home automation system. It
encapsulated an actor with a certain AIN and provides all methods as described
in L<"AHA"> with the difference, that not AIN is required, since this has
been already provided during the construction of this object.

=head1 METHODS

=over 

=cut

package AHA::Switch;
use vars qw{$AUTOLOAD};

=item $switch = new AHA::Switch($aha,$ain)

Create a new switch object. The first object must be an L<"AHA"> instance,
which is responsible for the HTTP communication. The second argument Many must
be an 8-digit AIN (actor id) or a symbolic name. This symbolic name
can be configured in the admin UI of the Fritz Box.

=cut

sub new {
    my $class = shift;
    my $aha = shift;
    my $self = {
                aha => $aha,
                ain => $aha->_ain(shift)
               };
    return bless $self,$class;
}

=item $ain = $switch->ain()

Get the AIN which this object represents.

=cut

sub ain {
    return shift->{ain};
}

=item $switch->is_on()

=item $switch->is_present()

=item $switch->on()

=item $switch->off()

=item $switch->energy()

=item $switch->power()

=item $switch->name()

Same as the corresponding method in L<"AHA"> with the exception, that no
C<$ain> argument is required since it already has been given during
construction time

=back 

=cut

my %SUPPORTED_METHODS = (map { $_ => 1 } qw(is_on is_present on off energy power name));

sub AUTOLOAD {
    my $self = shift;
    ( my $method = $AUTOLOAD ) =~ s{.*::}{};
    die "Unknown method $method" unless $SUPPORTED_METHODS{$method};
    return $self->{aha}->$method($self->{ain});
}

use overload fallback => 1,
  '""' => sub { "[AIN " . shift->{ain} . "]" }; 

1;
