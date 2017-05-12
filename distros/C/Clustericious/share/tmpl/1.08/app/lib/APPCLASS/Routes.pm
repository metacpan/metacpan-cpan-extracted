% my $class = shift;
package <%= $class %>::Routes;

=head1 NAME

<%= $class %>::Routes - set up the routes for <%= $class %>.

=head1 DESCRIPTION

This package defines the API for <%= $class %>.

=head1 ROUTES

=cut

use strict;
use warnings;

use Clustericious::RouteBuilder;

=head2 get /

Get a welcome message.

=cut

get '/' => sub {
  my($c) = @_;
  $c->render(text => 'welcome to <%= $class %>');
};

1;
