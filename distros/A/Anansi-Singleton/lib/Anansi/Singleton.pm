package Anansi::Singleton;


=head1 NAME

Anansi::Singleton - A base module definition where only a single object instance
is allowed.

=head1 SYNOPSIS

    package Anansi::Example;

    use base qw(Anansi::Singleton);

    sub finalise {
        my ($self, %parameters) = @_;
    }

    sub fixate {
        my ($self, %parameters) = @_;
    }

    sub initialise {
        my ($self, %parameters) = @_;
    }

    sub reinitialise {
        my ($self, %parameters) = @_;
    }

    1;

    package main;

    use Anansi::Example;

    my $object = Anansi::Example->new();

    1;

=head1 DESCRIPTION

This is a base module definition that manages the creation and destruction of
module object instances that are not repeatable including embedded objects and
ensures that destruction can only occur when all duplicate object instances are
no longer used.  Uses L<Anansi::Class>, L<Anansi::ObjectManager> and L<base>.

=cut


our $VERSION = '0.08';

use base qw(Anansi::Class);

use Anansi::ObjectManager;


my $NAMESPACE = {};


=head1 METHODS

=cut


=head2 Anansi::Class

See L<Anansi::Class|Anansi::Class> for details.  A parent module of
L<Anansi::Singleton|Anansi::Singleton>.

=cut


=head3 DESTROY

See L<Anansi::Class::DESTROY|Anansi::Class/"DESTROY"> for details.  Overridden
by L<Anansi::Singleton::DESTROY|Anansi::Singleton/"DESTROY">.

=cut


=head3 finalise

See L<Anansi::Class::finalise|Anansi::Class/"finalise"> for details.  A virtual
method.

=cut


=head3 implicate

See L<Anansi::Class::implicate|Anansi::Class/"implicate"> for details.  A
virtual method.

=cut


=head3 import

See L<Anansi::Class::import|Anansi::Class/"import"> for details.

=cut


=head3 initialise

See L<Anansi::Class::initialise|Anansi::Class/"initialise"> for details.  A
virtual method.

=cut


=head3 new

See L<Anansi::Class::new|Anansi::Class/"new"> for details.  Overridden by
L<Anansi::Singleton::new|Anansi::Singleton/"new">.

=cut


=head3 old

See L<Anansi::Class::old|Anansi::Class/"old"> for details.

=cut


=head3 used

See L<Anansi::Class::used|Anansi::Class/"used"> for details.

=cut


=head3 uses

See L<Anansi::Class::uses|Anansi::Class/"uses"> for details.

=cut


=head3 using

See L<Anansi::Class::using|Anansi::Class/"using"> for details.

=cut


=head2 DESTROY

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=back

Overrides L<Anansi::Class::DESTROY|Anansi::Class/"DESTROY">.  Performs module
object instance clean-up actions.  Either calls the
L<fixate|Anansi::Singleton/"fixate"> method prior to dereferencing an instance
of the object where more than one instance exists or the
L<finalise|Anansi::Class/"finalise"> method prior to dereferencing the last
instance.  Indirectly called by the perl interpreter.

=cut


sub DESTROY {
    my ($self) = @_;
    my $objectManager = Anansi::ObjectManager->new();
    if(1 == $objectManager->registrations($self)) {
        $self->finalise();
        $objectManager->obsolete(
            USER => $self,
        );
        $objectManager->unregister($self);
    } elsif(1 < $objectManager->registrations($self)) {
        $self->fixate();
        $objectManager->unregister($self);
    }
}


=head2 fixate

    $OBJECT->fixate();

    $OBJECT->SUPER::fixate();

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

A virtual method.  Called just prior to module instance object destruction where
there are multiple instances of the object remaining.

=cut


sub fixate {
    my ($self, %parameters) = @_;
}


=head2 new

    my $object = Anansi::Example->new();
    my $object = Anansi::Example->new(
        SETTING => 'example',
    );

=over 4

=item class I<(Blessed Hash B<or> String, Required)>

Either an object or a string of this namespace.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

Overrides L<Anansi::Class::new|Anansi::Class/"new">.  Instantiates or
reinstantiates an object instance of a module.  Either calls the
L<initialise|Anansi::Class/"initialise"> method with the supplied I<parameters>
after the object is first instantiated or the
L<reinitialise|Anansi::Singleton/"reinitialise"> method after subsequent
instantiations.

=cut


sub new {
    my ($class, %parameters) = @_;
    return if(ref($class) =~ /^(ARRAY|CODE|FORMAT|GLOB|HASH|IO|LVALUE|REF|Regexp|SCALAR|VSTRING)$/i);
    $class = ref($class) if(ref($class) !~ /^$/);
    if(!defined($NAMESPACE->{$class})) {
        my $self = {
            NAMESPACE => $class,
            PACKAGE => __PACKAGE__,
        };
        $NAMESPACE->{$class} = bless($self, $class);
        my $objectManager = Anansi::ObjectManager->new();
        $objectManager->register($NAMESPACE->{$class});
        $NAMESPACE->{$class}->initialise(%parameters);
    } else {
        my $objectManager = Anansi::ObjectManager->new();
        $objectManager->register($NAMESPACE->{$class});
        $NAMESPACE->{$class}->reinitialise(%parameters);
    }
    return $NAMESPACE->{$class};
}


=head2 reinitialise

    $OBJECT->reinitialise();

    $OBJECT->SUPER::reinitialise();

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item parameters I<(Hash, Optional)>

Named parameters.

=back

A virtual method.  Called just after module instance object recreation.

=cut


sub reinitialise {
    my ($self, %parameters) = @_;
}


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
