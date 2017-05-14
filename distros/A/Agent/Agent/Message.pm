#!/usr/bin/perl

##
# Messaging class to standardize agent communication across multiple
#  transport mediums.
# Steve Purkis, <spurkis@engsoc.carleton.ca>
# June 21, 1998
##

package Agent::Message;
use vars qw( $Debug );

#$Debug = 1;

sub new {
	my ($class, %args) = @_;
	my $self = {};

	$self->{Body} = $args{Body};
	if ($args{Transport}) {
		${$self->{Transport}}{$args{Transport}} = [ $args{Address} ];
		if ($args{SendNow}) {
			bless $self, $class;
			return $self->send;
		}
	}
	bless $self, $class;
}

sub send {
	my $self = shift;
	my %args = @_;
	my %trans = %{$self->{Transport}};
	my @return;

	foreach $medium (keys(%trans)) {
		my @addrs = @{$trans{$medium}};
		print "Sending message in $medium.\n" if $Debug;
		foreach $address (@addrs) {
			push @return, &Agent::Transport::send(
				Medium  => $medium,
				Address => $address,
				Message => $self->{Body},
				%args
			);
		}
	}
	return @return;
}

sub add_dest {
	my $self = shift;
	my $medium = shift or return;
	push (@{${$self->{Transport}}{$medium}}, @_);
}

sub del_dest {
	my $self = shift;
	my $medium = shift or return;
	my %trans = %{$self->{Transport}};
	foreach my $addr (@_) {
		;	# can't be bothered at the moment.
	}
}

sub del_transport {
	my $self = shift;
	my %trans = %{$self->{Transport}};
	for (@_) {
		delete ${$self->{Transport}}{$_};
	}
}

sub body {
	my $self = shift;
	$self->{Body} = \@_ if @_;
	return @{$self->{Body}};
}

sub dump {
	my $self = shift;
	my %trans = %{$self->{Transport}};

	foreach $med (keys(%trans)) {
		print "Medium: $med\nAddress(es): ";
		my @addrs = @{$trans{$med}};
		for (@addrs) { print "$_; "; }
		print "\n";
	}
	print "Body:\n";
	for (@{$self->{Body}}) { print; }
	print "\n";
}

1;

__END__

=head1 NAME

Agent::Message - the Transportable Agent Perl module

=head1 SYNOPSIS

  use Agent;

  my $msg = new Agent::Message(
	Body      => [ 'foo bar', 'baz' ],
	Transport => TCP,
	Address   => '127.0.0.1:24368'
  );

  $msg->send;

=head1 DESCRIPTION

This module is meant to standardize agent communications over a number of
different transport mediums (see I<Agent::Transport>).

=head1 CONSTRUCTOR

=over 4

=item new( [%args] )

C<new> makes a nice new C<Message> object with all the arguments you pass it.
It understands the following parameters:

        Body => $body,
     [  Transport => $medium,
        Address => $destination,
        SendNow => $true_false   ]

This instantiates the class with only one destination (multiple
destinations are possible - see below).  If SendNow is true, the message is
dispatched ASAP.

=back

=head1 METHODS

=over 4

=item $msg->body( [@value] )

Sets/gets the body of the message.

=item $msg->add_dest( $transport, $addr1 [, $addr2 ...] )

Adds the destination address to the list of destinations within said
medium; adds the medium if need be.

=item $msg->del_dest( $transport, $addr1 [, $addr2 ...] )

Removes the destination address from the list of destinations within said
medium.  If last destination in medium, removes medium also.

=item $msg->del_transport( $transport )

Removes the specified transport medium and all of its destinations.

=item $msg->send( %args )

Sends the message body in all transport mediums.  Passes C<\%args> to all
transport mediums when sending.  Returns an array of results returned by
each transport medium the message was sent in.

=back

=head1 BUGS

$msg->del_dest and $msg->del_transport don't work; I'm too lazy.

=head1 SEE ALSO

C<Agent>, C<Agent::Transport>, the example agents.

=head1 AUTHOR

Steve Purkis E<lt>F<spurkis@engsoc.carleton.ca>E<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Steve Purkis. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=head1 THANKS

Whoever invented mail.

=cut
 