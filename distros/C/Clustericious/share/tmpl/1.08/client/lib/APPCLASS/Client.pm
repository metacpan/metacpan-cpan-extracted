% my $class = shift;
package <%= $class %>::Client;

=head1 NAME

<%= $class %>::Client - <%= $class %> Client

=head1 SYNOPSIS

    my $c = <%= $class %>::Client->new();
    my $msg = $c->welcome or die $c->errorstring;

=head1 METHODS

=cut

use strict;
use warnings;

use Clustericious::Client;

our $VERSION = '0.01';

=head2 welcome

Get a welcome message.

Arguments :
    verbose : be verbose

=cut

route 'welcome'   => 'GET', '/';
route_args 'welcome' => [
    { name => 'verbose', type => '=s', modifies_url => 'query' },
];

=head1 SEE ALSO

<%= lc $class.'client' %>

=cut

1;

