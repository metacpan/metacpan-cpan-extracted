package CatalystX::ExtJS::Direct;
# ABSTRACT: Enable Ext.Direct in Catalyst controllers

1;

__END__

=head1 SYNOPSIS

  package MyApp::Controller::API;
  use Moose;
  extends 'CatalystX::Controller::ExtJS::Direct::API';

  package MyApp::Controller::Calculator;
  
  use Moose;
  BEGIN { extends 'Catalyst::Controller' };
  with 'CatalystX::Controller::ExtJS::Direct';
  
  sub sum : Local : Direct : DirectArgs(1) {
      my ($self, $c) = @_;
      $c->res->body( $c->req->param('a') + $c->req->param('b') );
  }
  
  1;

In your web application:

  // Load ExtJS classes here
  <script type="text/javascript" src="/api/src"></script>
  <script>
    Ext.Direct.addProvider(Ext.app.REMOTING_API);
    Calculator.sum({ a: 1, b: 2 }, function(result) {
        alert(result);
    });
  </script>
  

=head1 DESCRIPTION

This module makes the transition to Ext.Direct dead simple.

Have a look at the L<tutorial|CatalystX::ExtJS::Tutorial::Direct>
which gives you a few examples on how to use this module.

L<CatalystX::Controller::ExtJS::Direct::API> is responsible for
providing the API to the ExtJS application. Some configuration
can be done here.

=head1 SEE ALSO

=over 4

=item L<CatalystX::ExtJS>

Parent namespace. Includes examples and the code for the tutorial.

=item L<CatalystX::ExtJS::REST>

Add feature-rich REST controllers to your application.

=back
