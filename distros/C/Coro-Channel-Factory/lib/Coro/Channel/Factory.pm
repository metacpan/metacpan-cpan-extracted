=head1 NAME

Coro::Channel::Factory - Factory for named Coro::Channel queues.

=head1 SYNOPSIS

  use Coro::Channel::Factory;
  
  # Initialise factory
  my $factory = Coro::Channel::Factory->new();
  
  # Get a handle to a (possibly previously undeclared) Coro::Channel, and put something..
  my $channel = $factory->name('some channel name');
  $channel->put($var);
  
  # Interacting directly - no intermediate handle object..
  $factory->name('some channel name')->put($other_var);
  my $item = $factory->name('some channel name')->get;
  
=head1 DESCRIPTION

This module provides a very simple name-binding for Coro::Channel, removing the need to track individual Coro::Channel objects.

As long as the Coro::Channel::Factory object is available, any named Coro::Channel can be utilised. 

=cut

package Coro::Channel::Factory;

use 5.008002;
use strict;
use warnings;

use Coro;

our $VERSION = '1.01';

=head2 API

=over 4
 
=item $factory = Coro::Channel::Factory->new()

Creates the Factory object

=back

=cut

sub new {
	my $class = shift;
	
	my $self = {};
	
	bless($self, $class);
	
	$self->initialise(@_);
		
	return $self;		
}

sub initialise {
	my $self = shift;
		
	$self->{channels} = { };
}

=over 4
 
=item $channel = $factory->name($name)

Get or create a channel with name $name

=back

=cut

sub name {
	my $self = shift;
	my $channelName = shift;

	if (!defined($self->{channels}->{$channelName})) {
		$self->{channels}->{$channelName} = new Coro::Channel;	
	}

	return $self->{channels}->{$channelName};
}

=head1 SEE ALSO

L<Coro>
L<Coro::Channel>

=head1 AUTHOR

Phillip O'Donnell, E<lt>podonnell@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Phillip O'Donnell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

