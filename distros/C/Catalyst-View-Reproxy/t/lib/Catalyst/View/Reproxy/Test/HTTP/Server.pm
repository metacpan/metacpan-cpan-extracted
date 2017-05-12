package Catalyst::View::Reproxy::Test::HTTP::Server;

use base qw/HTTP::Server::Simple::CGI Class::Accessor::Fast/;
use HTTP::Server::Simple::Static;

use FindBin;

 __PACKAGE__->mk_accessors(qw/port docroot/);

sub new {
		my ($class, $arguments) = @_;

		my $self = $class->HTTP::Server::Simple::new($arguments->{port});

		$self->port($arguments->{port} || 3500);
		$self->docroot($arguments->{docroot} || '');

		return $self;
}

sub handle_request {
		my ($self, $cgi) = @_;

		return $self->serve_static($cgi, $self->docroot);
}

1;
