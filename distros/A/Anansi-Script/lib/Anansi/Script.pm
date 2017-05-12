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


our $VERSION = '0.03';

use base qw(Anansi::ComponentManager);


=head1 METHODS

=cut


=head2 addComponent

 # N/A

An overridden inherited method to remove this functionality.

=cut


sub addComponent {
}


=head2 finalise

 $OBJECT::SUPER->finalise(@_);

An overridden virtual method called during object destruction.  Not intended to
be directly called unless overridden by a descendant.

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


=head2 initialise

 $OBJECT::SUPER->initialise(@_);

An overridden virtual method called during object creation.  Not intended to be
directly called unless overridden by a descendant.

=cut


sub initialise {
    my ($self, %parameters) = @_;
    my $component = $self->SUPER::addComponent(undef, %parameters);
    $self->channelComponent($component);
}


=head2 channelComponent

 my $return = $OBJECT->channelComponent($component, 'some channel');

Attempts to create a new subroutine to enable the direct use of a channel of the
currently loaded component and define it as a channel of this module.  If a
channel with the same name as the component channel already is defined for this
module then it silently fails.  If a subroutine with the same name as the
channel does not exist in this module's namespace then that subroutine name is
used otherwise it remains anonymous.  Returns 0 (FALSE) on failure and 1 (TRUE)
on success.

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


=head2 removeComponent

 # N/A

An overridden inherited method to remove this functionality.

=cut


sub removeComponent {
}


=head1 AUTHOR

Kevin Treleaven <kevin AT treleaven DOT net>

=cut


1;
