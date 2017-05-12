package MyApp::Schema::ResultRole::Book::Count;

use Moose::Role;

requires qw/authors/;

sub count{
	my ($self) = @_;
	return $self->authors->count;
}

no Moose::Role;
1;
