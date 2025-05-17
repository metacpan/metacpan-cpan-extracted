package Crop::Rights;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Rights
	Interface to the Rights-system.
	
	Calculates actual privileges at the last moment when they used.
=cut

use v5.14;
use warnings;

use Crop::Rights::Role;

use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class attributes:

	priv       - hash of privileges; {Crop}{READ} = <sign>; where <sign>=-1 negative role, <sign>=1 positive; <sign> is NOT implemented
	roles_todo - array of delegated roles; only names
	role       - hash of all the roles <Crop::Rights::Role> by name
=cut
our %Attributes = (
	priv       => {default => {}},
	roles_todo => {default => []},
	role       => {default => {}},
);

=begin nd
Method: add_role (@roles)
	Add roles.
	
Parameters:
	@roles - names to add
=cut
sub add_role {
	my ($self, @roles) = @_;
	
	for (@roles) {
		next if exists $self->{role}{$_};
		
		push @{$self->{roles_todo}}, $_;
		$self->{role}{$_} = undef;
	}
}

=begin nd
Method: is_ok (%priv)
	Check required privileges to actual rights.
	
Parameters:
	%priv - required privileges
	
Returns:
	true  - if granted rights satisfy required privileges
	false - otherwise
=cut
sub ok {
	my ($self, %priv) = @_;
	
# 	debug 'RIGHTS_OK_SELF=', $self;
	
	if (@{$self->{roles_todo}}) {
		my $role = Crop::Rights::Role->All(
			name   => $self->{roles_todo},
			active => 1,
			EXT => ['privileges' => [qw/ realm perm /]]
		);
		
# 		debug 'ROLE=', $role;
		
		for ($role->List) {
			for ($_->privileges->List) {
				$self->{priv}{$_->realm->name}{$_->perm->code} = 1 unless exists $self->{priv}{$_->realm->name}{$_->perm->code};
			}
		}
		
		$self->{roles_todo} = [];
	}
# 	debug 'RIGHTS_OK_SELF=', $self;
	
	while (my ($perm, $realm) = each %priv) {
# 		debug "realm=$realm; perm=$perm";
		return unless exists $self->{priv}{$realm}{$perm};
	}

	1;
}

1;
