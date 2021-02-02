package Catalyst::ActionRole::RenderErrors;

use Moose::Role;
use Scalar::Util 'blessed';

my $dont_dispatch_error = sub {
  my ($self, $controller, $c) = @_;
  return 1 if $c->debug;
  return 1 if $c->req->method eq 'HEAD';
  return 1 if defined $c->response->body;
  return 1 if $c->response->status =~ /^(?:204|3\d\d)$/;
  return 0;
};

my $looks_like_error_obj = sub {
  my ($self, $obj) = @_;
  return (blessed($obj) && ($obj->can('code') || $obj->can('status'))) ? 1:0;
};

my $normalize_code = sub {
  my ($self, $obj) = @_;
  my $code = $obj->can('code') ? $obj->code : $obj->status;
  return $code;
};

my $finalize_args = sub {
  my ($self, $obj) = @_;
  my %args = ();
  $args{meta} = $obj->meta if $obj->can('meta');
  $args{errors} = $obj->errors if $obj->can('errors');
  return %args;
};

around 'execute', sub {
  my ($orig, $self, $controller, $c, @args) = @_;
  my $ret = $self->$orig($controller, $c, @args);

  return $ret if $self->$dont_dispatch_error($controller, $c);

  my @errors = @{$c->error};
  $c->clear_errors;
  if($self->$looks_like_error_obj(my $first = $errors[0])) {
    my $code = $self->$normalize_code($first);
    my %args = $self->$finalize_args($first);      
    $c->dispatch_error($code, %args);
  } else {
    $c->dispatch_error(500);
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

Handles any uncaught errors (defined as "there's something in C<$c->errors>").  If in Debug mode
this just passes the errors down to the default L<Catalyst> debugging error response.  Otherwise
it converts to a Bad Request and dispatches an error page via C<$c->dispatch_error(500, errors=>\@errors)>.
This will give you a servicable http 500 error via content negotiation which you can customize as
desired (see L<CatalystX::Errors>).

If the first error in  C<$c->error> is an object that does either C<code> or C<status> then we use that
error to get the HTTP status code and any additional C<meta> or C<errors> arguments (if those methods
exist on the object.  If its not then we just return a simple HTTP 500 Bad request.  In that case we
won't return any information in C<$c->error> since that might leack contain Perl debugging info.

Useful for API work since the default L<Catalyst> error page is in HTML and if your client is requesting
JSON we'll return a properly formatted response in C<application/json>.

=head1 SEE ALSO
 
L<CatalystX::Errors>.

=head1 AUTHOR
 
L<CatalystX::Errors>.
    
=head1 COPYRIGHT & LICENSE
 
L<CatalystX::Errors>.

=cut
