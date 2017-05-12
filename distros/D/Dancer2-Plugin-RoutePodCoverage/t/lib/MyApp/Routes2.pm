=head1 NAME

MyApp::Routes

=head1 DESCRIPTION

Dummy package

=cut

package t::lib::MyApp::Routes2;

use strict;
use warnings;
use Dancer2;

any ['get', 'post' ] => '/' => sub {

};


1;
