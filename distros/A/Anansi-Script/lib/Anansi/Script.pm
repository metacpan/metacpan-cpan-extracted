package Anansi::Script;


=head1 NAME

Anansi::Script - Manages how Perl script user input and process output should be handled.

=head1 SYNOPSIS

    #!/usr/bin/perl

    use Anansi::Script;

    my $OBJECT = Anansi::Script->new();
    if(defined($OBJECT)) {
        my $channels = $OBJECT->channel();
        if(defined($channels)) {
            my %channelHash = map { $_ => 1 } (@{$channels});
            if(defined($channelHash{MEDIUM})) {
                my $medium = $OBJECT->channel('MEDIUM');
                if('CGI' eq $medium) {
                    $OBJECT->channel('CONTENT', << "HEREDOC"
    <html>
     <body>
      <p>This Perl script was run using the Common Gateway Interface.</p>
     </body>
    </html>
    HEREDOC
                    );
                } elsif('SHELL' eq $medium) {
                    $OBJECT->channel('CONTENT', 'This Perl script was run using the Shell.'."\n");
                }
            }
        }
    }

    1;

=head1 DESCRIPTION

Determines the medium used to run the Perl Script and implements the resources
to handle the user input and process output.  Simplifies the interaction
mechanism and enables the Perl Script to be used in different mediums.  See
L<Anansi::ComponentManager> for inherited methods.

=cut


our $VERSION = '0.04';

use base qw(Anansi::ComponentManager);


=head1 INHERITED METHODS

=cut


=head2 addChannel

Declared in L<Anansi::ComponentManager>.

=cut


=head2 addComponent

    $OBJECT->SUPER::addComponent(undef);

    $OBJECT->Anansi::ComponentManager::addComponent(undef);

Declared in L<Anansi::ComponentManager>.  Overridden by this module.  Redeclared
in order to preclude inheritance.

=cut


sub addComponent {
}


=head2 channel

Declared in L<Anansi::ComponentManager>.

=cut


=head2 component

Declared in L<Anansi::ComponentManager>.

=cut


=head2 componentIdentification

Declared in L<Anansi::ComponentManager>.

=cut


=head2 components

Declared in L<Anansi::ComponentManager>.

=cut


=head2 DESTROY

Declared in L<Anansi::Singleton>.

=cut


=head2 finalise

    $OBJECT->SUPER::finalise(undef);

    $OBJECT->Anansi::Script::finalise(undef);

Declared as a virtual method in L<Anansi::Class>.  Overridden by this module.
Indirectly called during object destruction.

=cut


sub finalise {
    my ($self, %parameters) = @_;
    my $components = $self->components();
    if(defined($components)) {
        foreach my $component (@{$components}) {
            my $result = $self->SUPER::removeComponent($component);
        }
    }
}


=head2 fixate

Declared as a virtual method in L<Anansi::Singleton>.

=cut


=head2 implicate

Declared as a virtual method in L<Anansi::Class>.

=cut


=head2 import

Declared in L<Anansi::Class>.

=cut


=head2 initialise

    $OBJECT::SUPER->initialise(@_);

    $OBJECT->Anansi::Script::initialise(@_);

Declared as a virtual method in L<Anansi::Class>.  Overridden by this module.
Indirectly called during object construction.

=cut


sub initialise {
    my ($self, %parameters) = @_;
    my $component = $self->SUPER::addComponent(undef, %parameters);
    $self->channelComponent($component);
}


=head2 new

Declared in L<Anansi::Singleton>.

=cut


=head2 old

Declared in L<Anansi::Class>.

=cut


=head2 priorities

Declared in L<Anansi::ComponentManager>.

=cut


=head2 reinitialise

Declared as a virtual method in L<Anansi::Singleton>.

=cut


=head2 removeChannel

Declared in L<Anansi::ComponentManager>.

=cut


=head2 removeComponent

    $OBJECT->SUPER::removeComponent(undef);

    $OBJECT->Anansi::ComponentManager::removeComponent(undef);

Declared in L<Anansi::ComponentManager>.  Overridden by this module.  Redeclared
in order to preclude inheritance.

=cut


sub removeComponent {
}


=head2 used

Declared in L<Anansi::Class>.

=cut


=head2 uses

Declared in L<Anansi::Class>.

=cut


=head1 METHODS

=cut


=head2 channelComponent

    my $return = $OBJECT->channelComponent($component, 'some channel');

Attempts to create a new subroutine to enable the direct use of a channel of the
currently loaded component and define it as a channel of this module.  If a
channel with the same name as the component channel already is defined for this
module then it silently fails.  If a subroutine with the same name as the
channel does not exist in this module's namespace then that subroutine name is
used otherwise it remains anonymous.  Returns B<0> I<(zero)> on failure and B<1>
I<(one)> on success.

=cut


sub channelComponent {
    my ($self, $component) = @_;
    my $componentChannels = $self->component($component);
    return 0 if(!defined($componentChannels));
    my $channels = $self->channel();
    $channels = map { $_ => 1 } (@{$channels}) if(defined($channels));
    foreach my $channel (@{$componentChannels}) {
        next if('VALIDATE_AS_APPROPRIATE' eq $channel);
        if(defined($channels)) {
            next if(defined(${$channels}{$componentChannel}));
        }
        if(exists(&{ref($self).'::'.$channel})) {
            $self->addChannel(
                $channel => sub {
                    my ($self, $channel, @parameters) = @_;
                    return $self->component($component, $channel, (@parameters));
                }
            );
        } else {
            *{ref($self).'::'.$channel} = sub {
                my ($self, $channel, @parameters) = @_;
                return $self->component($component, $channel, (@parameters));
            };
            $self->addChannel(
                $channel => ref($self).'::'.$channel
            );
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

