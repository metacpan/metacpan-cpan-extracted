#
# This file is part of Catalyst-Controller-ElasticSearch
#
# This software is Copyright (c) 2013 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#
package MyApp::Model::ElasticSearch;
use Moose;
extends "Catalyst::Model";

sub es { shift }

sub request {
	shift; return { request => @_ };
}

sub search {
	shift; return { search => {@_} };
}

sub get {
	shift; return { get => {@_}, _source => { foo => "bar" } };
}

sub mapping {
	shift; return { mapping => {@_} };
}

package MyApp::View::JSON;
use Moose;
extends "Catalyst::View::JSON";

package MyApp::Controller::Twitter;
use Moose;
extends "Catalyst::Controller::ElasticSearch";

__PACKAGE__->config(
	model_class => "ElasticSearch",
	index => "twitter",
	actions => { end => { "Private" => undef } },
);

sub end {
	my ($self, $c) = @_;
	$c->forward($c->view);
}

package MyApp::Controller::Twitter::Tweet;
use Moose;
extends "MyApp::Controller::Twitter";

__PACKAGE__->config(
	type => "tweet",
);

package MyApp::Controller::Twitter::User;
use Moose;
extends "MyApp::Controller::Twitter";

__PACKAGE__->config(
	type    => "user",
	raw_get => 0,
);

package MyApp;
use Moose;
use Catalyst::Stats;
extends "Catalyst";
{
	no warnings;
	*Catalyst::Utils::ensure_class_loaded = sub {};
}

__PACKAGE__->setup;
__PACKAGE__->psgi_app;
