=head1 NAME

MyApp::Routes

=head1 DESCRIPTION

Dummy package

=over

=cut

package t::lib::MyApp::Routes;

use strict;
use warnings;
use Dancer2;

=item get /

basic route

=cut

get '/' => sub {

};

## no pod here

post '/' => sub {
}; 

=back

=cut

1;
