package Anansi::Component;


=head1 NAME

Anansi::Component - A base module definition for related processes that are managed.

=head1 SYNOPSIS

    package Anansi::ComponentManagerExample::ComponentExample;

    use base qw(Anansi::Component);

    sub validate {
        return 1;
    }

    sub doSomething {
        my ($self, $channel, %parameters) = @_;
    }

    Anansi::Component::addChannel(
        'Anansi::ComponentManagerExample::ComponentExample',
        'VALIDATE_AS_APPROPRIATE' => Anansi::ComponentManagerExample::ComponentExample->validate
    );
    Anansi::Component::addChannel(
        'Anansi::ComponentManagerExample::ComponentExample',
        'SOME_COMPONENT_CHANNEL' => Anansi::ComponentManagerExample::ComponentExample->doSomething
    );

    1;

    package Anansi::ComponentManagerExample;

    use base qw(Anansi::ComponentManager);

    sub doSomethingElse {
        my ($self, $channel, %parameters) = @_;
    }

    Anansi::ComponentManager::addChannel(
        'Anansi::ComponentManagerExample',
        'SOME_MANAGER_CHANNEL' => Anansi::ComponentManagerExample->doSomethingElse
    );

    1;

    package main;

    use Anansi::ComponentManagerExample;

    my $object = Anansi::ComponentManagerExample->new();
    my $component = $object->addComponent();
    my $result = $object->channel(
        $component,
        'SOME_COMPONENT_CHANNEL',
        someParameter => 'some data',
    );

    1;

=head1 DESCRIPTION

This is a base module definition for related functionality modules.  This module
provides the mechanism to be handled by a L<Anansi::ComponentManager> module.
In order to simplify the recognition and management of related I<component>
modules, each component is required to have the same base namespace as it's
manager.  Uses L<Anansi::Actor|Anansi::Actor>.

=cut


our $VERSION = '0.07';

use base qw(Anansi::Class);

use Anansi::Actor;


my %CHANNELS;


=head1 METHODS

=cut


=head2 Anansi::Class

See L<Anansi::Class|Anansi::Class> for details.  A parent module of L<Anansi::Component|Anansi::Component>.

=cut


=head3 DESTROY

See L<Anansi::Class::DESTROY|Anansi::Class/"DESTROY"> for details.

=cut


=head3 finalise

See L<Anansi::Class::finalise|Anansi::Class/"finalise"> for details.  A virtual method.

=cut


=head3 implicate

See L<Anansi::Class::implicate|Anansi::Class/"implicate"> for details.  A virtual method.

=cut


=head3 import

See L<Anansi::Class::import|Anansi::Class/"import"> for details.

=cut


=head3 initialise

See L<Anansi::Class::initialise|Anansi::Class/"initialise"> for details.  A virtual method.

=cut


=head3 new

See L<Anansi::Class::new|Anansi::Class/"new"> for details.

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


=head2 addChannel

    if(1 == Anansi::Component->addChannel(
        someChannel => 'Some::subroutine',
        anotherChannel => Some::subroutine,
        yetAnotherChannel => $AN_OBJECT->someSubroutine,
        etcChannel => sub {
            my $self = shift(@_);
        }
    ));

    if(1 == $OBJECT->addChannel(
        someChannel => 'Some::subroutine',
        anotherChannel => Some::subroutine,
        yetAnotherChannel => $AN_OBJECT->someSubroutine,
        etcChannel => sub {
            my $self = shift(@_);
        }
    ));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

An object or string of this namespace.

=item parameters I<(Hash, Optional)>

Named parameters where the key is the name of the channel and the value is
either a namespace string or code reference to an existing subroutine or an
anonymous subroutine definition.

=back

Defines the responding subroutine for the named component channels.

=cut


sub addChannel {
    my ($self, %parameters) = @_;
    my $package = $self;
    $package = ref($self) if(ref($self) !~ /^$/);
    return 0 if(0 == scalar(keys(%parameters)));
    foreach my $key (keys(%parameters)) {
        if(ref($key) !~ /^$/) {
            return 0;
        } elsif(ref($parameters{$key}) =~ /^CODE$/i) {
        } elsif(ref($parameters{$key}) !~ /^$/) {
            return 0;
        } elsif($parameters{$key} =~ /^[a-zA-Z]+[a-zA-Z0-9_]*(::[a-zA-Z]+[a-zA-Z0-9_]*)*$/) {
            if(exists(&{$parameters{$key}})) {
            } elsif(exists(&{$package.'::'.$parameters{$key}})) {
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }
    $CHANNELS{$package} = {} if(!defined($CHANNELS{$package}));
    foreach my $key (keys(%parameters)) {
        if(ref($parameters{$key}) =~ /^CODE$/i) {
            ${$CHANNELS{$package}}{$key} = sub {
                my ($self, $channel, @PARAMETERS) = @_;
                return &{$parameters{$key}}($self, $channel, (@PARAMETERS));
            };
        } elsif($parameters{$key} =~ /^[a-zA-Z]+[a-zA-Z0-9_]*(::[a-zA-Z]+[a-zA-Z0-9_]*)*$/) {
            if(exists(&{$parameters{$key}})) {
                ${$CHANNELS{$package}}{$key} = sub {
                    my ($self, $channel, @PARAMETERS) = @_;
                    return &{\&{$parameters{$key}}}($self, $channel, (@PARAMETERS));
                };
            } else {
                ${$CHANNELS{$package}}{$key} = sub {
                    my ($self, $channel, @PARAMETERS) = @_;
                    return &{\&{$package.'::'.$parameters{$key}}}($self, $channel, (@PARAMETERS));
                };
            }
        }
    }
    return 1;
}


=head2 channel

    Anansi::Component->channel('Anansi::Component::Example');

    $OBJECT->channel();

    Anansi::Component->channel(
        'Anansi::Component::Example',
        'someChannel',
        someParameter => 'something'
    );

    $OBJECT->channel(
        'someChannel',
        someParameter => 'something'
    );

Has a floating first parameter, dependant on how the subroutine is called.

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

An object or string of this namespace.

=item channel I<(String, Optional)>

The name of the channel to pass control to.

=item parameters I<(Scalar B<or> Array B<or> Hash, Optional)>

The parameters to pass to the channel.

=back

Either returns an array of the available channels or passes the supplied
parameters to the named channel.  Returns B<undef> on error.

=cut


sub channel {
    my $self = shift(@_);
    $self = shift(@_) if('Anansi::Component' eq $self);
    my $package = $self;
    $package = ref($self) if(ref($self) !~ /^$/);
    if(0 == scalar(@_)) {
        return [] if(!defined($CHANNELS{$package}));
        return [( keys(%{$CHANNELS{$package}}) )];
    }
    my ($channel, @parameters) = @_;
    return if(ref($channel) !~ /^$/);
    return if(!defined($CHANNELS{$package}));
    return if(!defined(${$CHANNELS{$package}}{$channel}));
    return &{${$CHANNELS{$package}}{$channel}}($self, $channel, (@parameters));
}


=head2 componentManagers

    my $managers = Anansi::Component->componentManagers();

    my $managers = Anansi::Component::componentManagers('Anansi::ComponentManagerExample::ComponentExample');

    my $managers = $OBJECT->componentManagers();

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

An object or string of this namespace.

=back

Either returns an ARRAY of all of the available component managers or an ARRAY
containing the current component's manager.

=cut


sub componentManagers {
    my ($self, %parameters) = @_;
    my $package = $self;
    $package = ref($package) if(ref($package) !~ /^$/);
    if('Anansi::Component' eq $package) {
        my %modules = Anansi::Actor->modules();
        my @managers;
        foreach my $module (keys(%modules)) {
            next if('Anansi::ComponentManager' eq $module);
            require $modules{$module};
            next if(!eval { $module->isa('Anansi::ComponentManager') });
            push(@managers, $module);
        }
        return [(@managers)];
    }
    my @namespaces = split(/::/, $package);
    return [] if(scalar(@namespaces) < 2);
    pop(@namespaces);
    my $namespace = join('::', @namespaces);
    my $filename = join('/', @namespaces).'.pm';
    require $filename;
    return [] if(!eval { $namespace->isa('Anansi::ComponentManager') });
    return [$namespace];
}


=head2 removeChannel

    if(1 == Anansi::Component::removeChannel(
        'Anansi::ComponentManagerExample::ComponentExample',
        'someChannel',
        'anotherChannel',
        'yetAnotherChannel',
        'etcChannel'
    ));

    if(1 == $OBJECT->removeChannel(
        'someChannel',
        'anotherChannel',
        'yetAnotherChannel',
        'etcChannel'
    ));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

An object or string of this namespace.

=item parameters I<(String B<or> Array, Required)>

A string or array of strings containing the name of a channel.

=back

Undefines the responding subroutine for the named component channels.  Returns
B<1> I<(one)> on success or B<0> I<(zero)> on failure.

=cut


sub removeChannel {
    my ($self, @parameters) = @_;
    my $package = $self;
    $package = ref($self) if(ref($self) !~ /^$/);
    return 0 if(0 == scalar(@parameters));
    return 0 if(!defined($CHANNELS{$package}));
    foreach my $key (@parameters) {
        return 0 if(!defined(${$CHANNELS{$package}}{$key}));
    }
    foreach my $key (@parameters) {
        delete ${$CHANNELS{$package}}{$key};
    }
    return 1;
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
