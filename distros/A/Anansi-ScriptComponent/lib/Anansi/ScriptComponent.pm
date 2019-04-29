package Anansi::ScriptComponent;


=head1 NAME

Anansi::ScriptComponent - A manager template for Perl script interface interactions.

=head1 SYNOPSIS

    package Anansi::Script::Example;

    use base qw(Anansi::ScriptComponent);

    sub validate {
        my ($self, $channel, %parameters) = @_;
        return $self->SUPER::validate(undef);
    }

    Anansi::ScriptComponent::addChannel('Anansi::Script::Example', 'VALIDATE_AS_APPROPRIATE' => 'validate');

    1;

=head1 DESCRIPTION

Manages a Perl script's interface interactions with the user providing generic
processes to co-ordinate execution argument access and verification and the
correct output of concurrent script responses.

=cut


our $VERSION = '0.02';

use base qw(Anansi::Component);


=head1 INHERITED METHODS

=cut


=head2 addChannel

Declared in L<Anansi::Component>.  Overridden by this module.

=cut


sub addChannel {
    my ($self, %parameters) = @_;
    return $self->SUPER::addChannel((%parameters));
}


=head2 channel

Declared in L<Anansi::Component>.

=cut


=head2 componentManagers

Declared in L<Anansi::Component>.

=cut


=head2 finalise

    $OBJECT->SUPER::finalise();

    $OBJECT->Anansi::Class::finalise();

Declared as a virtual method in L<Anansi::Class>.  Overridden by this module.

=cut


sub finalise {
    my ($self, %parameters) = @_;
}


=head2 implicate

Declared as a virtual method in L<Anansi::Class>.

=cut


=head2 import

Declared in L<Anansi::Class>.

=cut


=head2 initialise

    $OBJECT->SUPER::initialise();

Declared as a virtual method in L<Anansi::Class>.  Overridden by this module.

=cut


sub initialise {
    my ($self, %parameters) = @_;
}


=head2 old

Declared in L<Anansi::Class>.

=cut


=head2 removeChannel

Declared in L<Anansi::Component>.  Overridden by this module.

=cut


sub removeChannel {
    my ($self, %parameters) = @_;
    return $self->SUPER::removeChannel((%parameters));
}


=head2 used

Declared in L<Anansi::Class>.

=cut


=head2 uses

Declared in L<Anansi::Class>.

=cut


=head1 METHODS

=cut


=head2 validate

    if(1 == Anansi::ScriptComponent::validate($OBJECT, undef));

    if(1 == Anansi::ScriptComponent::channel($OBJECT, 'VALIDATE_AS_APPROPRIATE'));

    if(1 == Anansi::ScriptComponent->validate(undef));

    if(1 == Anansi::ScriptComponent->channel('VALIDATE_AS_APPROPRIATE'));

    if(1 == $OBJECT->validate(undef));

    if(1 == $OBJECT->channel('VALIDATE_AS_APPROPRIATE'));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item channel I<(String, Required)>

The abstract identifier of a subroutine.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Generic validation for whether a Perl script should be handled by a component.
Returns B<1> I<(one)> for yes and B<0> I<(zero)> for no.

=cut


sub validate {
    my ($self, $channel, %parameters) = @_;
    my $package = $self;
    $package = ref($self) if(ref($self) !~ /^$/);
    return 1;
}

Anansi::Component::addChannel('Anansi::ScriptComponent', 'VALIDATE_AS_APPROPRIATE' => 'validate');


=head1 METHODS

=cut


=head1 NOTES

This module is designed to make it simple, easy and quite fast to code your
design in perl.  If for any reason you feel that it doesn't achieve these goals
then please let me know.  I am here to help.  All constructive criticisms are
also welcomed.

=cut


=head1 AUTHOR

Kevin Treleaven <kevin I<AT> treleaven I<DOT> net>

=cut


1;

