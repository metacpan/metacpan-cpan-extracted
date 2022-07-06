package Catalyst::ActionRole::RenderErrors;

use Moose::Role;

my $dont_dispatch_error = sub {
  my ($self, $controller, $c) = @_;
  return 1 if $c->req->method eq 'HEAD';
  return 1 if defined $c->response->body;
  return 1 if $c->response->status =~ /^(?:204|3\d\d)$/;
  return 0;
};

around 'execute', sub {
  my ($orig, $self, $controller, $c, @args) = @_;
  my $ret = $self->$orig($controller, $c, @args);

  return $ret if $self->$dont_dispatch_error($controller, $c);

  my @errors = @{$c->error} || return $ret;
  my $first = $errors[-1]; # We can only handle the last error in the stack

  $c->log->error($first);

  if($c->looks_like_http_error_obj($first)) {
    my ($status_code, $additional_headers, $template_args) = $first->as_http_response;
    $c->clear_errors && $c->dispatch_error($status_code, $additional_headers, $template_args)
      unless ($c->debug && ($status_code >= 500));
  } else {
    $c->clear_errors && $c->dispatch_error(500) unless $c->debug;
  }

  return $ret;
};
 
1;

=head1 NAME

Catalyst::ActionRole::RenderErrors - Automatically return an error page

=head1 SYNOPSIS

    package Example::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/) PathPart('') CaptureArgs(0) {} 

      sub not_found :Chained(root) PathPart('') Args {
        my ($self, $c, @args) = @_;
        $c->detach_error(404);
      }

      sub die :Chained(root) PathPart(die) Args(0) {
        die "saefdsdfsfs";
      }

    sub end :Does(RenderErrors) { }

    __PACKAGE__->config(namespace=>'');
    __PACKAGE__->meta->make_immutable;
  
=head1 DESCRIPTION

Tries to convert the last error in '$c->error' to something we can dispatch an error view too.

If the first error in  '$c->error' is an object that looks like it does L<CatalystX::Utils::DoesHttpException>
then we use that error to get the HTTP status code and any additional arguments.  If its not then we just return 
a simple HTTP 500 Bad request.  In that case we  won't return any information in C<$c->error> since that might leak
sensitiver Perl debugging info.   A stringified version of the error is sent to the error log.

Useful for API work since the default L<Catalyst> error page is in HTML and if your client is requesting
JSON we'll return a properly formatted response in C<application/json>.

B<NOTE> if you are in CATALYST_DEBUG mode then all HTTP 500 errors and non specific errors will still 
dump the development debugging error screen.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
