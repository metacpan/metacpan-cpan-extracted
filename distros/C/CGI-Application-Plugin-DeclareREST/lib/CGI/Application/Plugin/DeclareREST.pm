use strict;
use warnings;
package CGI::Application::Plugin::DeclareREST;
{
  $CGI::Application::Plugin::DeclareREST::VERSION = '0.01';
}
# ABSTRACT: Declare RESTful API for CGI::Application

use Exporter;
use REST::Utils qw( request_method );
use Routes::Tiny 0.11;

our @ISA = qw( Exporter );
our @EXPORT = qw(
	get post del put patch any
	match captures
	add_route
);

our %EXPORT_TAGS = (
	http_methods => [qw( get post del put patch )],
);

our %routes;


sub add_route {
	my $self = shift;
	my $class = ref $self;
	
	my $router = $routes{ $class } ||= Routes::Tiny->new( strict_trailing_slash => 0 );
	return $router->add_route( @_ );
}


sub get {
	my $sub = pop;
	my ($path, %args) = @_;
	
	my $caller = caller();
	my $router = $routes{ $caller } ||= Routes::Tiny->new( strict_trailing_slash => 0 );
	return $router->add_route($path, method => 'get', name => $sub, %args);
}


sub post {
	my $sub = pop;
	my ($path, %args) = @_;
	
	my $caller = caller();
	my $router = $routes{ $caller } ||= Routes::Tiny->new( strict_trailing_slash => 0 );
	return $router->add_route($path, method => 'post', name => $sub, %args );
}


sub del {
	my $sub = pop;
	my ($path, %args) = @_;
	
	my $caller = caller();
	my $router = $routes{ $caller } ||= Routes::Tiny->new( strict_trailing_slash => 0 );
	return $router->add_route($path, method => 'delete', name => $sub, %args );
}


sub put {
	my $sub = pop;
	my ($path, %args) = @_;
	
	my $caller = caller();
	my $router = $routes{ $caller } ||= Routes::Tiny->new( strict_trailing_slash => 0 );
	return $router->add_route($path, method => 'put', name => $sub, %args );
}


sub patch {
	my $sub = pop;
	my ($path, %args) = @_;
	
	my $caller = caller();
	my $router = $routes{ $caller } ||= Routes::Tiny->new( strict_trailing_slash => 0 );
	return $router->add_route($path, method => 'patch', name => $sub, %args );
}


sub any {
	my $sub = pop;
	my ($methods, $path, %args) = @_;
	
	my $caller = caller();
	my $router = $routes{ $caller } ||= Routes::Tiny->new( strict_trailing_slash => 0 );
	return $router->add_route($path, method => $methods, name => $sub, %args);
}

sub import {
  my $caller = caller;
  
  $caller->add_callback('prerun', \&_routes_prerun);
  goto &Exporter::import;
}

sub _routes_prerun {
  my $self = shift;
  my $class = ref $self || $self;

  if(defined $self->query->param( $self->mode_param )) {
  	# OK, we got the query param, to select the right runmode:
  	# We should passthrough to allow normal behaviour
  	return;
  }

  my $method = request_method($self->query);

	my $r = $routes{$class};
	if($r) {
		my $match = $r->match($self->query->path_info, method => $method );
		if($match) {
			$self->run_modes( $match->name => $match->name );
			$self->prerun_mode( $match->name );
			$self->{__MATCH} = $match;
			return;
  	}
  }
}


sub match {
	(shift)->{__MATCH};
}


sub captures {
	(shift)->{__MATCH}->captures;
}

1;

__END__

=pod

=head1 NAME

CGI::Application::Plugin::DeclareREST - Declare RESTful API for CGI::Application

=head1 VERSION

version 0.01

=head1 SYNOPSIS

	package My::App;
	use base 'CGI::Application';
	use CGI::Application::Plugin::DeclareREST;
	
	get '/' => sub { ... }; # The main page
	get 'page/:id' => sub {
		my $self = shift;
		my $page_id = $self->captures->{id};
		...
	};
	post 'page/:id' => sub {
		my $self = shift;
		my $page_id = $self->captures->{id};
		...
	};

=head1 DESCRIPTION

This plugin brings the declarative syntax (similar to L<Dancer> & 
L<Mojolicious::Lite>) to L<CGI::Application>. It uses L<Routes::Tiny> to do the 
route-handling. It works together with default CGI::Application syntax as well
as with L<CGI::Application::Plugin::AutoRunmode>.

=head1 METHODS

=head2 add_route

See L<Routes::Tiny> add_route method.

=head2 get

	 get 'ROUTE/PATH/:some_arg' => sub {
	 		my $self = shift;
	 		# To access captured arguments:
	 		my $some_arg = $self->captures->{some_arg};
	 		# Do what ever you'd do in regular runmode
	 		...
	 };

Optionally you can use constraints for the captures:

	get 'article/:id', constraints => { id => qr/\d+/ } => sub { ... };

=head2 post

Works the same way as get, but only with HTTP POST requests.

=head2 del

Works the same way as get, but only with HTTP DELETE requests. Because HTTP 
DELETE is currently not availlable via regular html forms in todays browsers, 
you can tunnel it through POST with form-field _method=delete. See L<REST::Utils>
for documentation.

=head2 put

Works the same way as get. PUT-request can be tunneled with the same logic as
delete.

=head2 patch

Works the same way as get. PATCH-request can be tunneled with the same logic as delete.

=head2 any

Allows you to pass multiple http-methods as an array ref that will be handled by the same code.

	any [qw( get post )] => 'product/:id' => sub {
		my $self = shift;
		my $id   = $self->captures->{id};
		...
	};

=head2 match

Get the L<Routes::Tiny::Match> object.

=head2 captures

Returns hash-ref to captures (the arguments in the route). Same as:

	my $captures_ref = $self->match->captures;

=head1 SEE ALSO

=over 4

=item *

L<Routes::Tiny> is used for the route-handling. Check out Routes::Tiny docs
for the complete description of the path-syntax.

=item * 

L<REST::Utils> brings in the HTTP-method tunneling in regular html-forms. 
Basicly this means, that we can have hidden input named _method to tunnel
delete, put, patch, etc requests.

=item * 

L<CGI::Application>

=back

=head1 AUTHOR

Aku Kauste <aku@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Aku Kauste.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
