
package CGI::Application::Dispatch::Server;

use strict;
use warnings;

use Carp qw ( confess croak );
#use CGI 'param';
use Scalar::Util qw( blessed reftype );
use HTTP::Response;
use HTTP::Status;
use IO::Capture::Stdout;
use CGI::Application::Dispatch;
use Params::Validate ':all';

our $VERSION = '0.53';

use base qw(
	    HTTP::Server::Simple::CGI
	    HTTP::Server::Simple::Static
	   );

# HTTP::Server::Simple methods

sub new {
	my $class = shift;
    my %p = validate(@_, {
            port  =>    { default => '8080',},
            class =>    { default => 'CGI::Application::Dispatch' },
            root_dir => { default => '.' }
    });

    # Reality check, is "root_dir really a directory?
    unless (-d $p{root_dir}) {
        croak "root_dir does not appear to a directory. The path provided was: $p{root_dir} ";
    }

	my $self  = $class->SUPER::new($p{port});

	$self->{root_dir}  = $p{root_dir};

    # XXX add reality check that the class has dispatch_args method first?
    eval "require $p{class}" || croak $@;

	$self->{dispatch_args} = $p{class}->dispatch_args;
	return $self;
}

# accessors

sub dispatch_args {
  my ($self, $new_args) = @_;
  if (defined $new_args) {
    (reftype($new_args) && reftype($new_args) eq 'HASH') ||
      confess "The new_args must be a HASH ref, not $new_args";
    # merge the new args into the defaults.
    @{$self->{dispatch_args}}{keys %$new_args} = values %$new_args;
  }
  return $self->{dispatch_args} ;
}

sub handle_request {
  my ($self, $cgi) = @_;

  # If the the request doesn't map to a static file that exists,
  # try our dispatch table. 
  unless ( $self->serve_static($cgi, $self->{root_dir}) ) {
    # warn "$ENV{REQUEST_URI}\n";
    # warn "\t$_ => " . param( $_ ) . "\n" for param();
    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    CGI::Application::Dispatch->dispatch(%{$self->{dispatch_args}});
    $capture->stop;
    my $stdout = join "\x0d\x0a", $capture->read;
    my $response = $self->_build_response( $stdout );
    print $response->as_string;
  }

}

# Shamelessly stolen from HTTP::Request::AsCGI by chansen
sub _build_response {
    my ( $self, $stdout ) = @_;

    $stdout =~ s{(.*?\x0d?\x0a\x0d?\x0a)}{}xsm;
    my $headers = $1;

    unless ( defined $headers ) {
        $headers = "HTTP/1.1 500 Internal Server Error\x0d\x0a";
    }

    unless ( $headers =~ /^HTTP/ ) {
        $headers = "HTTP/1.1 200 OK\x0d\x0a" . $headers;
    }

    my $response = HTTP::Response->parse($headers);
    $response->date( time() ) unless $response->date;

    my $message = $response->message;
    my $status  = $response->header('Status');

    $response->header( Connection => 'close' );

    if ( $message && $message =~ /^(.+)\x0d$/ ) {
        $response->message($1);
    }

    if ( $status && $status =~ /^(\d\d\d)\s?(.+)?$/ ) {

        my $code    = $1;
           $message = $2 || HTTP::Status::status_message($code);

        $response->code($code);
        $response->message($message);
    }

    my $length = length $stdout;

    if ( $response->code == 500 && !$length ) {

        $response->content( $response->error_as_HTML );
        $response->content_type('text/html');

        return $response;
    }

    $response->add_content($stdout);
    $response->content_length($length);

    return $response;
}


1;

__END__

=pod

=head1 NAME

CGI::Application::Dispatch::Server - A simple HTTP server for developing with CGI::Application::Dispatch

=head1 SYNOPSIS

B<This module is no longer maintained or recommended. Use
L<CGI::Application::Server> instead, which can do all this can and more.>

  use CGI::Application::Dispatch::Server;

  my $server = CGI::Application::Dispatch::Server->new( 
             class    => 'MyClass::Dispatch' 
             root_dir => '/home/project/www',
   );
  $server->run;

=head1 DESCRIPTION

This is a simple HTTP server for for use during development with
L<CGI::Application::Dispatch|CGI::Application::Dispatch>.  

It's a helpful tool for working on a private copy of a website on a personal computer. It's especially 
useful for working offline when you don't have easy access to a full-blown webserver.

If you have customized dispatch args, it's recommended that you put them 
in their own class, as described in the L<CGI::Application::Dispatch|CGI::Application::Dispatch> docs. 
That way, they can be accessed directly through L<CGI::Application::Dispatch|CGI::Application::Dispatch>,
or through here. 

=head1 METHODS

=head2 new()

  my $server = CGI::Application::Dispatch::Server->new( 
        port     => '80',                # optional, defaults to 8080
        class    => 'MyClass::Dispatch', # optional, defaults CGI::Application::Dispatch
        root_dir => './alphasite',       # optional, defaults to "."
  );
   
Initialize the server. If you've subclassed CGI::Application::Dispatch to provide your own
C<dispatch_args()>, let us know that here. 

If you are also serving some static content, define "root_dir" with the root directory
of this content. 

=head1 Other Methods You Probably Don't Need to Know About

=head2 dispatch_args()

 $server->dispatch_args(\%override_args);

This accepts a hashref of arguments and merges it into
L<CGI::Application::Dispatch|CGI::Application::Dispatch>'s dispatch() arguments. 

Be aware that this is a shallow merge, so a top level key name in the new hash
will completely replace one in the old hash with the same name.

It is recommended that you put your dispatch args in a separate class instead, as mentioned 
in the L<DESCRIPTION>.

=head2 handle_request()

  $self->handle_request($cgi);

This will check the request URI and handle  it appropriately,
printing to STDOUT upon success. There's generally no reason to call this directly.

=head1 CAVEATS

This is a subclass of L<HTTP::Server::Simple|HTTP::Server::Simple> and all of its caveats 
apply here as well.

=head1 BUGS

If you are not sure the behavior is a bug, please discuss it on the 
cgiapp mailing list ( cgiapp@lists.erlbaum.net ). If you feel certain
if you have found a bug, please report it through rt.cpan.org. 

=head1 ACKNOWLEDGEMENTS

This module was cloned from L<CGI::Application::Server|CGI::Application::Server>, which in turn 
borrowed significant parts from L<HTTP::Request::AsCGI|HTTP::Requeste::AsCGI>.

=head1 CONTRIBUTORS

George Hartzell E<lt>hartzell@alerce.comE<gt> 
Mark Stosberg

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by George Hartzell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
