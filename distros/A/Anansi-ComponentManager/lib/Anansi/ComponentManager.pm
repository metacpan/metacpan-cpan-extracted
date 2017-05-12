package Anansi::ComponentManager;


=head1 NAME

Anansi::ComponentManager - A base module definition for related process management.

=head1 SYNOPSIS

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

    package Anansi::ComponentManagerExample::ComponentExample;

    use base qw(Anansi::Component);

    sub priority {
        my ($self, $channel, %parameters) = @_;
        my $PRIORITY = {
            'Anansi::ComponentManagerExample::AnotherComponentExample' => 'HIGHER',
            'Anansi::ComponentManagerExample::YetAnotherComponentExample' => 'LOWER',
            'Anansi::ComponentManagerExample::SomeOtherComponentExample' => 'SAME',
            'Anansi::ComponentManagerExample::ADifferentComponentExample' => 1,
            'Anansi::ComponentManagerExample::EtcComponentExample' => 0,
            'Anansi::ComponentManagerExample::AndSoOnComponentExample' => -1,
        };
        return $PRIORITY;
    }

    sub validate {
        my ($self, $channel, %parameters) = @_;
        return 1;
    }

    sub doSomething {
        my ($self, $channel, %parameters) = @_;
    }

    Anansi::Component::addChannel(
        'Anansi::ComponentManagerExample::ComponentExample',
        'PRIORITY_OF_VALIDATE' => Anansi::ComponentManagerExample::ComponentExample->priority
    );
    Anansi::Component::addChannel(
        'Anansi::ComponentManagerExample::ComponentExample',
        'VALIDATE_AS_APPROPRIATE' => Anansi::ComponentManagerExample::ComponentExample->validate
    );
    Anansi::Component::addChannel(
        'Anansi::ComponentManagerExample::ComponentExample',
        'SOME_COMPONENT_CHANNEL' => Anansi::ComponentManagerExample::ComponentExample->doSomething
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
        anotherParameter => 'some more data',
    );

    my $another = Anansi::ComponentManagerExample->new(
        IDENTIFICATION => 'Another component',
    );
    $result = $object->channel(
        'Another component',
        'SOME_COMPONENT_CHANNEL',
        aParameter => 'more data?',
    );

    1;

=head1 DESCRIPTION

This is a base module definition for the management of modules that deal with
related functionality.  This management module provides the mechanism to handle
multiple related functionality modules at the same time, loading and creating an
object of the most appropriate module to handle each situation by using the
VALIDATE_AS_APPROPRIATE and PRIORITY_OF_VALIDATE component channels.  In order
to simplify the recognition of related L<Anansi::Component> modules, each
component is required to have the same base namespace as it's manager.

=cut


our $VERSION = '0.10';

use base qw(Anansi::Singleton);

use Anansi::Actor;

my %CHANNELS;
my %COMPONENTS;
my %IDENTIFICATIONS;
my %PRIORITIES;


=head1 METHODS

=cut


=head2 Anansi::Class

See L<Anansi::Class|Anansi::Class> for details.  A parent module of L<Anansi::Singleton|Anansi::Singleton>.

=cut


=head3 DESTROY

See L<Anansi::Class::DESTROY|Anansi::Class/"DESTROY"> for details.  Overridden by L<Anansi::Singleton::DESTROY|Anansi::Singleton/"DESTROY">.

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

See L<Anansi::Class::initialise|Anansi::Class/"initialise"> for details.  Overridden by L<Anansi::ComponentManager::initialise|Anansi::ComponentManager/"initialise">.  A virtual method.

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


=head2 Anansi::Singleton

See L<Anansi::Singleton|Anansi::Singleton> for details.  A parent module of L<Anansi::ComponentManager|Anansi::ComponentManager>.

=cut


=head3 Anansi::Class

See L<Anansi::Class|Anansi::Class> for details.  A parent module of L<Anansi::Singleton|Anansi::Singleton>.

=cut


=head3 DESTROY

See L<Anansi::Singleton::DESTROY|Anansi::Singleton/"DESTROY"> for details.  Overrides L<Anansi::Class::DESTROY|Anansi::Class/"DESTROY">.

=cut


=head3 fixate

See L<Anansi::Singleton::fixate|Anansi::Singleton/"fixate"> for details.  A virtual method.

=cut


=head3 new

See L<Anansi::Singleton::new|Anansi::Singleton/"new"> for details.  Overrides L<Anansi::Class::new|Anansi::Class/"new">.

=cut


=head3 reinitialise

See L<Anansi::Singleton::reinitialise|Anansi::Singleton/"reinitialise"> for details.  Overridden by L<Anansi::ComponentManager::reinitialise|Anansi::ComponentManager/"reinitialise">.  A virtual method.

=cut


=head2 addChannel

    if(1 == Anansi::ComponentManager->addChannel(
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

Either an object or a string of this namespace.

=item parameters I<(Hash, Required)>

Named parameters where the key is the name of the channel and the value is
either a namespace string or code reference to an existing subroutine or an
anonymous subroutine definition.

=back

Defines the responding subroutine for the named component manager channels.

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


=head2 addComponent

    my $identification = Anansi::ComponentManager->addComponent(
        undef,
        someParameter => 'some value'
    );
    if(defined($identification));

    my $identification = $OBJECT->addComponent(
        undef,
        someParameter => 'some value'
    );
    if(defined($identification));

    my $identification = Anansi::ComponentManager->addComponent(
        'some identifier',
        someParameter => 'some value'
    );
    if(defined($identification));

    my $identification = $OBJECT->addComponent(
        'some identifier',
        someParameter => 'some value'
    );
    if(defined($identification));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

An object or string of this namespace.

=item identification I<(String, Required)>

The name to associate with the component.

=item parameters I<(Scalar B<or> Array, Optional)>

The list of parameters to pass to the I<VALIDATE_AS_APPROPRIATE> channel of
every component module found on the system.

=back

Creates a new component object and stores the object for indirect interaction by
the implementer of the component manager.  A unique identifier for the object
may either be supplied or automatically generated and is returned as a means of
referencing the object.

Note: The process of selecting the component to use requires each component to
validate it's own appropriateness.  Therefore this process makes use of a
VALIDATE_AS_APPROPRIATE component channel which is expected to return either a
B<1> I<(one)> or a B<0> I<(zero)> representing B<appropriate> or
B<inappropriate>.  If this component channel does not exist it is assumed that
the component is not designed to be implemented in this way.  A component may
also provide a PRIORITY_OF_VALIDATE component channel to aid in validating where
multiple components may be appropriate to different degrees.  If this component
channel does not exist it is assumed that the component has the lowest priority.

=cut


sub addComponent {
    my ($self, $identification, @parameters) = @_;
    my $package = $self;
    $package = ref($self) if(ref($self) !~ /^$/);
    if(!defined($identification)) {
        $identification = $self->componentIdentification();
    } elsif(ref($identification) !~ /^$/) {
        return;
    } elsif($identification =~ /^\s*$/) {
        return;
    } elsif(defined($COMPONENTS{$package})) {
        return $identification if(defined(${$COMPONENTS{$package}}{$identification}));
        my %reverse = map { ${$COMPONENTS{$package}}{$_} => $_ } (keys(%{$COMPONENTS{$package}}));
        return $reverse{$identification} if(defined($reverse{$identification}));
        return if(defined($IDENTIFICATIONS{$identification}));
        %reverse = map { $IDENTIFICATIONS{$_} => $_ } (keys(%IDENTIFICATIONS));
        return if(defined($reverse{$identification}));
    }
    my $alias = '';
    if($identification !~ /^\d{20}$/) {
        $alias = $identification;
        $identification = $self->componentIdentification();
    }
    my $components = $self->components();
    return if(ref($components) !~ /^ARRAY$/i);
    my $priority = $self->priorities(
        PARAMETERS => [(@parameters)],
    );
    return if(!defined($priority));
    my $OBJECT;
    while(0 <= $priority) {
        my $components = $self->priorities(
            PRIORITY => $priority,
        );
        next if(!defined($components));
        next if(ref($components) !~ /^ARRAY$/i);
        foreach my $component (@{$components}) {
            my $valid = &{\&{'Anansi::Component::channel'}}($component, 'VALIDATE_AS_APPROPRIATE', (@parameters));
            next if(!defined($valid));
            if($valid) {
                $OBJECT = Anansi::Actor->new(PACKAGE => $component, (@parameters));
                last;
            }
        }
        last if(defined($OBJECT));
        $priority--;
    }
    return if(!defined($OBJECT));
    $COMPONENTS{$package} = {} if(!defined($COMPONENTS{$package}));
    ${$COMPONENTS{$package}}{$identification} = $OBJECT;
    $self->uses(
        'COMPONENT_'.$identification => $OBJECT,
    );
    $IDENTIFICATIONS{$identification} = $alias;
    return $identification;
}


=head2 channel

    Anansi::ComponentManager->channel('Anansi::ComponentManager::Example');

    $OBJECT->channel();

    Anansi::ComponentManager->channel(
        'Anansi::ComponentManager::Example',
        'someChannel',
        someParameter => 'something'
    );

    $OBJECT->channel('someChannel', someParameter => 'something');

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

An object or string of this namespace.

=item channel I<(String, Optional)>

The name that is associated with the component's channel.

=item parameters I<(Scalar B<or> Array, Optional)>

The list of parameters to pass to the component's channel.

=back

Either returns an array of the available channels or passes the supplied
parameters to the named channel.  Returns B<undef> on error.

=cut


sub channel {
    my $self = shift(@_);
    $self = shift(@_) if('Anansi::ComponentManager' eq $self);
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


=head2 component

    my $returned;
    my $channels = Anansi::ComponentManager->component($component);
    if(defined($channels)) {
        foreach my $channel (@{$channels}) {
            next if('SOME_CHANNEL' ne $channel);
            $returned = Anansi::ComponentManager->component(
                $component,
                $channel,
                anotherParameter => 'another value'
            );
        }
    }

    my @returned;
    $OBJECT->addComponent(undef, someParameter => 'some value');
    my $components = $OBJECT->component();
    if(defined($components)) {
        foreach my $component (@{$components}) {
            my $channels = $OBJECT->component($component);
            if(defined($channels)) {
                foreach my $channel (@{$channels}) {
                    next if('SOME_CHANNEL' ne $channel);
                    push(@returned, $OBJECT->component(
                        $component,
                        $channel,
                        anotherParameter => 'another value'
                    ));
                }
            }
        }
    }

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

An object or string of this namespace.

=item identification I<(String, Optional)>

The name associated with the component.

=item channel I<(String, Optional)>

The name that is associated with the component's channel.

=item parameters I<(Scalar B<or> Array, Optional)>

The list of parameters to pass to the component's channel.

=back

Either returns an array of all of the available components or an array of all
of the channels available through an identified component or interacts with an
identified component using one of it's channels.  Returns an B<undef> on
failure.

=cut


sub component {
    my $self = shift(@_);
    my $package = $self;
    $package = ref($self) if(ref($self) !~ /^$/);
    return if(!defined($COMPONENTS{$package}));
    my %reverse = map { $IDENTIFICATIONS{$_} => $_ } (keys(%IDENTIFICATIONS));
    if(0 == scalar(@_)) {
        my @identifications;
        foreach my $identification (keys(%{$COMPONENTS{$package}})) {
            if(defined($IDENTIFICATIONS{$identification})) {
                push(@identifications, $identification);
            } elsif(defined($reverse{$identification})) {
                push(@identifications, $reverse{$identification});
            }
        }
        return [( @identifications )];
    }
    my $identification = shift(@_);
    return if(!defined($identification));
    my $OBJECT;
    if(defined(${$COMPONENTS{$package}}{$identification})) {
        $OBJECT = ${$COMPONENTS{$package}}{$identification};
    } elsif(defined(${$COMPONENTS{$package}}{$reverse{$identification}})) {
        $OBJECT = ${$COMPONENTS{$package}}{$reverse{$identification}};
    } else {
        return;
    }
    return $OBJECT->channel() if(0 == scalar(@_));
    my ($channel, @parameters) = @_;
    return $OBJECT->channel($channel, (@parameters));
}


=head2 componentIdentification

    my $identification = Anansi::ComponentManager->componentIdentification();

    my $alias = 'An identifying phrase';
    my $identification = $OBJECT->componentIdentification($alias);
    if(defined($identification)) {
        print 'The "'.$alias.'" component already exists with the "'.$identification.'" identification.'."\n";
    }

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item identification I<(String, Optional)>

A component identification.

=back

Either generates a volatile B<20> I<(twenty)> digit identification string that
is unique within the executing script or determines whether a component exists
with the specified I<identification>.  Returns the unique identification string
on success or an B<undef> on failure.

=cut


sub componentIdentification {
    my ($self, $identification) = @_;
    my %reverse = map { $IDENTIFICATIONS{$_} => $_ } (keys(%IDENTIFICATIONS));
    if(!defined($identification)) {
        my ($second, $minute, $hour, $day, $month, $year) = localtime(time);
        my $random;
        do {
            $random = int(rand(1000000));
            $identification = sprintf("%4d%02d%02d%02d%02d%02d%06d", $year + 1900, $month, $day, $hour, $minute, $second, $random);
        } while(defined($IDENTIFICATIONS{$identification}));
    } elsif(ref($identification) !~ /^$/) {
        return;
    } elsif($identification =~ /^\s*$/) {
        return;
    } elsif(defined($IDENTIFICATIONS{$identification})) {
    } elsif(defined($reverse{$identification})) {
        return $reverse{$identification};
    } else {
        return;
    }
    return $identification;
}


=head2 components

    my $components = Anansi::ComponentManager->components();
    if(ref($components) =~ /^ARRAY$/i) {
        foreach my $component (@{$components}) {
        }
    }

    my $components = Anansi::ComponentManager::components('Some::Namespace');
    if(ref($components) =~ /^ARRAY$/i) {
        foreach my $component (@{$components}) {
        }
    }

    my $components = $OBJECT->components();
    if(ref($components) =~ /^ARRAY$/i) {
        foreach my $component (@{$components}) {
        }
    }

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

An object or string of this namespace.

=back

Either returns an array of all of the available components or an array
containing the current component manager's components.

=cut


sub components {
    my $self = shift(@_);
    my $package = $self;
    $package = ref($package) if(ref($package) !~ /^$/);
    my %modules = Anansi::Actor->modules();
    my @components;
    if('Anansi::ComponentManager' eq $package) {
        foreach my $module (keys(%modules)) {
            next if('Anansi::Component' eq $module);
            require $modules{$module};
            next if(!eval { $module->isa('Anansi::Component') });
            push(@components, $module);
        }
        return [(@components)];
    }
    my @namespaces = split(/::/, $package);
    my $namespace = join('::', @namespaces).'::';
    foreach my $module (keys(%modules)) {
        next if($module !~ /^${namespace}[^:]+$/);
        require $modules{$module};
        next if(!eval { $module->isa('Anansi::Component') });
        push(@components, $module);
    }
    return [(@components)];
}


=head2 initialise

Overrides L<Anansi::Class::initialise|Anansi::Class/"initialise">.

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item parameters I<(Hash, Optional)>

Named parameters supplied to the L<Anansi::Singleton::new|Anansi::Singleton/"new"> method.

=over 4

=item IDENTIFICATION I<(String, Optional)>

A unique component identification.

=back

=back

Enables the conglomeration of L<Anansi::Singleton::new|Anansi::Singleton/"new">
and L<Anansi::ComponentManager::addComponent|Anansi::ComponentManager/"addComponent">
through a specified I<IDENTIFICATION> parameter.  Called just after module
instance object creation.

=cut


sub initialise {
    my ($self, %parameters) = @_;
    if(defined($parameters{IDENTIFICATION})) {
        my $identification = $parameters{IDENTIFICATION};
        if(!defined($self->componentIdentification($identification))) {
            delete $parameters{IDENTIFICATION};
            $self->addComponent(
                $identification,
                %parameters
            );
        }
    }
}


=head2 priorities

    my $priorities = $self->priorities();
    if(defined($priorities)) {
        for(my $priority = $priorities; -1 < $priority; $priority--) {
            my $components = $self->priorities(
                PRIORITY => $priority,
            );
            next if(!defined($components));
            foreach my $component (@{$components}) {
            }
        }
    }

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

An object or string of this namespace.

=item parameters I<(Hash, Optional)>

Named parameters.

=over 4

=item PARAMETERS I<(Array B<or> Scalar, Optional)>

An array or single value containing the parameters to pass to the
PRIORITY_OF_VALIDATE component channel.

=item PRIORITY I<(String, Optional)>

Either a component namespace or a priority value of B<0> I<(zero)> or greater
where B<0> I<(zero)> represents the lowest priority.

=back

=back

Either returns the highest component priority, the list of all the component
namespaces that have the component priority supplied as the I<PRIORITY>
parameter or the component priority of the component given it's namespace
supplied as the I<PRIORITY> parameter.

=cut


sub priorities {
    my ($self, %parameters) = @_;
    my $package = $self;
    $package = ref($package) if(ref($package) !~ /^$/);
    return if('Anansi::ComponentManager' eq $package);

    my %components;

    sub priorities_component {
        my (%parameters) = @_;
        return if(!defined($parameters{COMPONENT}));
        return if(ref($parameters{COMPONENT}) !~ /^$/);
        return if($parameters{COMPONENT} =~ /^\s*$/);
        if(!defined($components{$parameters{COMPONENT}})) {
            $components{$parameters{COMPONENT}} = {
                HIGHER => {},
                LOWER => {},
                SAME => {},
            };
        }
        my $prioritise = &{\&{'Anansi::Component::channel'}}($parameters{COMPONENT}, 'PRIORITY_OF_VALIDATE', (@{$parameters{PARAMETERS}}));
        return if(!defined($prioritise));
        return if(ref($prioritise) !~ /^HASH$/i);
        while(my ($componentName, $componentPriority) = each(%{$prioritise})) {
            next if(!defined($componentName));
            next if(!defined($componentPriority));
            next if(ref($componentPriority) !~ /^$/);
            if($componentPriority =~ /^\s*LOWER\s*/i) {
                $componentPriority = -1;
            } elsif($componentPriority =~ /^\s*HIGHER\s*/i) {
                $componentPriority = 1;
            } elsif($componentPriority =~ /^\s*SAME\s*/i) {
                $componentPriority = 0;
            }
            next if($componentPriority !~ /^\s*(|\-|\+)\d+\s*$/);
            if($componentPriority < 0) {
                priorities_prioritise(
                    HIGHER => $parameters{COMPONENT},
                    LOWER => $componentName,
                );
            } elsif(0 < $componentPriority) {
                priorities_prioritise(
                    HIGHER => $componentName,
                    LOWER => $parameters{COMPONENT},
                );
            } else {
                priorities_prioritise(
                    SAME => [($parameters{COMPONENT}, $componentName)],
                );
            }
        }
    }

    sub priorities_higher {
        my (%parameters) = @_;
        return if(!defined($parameters{HIGHER}));
        return if(ref($parameters{HIGHER}) !~ /^$/);
        return if($parameters{HIGHER} =~ /^\s*$/);
        return if(!defined($parameters{COMPONENT}));
        return if(ref($parameters{COMPONENT}) !~ /^$/);
        return if($parameters{COMPONENT} =~ /^\s*$/);
        if(!defined($components{$parameters{COMPONENT}})) {
            $components{$parameters{COMPONENT}} = {
                HIGHER => {},
                LOWER => {},
                SAME => {},
            };
        }
        if(!defined($components{$parameters{HIGHER}})) {
            $components{$parameters{HIGHER}} = {
                HIGHER => {},
                LOWER => {},
                SAME => {},
            };
        }
        my $isHigher = 1;
        foreach my $lower (keys(%{${$components{$parameters{COMPONENT}}}{LOWER}})) {
            next if(defined(${${$components{$lower}}{HIGHER}}{$parameters{HIGHER}}));
            if(defined(${${$components{$lower}}{SAME}}{$parameters{HIGHER}})) {
                $isHigher = 0;
                next;
            }
            ${${$components{$parameters{HIGHER}}}{LOWER}}{$lower} = 0;
            ${${$components{$lower}}{HIGHER}}{$parameters{HIGHER}} = 0;
            my $wasHigher = priorities_higher(
                COMPONENT => $lower,
                HIGHER => $parameters{HIGHER},
            );
            if(!defined($wasHigher)) {
            } elsif(0 == $wasHigher) {
                priorities_same(
                    COMPONENT => $parameters{HIGHER},
                    SAME => $lower,
                );
                $isHigher = 0;
            }
        }
        return isHigher;
    }

    sub priorities_lower {
        my (%parameters) = @_;
        return if(!defined($parameters{COMPONENT}));
        return if(ref($parameters{COMPONENT}) !~ /^$/);
        return if($parameters{COMPONENT} =~ /^\s*$/);
        return if(!defined($parameters{LOWER}));
        return if(ref($parameters{LOWER}) !~ /^$/);
        return if($parameters{LOWER} =~ /^\s*$/);
        if(!defined($components{$parameters{COMPONENT}})) {
            $components{$parameters{COMPONENT}} = {
                HIGHER => {},
                LOWER => {},
                SAME => {},
            };
        }
        if(!defined($components{$parameters{LOWER}})) {
            $components{$parameters{LOWER}} = {
                HIGHER => {},
                LOWER => {},
                SAME => {},
            };
        }
        my $isLower = 1;
        foreach my $higher (keys(%{${$components{$parameters{COMPONENT}}}{HIGHER}})) {
            next if(defined(${${$components{$higher}}{LOWER}}{$parameters{LOWER}}));
            if(defined(${${$components{$higher}}{SAME}}{$parameters{LOWER}})) {
                $isLower = 0;
                next;
            }
            ${${$components{$higher}}{LOWER}}{$parameters{LOWER}} = 0;
            ${${$components{$parameters{LOWER}}}{HIGHER}}{$higher} = 0;
            my $wasLower = priorities_lower(
                COMPONENT => $higher,
                LOWER => $parameters{LOWER},
            );
            if(!defined($wasLower)) {
            } elsif(0 == $wasLower) {
                priorities_same(
                    COMPONENT => $parameters{LOWER},
                    SAME => $higher,
                );
                $isLower = 0;
            }
        }
        return isLower;
    }

    sub priorities_prioritise {
        my (%parameters) = @_;
        if(defined($parameters{SAME})) {
            return if(ref($parameters{SAME}) !~ /^ARRAY$/i);
            foreach my $component (@{$parameters{SAME}}) {
                return if(ref($component) !~ /^$/);
                return if($component =~ /^\s*$/);
            }
            for(my $index = 1; $index < scalar(@{$parameters{SAME}}); $index++) {
                next if(${$parameters{SAME}}[0] eq ${$parameters{SAME}}[$index]);
                priorities_same(
                    COMPONENT => ${$parameters{SAME}}[0],
                    SAME => ${$parameters{SAME}}[$index],
                );
            }
        } elsif(!defined($parameters{HIGHER})) {
            return;
        } elsif(ref($parameters{HIGHER}) !~ /^$/) {
            return;
        } elsif($parameters{HIGHER} =~ /^\s*$/) {
            return;
        } elsif(!defined($parameters{LOWER})) {
            return;
        } elsif(ref($parameters{LOWER}) !~ /^$/) {
            return;
        } elsif($parameters{LOWER} =~ /^\s*$/) {
            return;
        } elsif($parameters{HIGHER} eq $parameters{LOWER}) {
            return;
        } else {
            if(!defined($components{$parameters{HIGHER}})) {
                $components{$parameters{HIGHER}} = {
                    HIGHER => {},
                    LOWER => {},
                    SAME => {},
                };
            }
            if(!defined($components{$parameters{LOWER}})) {
                $components{$parameters{LOWER}} = {
                    HIGHER => {},
                    LOWER => {},
                    SAME => {},
                };
            }
            if(${${$components{$parameters{HIGHER}}}{LOWER}}{$parameters{LOWER}}) {
                return;
            } elsif(${${$components{$parameters{HIGHER}}}{HIGHER}}{$parameters{LOWER}}) {
                priorities_same(
                    COMPONENT => $parameters{LOWER},
                    SAME => $parameters{HIGHER},
                );
            } else {
                ${${$components{$parameters{HIGHER}}}{LOWER}}{$parameters{LOWER}} = 0;
                ${${$components{$parameters{LOWER}}}{HIGHER}}{$parameters{HIGHER}} = 0;
                my $wasLower = priorities_lower(
                    COMPONENT => $parameters{HIGHER},
                    LOWER => $parameters{LOWER},
                );
                my $wasHigher = priorities_higher(
                    COMPONENT => $parameters{LOWER},
                    HIGHER => $parameters{HIGHER},
                );
            }
        }
    }

    sub priorities_same {
        my (%parameters) = @_;
        return if(!defined($parameters{COMPONENT}));
        return if(ref($parameters{COMPONENT}) !~ /^$/);
        return if($parameters{COMPONENT} =~ /^\s*$/);
        return if(!defined($parameters{SAME}));
        return if(ref($parameters{SAME}) !~ /^$/);
        return if($parameters{SAME} =~ /^\s*$/);
        return if($parameters{COMPONENT} eq $parameters{SAME});
        if(!defined($components{$parameters{COMPONENT}})) {
            $components{$parameters{COMPONENT}} = {
                HIGHER => {},
                LOWER => {},
                SAME => {},
            };
        }
        if(!defined($components{$parameters{SAME}})) {
            $components{$parameters{SAME}} = {
                HIGHER => {},
                LOWER => {},
                SAME => {},
            };
        }
        if(defined(${${$components{$parameters{COMPONENT}}}{LOWER}}{$parameters{SAME}})) {
            delete ${${$components{$parameters{COMPONENT}}}{LOWER}}{$parameters{SAME}};
            delete ${${$components{$parameters{SAME}}}{HIGHER}}{$parameters{COMPONENT}};
        }
        if(defined(${${$components{$parameters{COMPONENT}}}{HIGHER}}{$parameters{SAME}})) {
            delete ${${$components{$parameters{SAME}}}{LOWER}}{$parameters{COMPONENT}};
            delete ${${$components{$parameters{COMPONENT}}}{HIGHER}}{$parameters{SAME}};
        }
        if(!defined(${${$components{$parameters{COMPONENT}}}{SAME}}{$parameters{SAME}})) {
            ${${$components{$parameters{COMPONENT}}}{SAME}}{$parameters{SAME}} = 0;
            ${${$components{$parameters{SAME}}}{SAME}}{$parameters{COMPONENT}} = 0;
            foreach my $component (keys(%{${$components{$parameters{COMPONENT}}}{SAME}})) {
                next if($component eq $parameters{SAME});
                next if(defined(${${$components{$component}}{SAME}}{$parameters{SAME}}));
                if(defined(${${$components{$component}}{LOWER}}{$parameters{SAME}})) {
                    delete ${${$components{$component}}{LOWER}}{$parameters{SAME}};
                    delete ${${$components{$parameters{SAME}}}{HIGHER}}{$component};
                } elsif(defined(${${$components{$component}}{HIGHER}}{$parameters{SAME}})) {
                    delete ${${$components{$parameters{SAME}}}{LOWER}}{$component};
                    delete ${${$components{$component}}{HIGHER}}{$parameters{SAME}};
                }
                ${${$components{$component}}{SAME}}{$parameters{SAME}} = 0;
                ${${$components{$parameters{SAME}}}{SAME}}{$component} = 0;
                foreach my $lower (keys(%{${$components{$component}}{LOWER}})) {
                    next if(defined(${$components{$parameters{SAME}}}{$lower}));
                    priorities_lower(
                        COMPONENT => $parameters{SAME},
                        LOWER => $lower,
                    );
                }
                foreach my $higher (keys(%{${$components{$component}}{HIGHER}})) {
                    next if(defined(${$components{$parameters{SAME}}}{$higher}));
                    priorities_higher(
                        COMPONENT => $parameters{SAME},
                        HIGHER => $higher,
                    );
                }
            }
            foreach my $component (keys(%{${$components{$parameters{SAME}}}{SAME}})) {
                next if($component eq $parameters{COMPONENT});
                next if(defined(${${$components{$component}}{SAME}}{$parameters{COMPONENT}}));
                if(defined(${${$components{$component}}{LOWER}}{$parameters{COMPONENT}})) {
                    delete ${${$components{$component}}{LOWER}}{$parameters{COMPONENT}};
                    delete ${${$components{$parameters{COMPONENT}}}{HIGHER}}{$component};
                } elsif(defined(${${$components{$component}}{HIGHER}}{$parameters{COMPONENT}})) {
                    delete ${${$components{$parameters{COMPONENT}}}{LOWER}}{$component};
                    delete ${${$components{$component}}{HIGHER}}{$parameters{COMPONENT}};
                }
                ${${$components{$component}}{SAME}}{$parameters{COMPONENT}} = 0;
                ${${$components{$parameters{COMPONENT}}}{SAME}}{$component} = 0;
                foreach my $lower (keys(%{${$components{$component}}{LOWER}})) {
                    next if(defined(${$components{$parameters{COMPONENT}}}{$lower}));
                    priorities_lower(
                        COMPONENT => $parameters{COMPONENT},
                        LOWER => $lower,
                    );
                }
                foreach my $higher (keys(%{${$components{$component}}{HIGHER}})) {
                    next if(defined(${$components{$parameters{COMPONENT}}}{$higher}));
                    priorities_higher(
                        COMPONENT => $parameters{COMPONENT},
                        HIGHER => $higher,
                    );
                }
            }
        }
    }

    my $COMPONENTS = $self->components();
    return if(ref($COMPONENTS) !~ /^ARRAY$/i);
    $PRIORITIES{$package} = {} if(!defined($PRIORITIES{$package}));
    $PRIORITIES{$package} = {} if(ref($PRIORITIES{$package}) !~ /^HASH$/i);
    if(0 == scalar(keys(%{$PRIORITIES{$package}}))) {
        foreach my $component (@{$COMPONENTS}) {
            priorities_component(
                COMPONENT => $component,
                PARAMETERS => [(@{$parameters{PARAMETERS}})],
            );
        }
        my $priorities = 0;
        my $reduced = 1;
        while(scalar(keys(%{$PRIORITIES{$package}})) < scalar(keys(%components)) && $reduced) {
            $reduced = 0;
            foreach my $component (keys(%components)) {
                next if(defined(${$PRIORITIES{$package}}{$component}));
                my $hasLower = 0;
                foreach my $lower (keys(%{${$components{$component}}{LOWER}})) {
                    if(!defined(${$PRIORITIES{$package}}{$lower})) {
                        $hasLower = 1;
                        last;
                    } elsif($priorities == ${$PRIORITIES{$package}}{$lower}) {
                        $hasLower = 1;
                        last;
                    }
                }
                if(0 == $hasLower) {
                    ${$PRIORITIES{$package}}{$component} = $priorities;
                    foreach my $same (keys(%{${$components{$component}}{SAME}})) {
                        ${$PRIORITIES{$package}}{$same} = $priorities;
                    }
                    $reduced = 1;
                }
            }
            $priorities++;
        }
    }
    if(!defined($parameters{PRIORITY})) {
        my $priorities = 0;
        foreach my $priority (keys(%{$PRIORITIES{$package}})) {
            $priorities = ${$PRIORITIES{$package}}{$priority} if($priorities < ${$PRIORITIES{$package}}{$priority});
        }
        return $priorities;
    } elsif(ref($parameters{PRIORITY}) !~ /^$/) {
    } elsif($parameters{PRIORITY} =~ /^\s*\d+\s*$/) {
        my @priorities;
        foreach my $priority (keys(%{$PRIORITIES{$package}})) {
            push(@priorities, $priority) if($parameters{PRIORITY} == ${$PRIORITIES{$package}}{$priority});
        }
        return if(0 == scalar(@priorities));
        return [(@priorities)];
    } elsif(defined(${$PRIORITIES{$package}}{$parameters{PRIORITY}})) {
        return ${$PRIORITIES{$package}}{$parameters{PRIORITY}};
    }
    return;
}


=head2 reinitialise

Overrides L<Anansi::Singleton::reinitialise|Anansi::Singleton/"reinitialise">.

=over 4

=item self I<(Blessed Hash, Required)>

An object of this namespace.

=item parameters I<(Hash, Optional)>

Named parameters supplied to the L<Anansi::Singleton::new|Anansi::Singleton/"new"> method.

=over 4

=item IDENTIFICATION I<(String, Optional)>

A unique component identification.

=back

=back

Enables the conglomeration of L<Anansi::Singleton::new|Anansi::Singleton/"new">
and L<Anansi::ComponentManager::addComponent|Anansi::ComponentManager/"addComponent">
through a specified I<IDENTIFICATION> parameter.  Called just after module
instance object creation.

=cut


sub reinitialise {
    my ($self, %parameters) = @_;
    if(defined($parameters{IDENTIFICATION})) {
        my $identification = $parameters{IDENTIFICATION};
        if(!defined($self->componentIdentification($identification))) {
            delete $parameters{IDENTIFICATION};
            $self->addComponent(
                $identification,
                %parameters
            );
        }
    }
}


=head2 removeChannel

    if(1 == Anansi::ComponentManager::removeChannel(
        'Anansi::ComponentManagerExample',
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

=item parameters I<(Scalar B<or> Array, Required)>

The channels to remove.

=back

Undefines the responding subroutine for the named component manager's channels.

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


=head2 removeComponent

    if(1 == Anansi::ComponentManager::removeComponent(
        'Anansi::ComponentManagerExample',
        'someComponent',
        'anotherComponent',
        'yetAnotherComponent',
        'etcComponent'
    ));

    if(1 == $OBJECT->removeComponent(
        'someComponent',
        'anotherComponent',
        'yetAnotherComponent',
        'etcComponent'
    ));

=over 4

=item self I<(Blessed Hash B<or> String, Required)>

An object or string of this namespace.

=item parameters I<(Array, Required)>

A string or array of strings containing the name of a component.

=back

Releases a named component instance for garbage collection.  Returns a B<1>
I<(one)> or a B<0> I<(zero)> representing B<success> or B<failure>.

=cut


sub removeComponent {
    my ($self, @parameters) = @_;
    my $package = $self;
    $package = ref($self) if(ref($self) !~ /^$/);
    return 0 if(0 == scalar(@parameters));
    return 0 if(!defined($COMPONENTS{$package}));
    my %reverse = map { $IDENTIFICATIONS{$_} => $_ } (keys(%IDENTIFICATIONS));
    foreach my $key (@parameters) {
        if(defined(${$COMPONENTS{$package}}{$key})) {
        } elsif(!defined(${$COMPONENTS{$package}}{$reverse{$key}})) {
            return 0;
        }
    }
    foreach my $key (@parameters) {
        if(defined(${$COMPONENTS{$package}}{$key})) {
            delete ${$COMPONENTS{$package}}{$key};
            $self->used('COMPONENT_'.$key);
        } elsif(defined(${$COMPONENTS{$package}}{$reverse{$key}})) {
            delete ${$COMPONENTS{$package}}{$reverse{$key}};
            $self->used('COMPONENT_'.$key);
        }
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
