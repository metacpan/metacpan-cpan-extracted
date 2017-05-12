package TestApp::Model::XMLRPC;

use strict;
use warnings;
use base qw/Catalyst::Model::XMLRPC/;

__PACKAGE__->config(
    location => 'http://rpc.geocoder.us/service/xmlrpc',
);


1;

__END__

=head1 NAME

TestApp::Model::XMLRPC - Test Model for Catalyst::Model::XMLRPC

=cut
