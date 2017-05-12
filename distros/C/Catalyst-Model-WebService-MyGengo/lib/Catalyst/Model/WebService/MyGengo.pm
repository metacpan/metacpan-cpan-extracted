package Catalyst::Model::WebService::MyGengo;

use 5.008004;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::Factory::PerRequest';

our $VERSION = '0.002';

=head1 NAME

Catalyst::Model::WebService::MyGengo - Catalyst Model providing access to the L<WebService::MyGengo> library

=head1 SYNOPSIS

In your model class:

    package MyApp::Model::MyGengo;
    
    use strict;
    use parent qw( Catalyst::Model::WebService::MyGengo );
    
    __PACKAGE__->config({
        class           => 'WebService::MyGengo::Client'
        , public_key    => 'your API public key'
        , private_key   => 'your API private key'
        , use_sandbox   => 0    # Whether to use the production site or the sandbox
        # See WebService::MyGengo::Client for other options
        });
    
    1;

Or in your myapp.conf or myapp_local.conf file ( be sure to escape any #
characters in your keys (eg \#) ):

    <Model::MyGengo>
        class           WebService::MyGengo::Client
        public_key      my-sandbox-pubkey
        private_key     my-sandbox-privkey
        use_sandbox     1
    </Model::MyGengo>

Then, in a controller:

    # Grab a WebService::MyGengo::Job
    my $job = $c->model('MyGengo')->get_job( 123 );

    # Add comments, etc.
    $job = $c->model('MyGengo')->add_job_comment( $job, "Nicey nice nice!" );

=head1 SEE ALSO

L<http://mygengo.com>

L<WebService::MyGengo::Client>

L<Catalyst::Model::Factory::PerRequest>

=head1 AUTHOR

Nathaniel Heinrichs

=head1 LICENSE

Copyright (c) 2011, Nathaniel Heinrichs <nheinric-at-cpan.org>.
All rights reserved.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
1;
