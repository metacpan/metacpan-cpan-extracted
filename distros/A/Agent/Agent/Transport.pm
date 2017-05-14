#!/usr/bin/perl

##
# Transport class stub for Agent.pm messages.
# Steve Purkis <spurkis@engsoc.carleton.ca>
# June 21, 1998
##

package Agent::Transport;
use vars qw( $Debug );

#$Debug = 1;


##
# Autoloaded, non-OO Stuff
##

sub AUTOLOAD {
	return if (@_ % 2);	# was this _meant_ to be called?
	my (%args) = @_;
	my $med = delete $args{Medium} or return;
	$AUTOLOAD =~ /^((\w+\:\:)+)(\w+)$/;
	my $pkg = $1 . $med;
	my $sub = "$pkg\:\:$+";

	print "Autoloading $sub...\n" if $Debug;

	unless (defined &$sub) {
		# try Autoloading it...
		unless (eval "require $pkg") {
			warn "Couldn't autoload $pkg!\n";
			return;
		}
		unless (defined &$sub) {
			warn "Call to non-existing sub: $sub!\n";
			return;
		}
	}
	goto &$sub;
}


##
# OO Stuff
##

sub new {
	my ($class, %args) = @_;
	my $med = delete $args{Medium} or return;
	my $pkg = "$class\:\:$med";
	my $sub = "$pkg\:\:new";

	unless (defined &$sub) {
		unless (eval "require $pkg") {
			warn "Couldn't Autoload $pkg!\n";
			return;
		}
	}
	# does this really need to be wrapped in an eval?
	return eval "new $pkg( \%args )";
}

1;


__END__

=head1 NAME

Agent::Transport - the Transportable Agent Perl module

=head1 SYNOPSIS

  use Agent;

  my $t = new Agent::Transport(
	Medium => $name,
	Address => $addr
	...
  );
  ...
  my $data = $t->recv( [%args] );

=head1 DESCRIPTION

This package provides a standard interface to different transport mediums.
C<Agent::Transport> does not contain any transport code itself; it contains
a constructor, and code that autoloads the appropriate transport methods.

=head1 CONSTRUCTOR

=over 4

=item new( %args )

new() must be passed at least a I<Medium>.  The I<Address> argument is
strongly recomended (and should be required in most cases), as it's best not
to let the system make assumptions.  new() decides which Transport package
to use base upon the C<Medium> specified.  C<Address> is the destination in
that medium.  Any other arguments will be documented in the Agent::Transport
subclasses (such as Agent::Transport::TCP).

=back

=head1 STANDARD API METHODS

These methods are implemented in all transport subclasses.

=over 4

=item $t->recv()

C<recv> attempts to retrieve a message (from said address, over said
transport medium).  Returns the data if called in a scalar context, or a
list containing ($data, $from_address) if called in an array context. 
Returns nothing (i.e. sv_null or an empty list) if unsuccessful.

=item $t->transport()

Returns the transport medium over which the object communicates.

=item $t->address()

Returns the primary address at which the object can be reached.

=item $t->aliases()

Returns a list of addresses at which the object can be reached.

=back

=head1 STANDARD SUBROUTINES

=over 4

=item send( %args )

C<send> too must be passed a I<Medium> and an I<Address>.  In addition, it
also needs a I<Message> as either an anonymous array or a reference to an
array.

=item valid_address( %args )

This checks to see if the I<Address> provided is valid within the I<Medium>
specified by checking the I<syntax> of the address.  It does not check to
see whether or not said address exists.  Returns the address if successful,
or nothing otherwise.

=back

=head1 SEE ALSO

L<Agent>, L<Agent::Transport::*>

=head1 AUTHOR

Steve Purkis E<lt>F<spurkis@engsoc.carleton.ca>E<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Steve Purkis. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=head1 THANKS

The perl5-agents mailing list.

=cut
