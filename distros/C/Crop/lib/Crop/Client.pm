package Crop::Client;

=pod

=head1 NAME

Crop::Client - Client utilities for the Crop framework

=head1 SYNOPSIS

    use Crop::Client;
    # ...usage...

=head1 DESCRIPTION

Crop::Client provides client-related utilities for the Crop framework.

=head1 AUTHORS

Euvgenio (Core Developer)

Alex (Contributor)

=head1 COPYRIGHT AND LICENSE

Apache 2.0

=cut

use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Client
	The Session based user.
=cut

use v5.14;
use warnings;

use Crop::Error;

=begin nd
Variable: our %Attributes
	id       - attribute lives in the <Crop::Object::Simple>
	id_users - user logined
=cut
our %Attributes = (
	id_users => {mode => 'read/write'},
);

=begin nd
Method: login ($user)
	Login with $user
	
Parameters:
	$user - <Crop::User>
	
Returns:
	$self
=cut
sub login {
	my ($self, $user) = @_;
	
	$self->{id_users} = $user->id;
	
	$self->Modified;
}

=begin nd
Method: logout ( )
	Log out.
	
	Client unlinks <Crop::User>
	
Returns:
	$self
=cut
sub logout {
	my $self = shift;
	
	undef $self->{id_users};
	
	$self->Modified;
}

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'client' string
=cut
sub Table { 'client' }

1;
