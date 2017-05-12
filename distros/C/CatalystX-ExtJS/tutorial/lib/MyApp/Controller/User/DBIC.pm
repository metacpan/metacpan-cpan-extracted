#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MyApp::Controller::User::DBIC;

use Moose;
extends 'Catalyst::Controller::DBIC::API::RPC';
with 'CatalystX::Controller::ExtJS::Direct';


__PACKAGE__->config(
	actions => { 
        setup  => { PathPart => 'user', Chained => '/' },
        create => { Direct => undef, DirectArgs => 1 }, 
        item   => { Direct => undef }, 
        update => { Direct => undef, DirectArgs => 1 }, 
        delete => { Direct => undef }, 
        list   => { Direct => undef, DirectArgs => 1 },  
    },
	class => 'DBIC::User',
	use_json_boolean => 1,
	create_requires => [qw(email first last)],
	return_object => 1,
);

before 'deserialize' => sub {
	my ($self, $c) = @_;
    $c->req->data($c->req->data->[0]) if(ref $c->req->data eq 'ARRAY');
	$c->req->data(undef) unless(ref $c->req->data);
};


1;