package MyApp::Schema::ResultRole::Author::Name;

use Moose::Role;
requires qw/first_name last_name/;

sub name {
	my ($self) = @_;
	return $self->first_name." ". $self->last_name;
}


no Moose::Role;
1;
