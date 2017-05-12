sub {
	my ($self, $delegate) = @_;
	die "expected CGI::App instance as first parameter" unless $self->isa('CGI::Application');
	die "expected delegate class or instance as second parameter" unless $delegate;
	'called submode';
};

