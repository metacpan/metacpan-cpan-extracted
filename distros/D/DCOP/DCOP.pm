package DCOP;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.038';
our $DEBUG   = 0;

######################################################
# Constructor
# Params: 
#   user      - user name to be used with DCOP
#   session   - (optional), if noSession is not specified and user is, the 
#               first DCOP session belonging to this user is assigned
#   noSession - (optional), if user is specified, then do not request DCOP
#               to return session for user
#   target    - what is the DCOP target to handle
#   control   - what is the DCOP target's control to use
sub new {
	my $proto  = shift;
	my $class  = ref($proto) || $proto;
	my %params = @_;
	my $self   = {};
	bless( $self, $class );
	chomp( my $basepath = `kde-config --expandvars --exec-prefix` );
	$self->{dcop}  = "$basepath/bin/dcop ";
	$self->{start} = localtime;
	$self->{user}  = $params{user} if ( $params{user} );
	if ( $self->{user} && !$params{noSession} ) {
		$self->_findSession( $params{session} );
	}
	$self->{target}  = $params{target}  if ( $params{target} );
	$self->{control} = $params{control} if ( $params{control} );
	$self->{dcop} .= "--user $self->{user} "       if ( $self->{user} );
	$self->{dcop} .= "--session $self->{session} " if ( $self->{session} );
	$self->{dcop} .= "$self->{target} "            if ( $self->{target} );
	$self->{dcop} .= "$self->{control} "           if ( $self->{control} );
	print "DCOP command is [$self->{dcop}]\n" if ($DEBUG);
	return $self;
}

###############################################
# Get the first session of user, else, just 
# use the provided session
sub _findSession {
	my ( $self, $sessionParam ) = @_;
	if ($sessionParam) {
		print "session provided, using it.\n" if ($DEBUG);
		$self->{session} = $sessionParam;
		return;
	}

	print "session not provided. finding it.\n" if ($DEBUG);
	if ( !$self->{user} ) {
		croak(
			'No user specified. DCOP session cannot be found without an user.');
	}

	my $sessions = `$self->{dcop} --user $self->{user} --list-sessions`;
	my @sessions = split /\n/, $sessions;
	my $session;

	for (@sessions) {
		if (/DCOPserver/) {
			$session = $_ if (/DCOPserver/);
			last;
		}
	}
	$session = $1 if ( $session =~ /([._A-Za-z0-9]+)/ );
	print "user = $self->{user}, session = $session\n" if ($DEBUG);
	$self->{session} = $session;
}

sub _getCommand {
	my $self = shift;
	return $self->{dcop};
}

sub run {
	my $self = shift;
	my $args = join " ", @_;
	chomp( my $ret = `$self->{dcop} $args` );
	return $ret;
}

1;
__END__

=head1 NAME

DCOP - Perl extension to speak to the dcop server via system's DCOP client.

=head1 SYNOPSIS

  use DCOP;
  $dcop = DCOP->new();
  print $dcop->run( 'konqueror interfaces' ), "\n";

=head1 DESCRIPTION

This class is meant to be a base constructor for higher level of abstraction
on dcop clients.

=head1 METHODS

=head2 new()

Constructor. Args: user, session, noSession, target, control.
Target is the application wished to control. Control is the interface of the application wished to control.
User is the user name, session is the DCOP session's name belonging to the user specified, noSession is supplied
when no session needs to be automatically gotten.

=head2 run()

Function call. This is how we interface with dcop.

=head1 AUTHOR

Juan C. Muller, E<lt>jcmuller@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Juan C. Muller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
