#
# This file is part of Catalyst-Controller-ElasticSearch
#
# This software is Copyright (c) 2013 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#
package Catalyst::Controller::ElasticSearch;
{
  $Catalyst::Controller::ElasticSearch::VERSION = '0.1.0';
}
# ABSTRACT: Thin proxy for ElasticSearch with some protection

use Moose;
use namespace::autoclean;
use JSON;
use List::MoreUtils ();
use Moose::Util     ();

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(
    default     => 'application/json',
    map     => { 'application/json' => "JSON" },
    action_args => {
        'search' =>
            { deserialize_http_methods => [qw(POST PUT OPTIONS DELETE GET)] }
    }
);


has model_class => (
	is => "ro",
	required => 1,
	lazy => 1,
	default => sub {
		my $self = shift;
		die "Please specify the model class for " . ref $self;
	},
);


has index => (
    is => 'ro',
    required => 1,
    lazy => 1,
    default => sub {
        my $self = shift;
        die "Please specify an index for " . ref $self;
    },
);


has type => (
    is => 'ro',
);


has max_size => (
	is => "ro",
	isa => "Int",
	default => 5000,
);


has raw_get => (
	is => "ro",
	isa => "Bool",
	default => 1,
);


has allow_scripts => (
	is => "ro",
	isa => "Bool",
	default => 0,
);


sub model {
    my ($self, $c) = @_;
    my $model = $c->model($self->model_class);
    if($model->can("esxmodel")) {
        $model = $model->esxmodel->index($self->index)->type($self->type);
    } elsif(my $es = $model->can("es") || $model->can("_es")) {
        $model = Catalyst::Controller::ElasticSearch::State->new(
            es => $model->$es,
            type => $self->type,
            index => $self->index,
        );
    } else {
        die "The model " . ref $model . " does not provide an es method that returns an ElasticSearch instance";
    }
    my $params = $c->req->params;
    $model = $model->fields( [ map { split(/,/) } $c->req->param("fields") ] )
        if $c->req->param("fields");
    my $size = $params->{size} || ( $c->req->data || {} )->{size};
    if(defined $size) {
    	my $max_size = $self->max_size;
        $c->detach( "error", [ 416, "size parameter exceeds maximum of $max_size" ] )
            if ( $size && $max_size && $size > $max_size );
        $model = $model->size($size);
    }
    unless($self->allow_scripts) {
    	my $body = $c->req->data;
        my $script;
        $body = [$body] unless ref $body eq "ARRAY";
        while(my @keys = map { keys %$_ } grep { ref $_ eq "HASH" } @$body) {
            $script++ && last if grep { $_ eq "script" } @keys;
            $body = [
                map { ref $_ eq "ARRAY" ? @$_ : $_ }
                map { values %$_ }
                grep { ref $_ eq "HASH" } @$body
            ];
        }
        $c->detach( "error",
        [ 416, "'script' fields are not allowed" ] ) if $script;
    }
    return $model;
}


sub mapping : Path('_mapping') {
    my ( $self, $c ) = @_;
    $c->stash(
        $self->model($c)->es->mapping(
            index => $self->index,
            type  => $self->type,
        )
    );
}


sub get : Path('') : Args(1) : ActionClass('Deserialize') {
    my ( $self, $c, $id ) = @_;
    eval {
        my $file = $self->model($c)->raw->get($c->req->data || $id);
        $c->stash( $self->raw_get ? $file : ( $file->{_source} || $file->{fields} ) );
    } or $c->detach("error", [404, $@]);
}


sub all : Path('') : Args(0) :
    ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
    $c->forward('search');
}


sub search : Path('_search') : ActionClass('Deserialize') {
    my ( $self, $c ) = @_;
    my $req = $c->req;
    # shallow copy
    my $params = { %{ $req->params } };
    my $model = $self->model($c);
    delete $params->{callback};
    my $method = $req->param("q") ? "searchqs" : "search";
    eval {
        $c->stash(
            $model->es->$method(
                $req->data ? ( %{$req->data} ) : (),
                %$params,
                index => $self->index,
                $self->type ? ( type => $self->type ) : (),
                $model->size ? ( size => $model->size ) : (),
                $model->fields ? ( fields => $model->fields ) : (),
            )
        );
    } or do { $c->detach( "error", [416, $@] ) };
}


sub error : Private {
    my ( $self, $c, $code, $message ) = @_;
    $c->res->code($code);
    if ( eval { $message->isa('ElasticSearch::Error') } ) {
        $c->stash( { code => $code, message => $message->{'-text'} } );
        $c->detach;
    }
    else {
        $c->stash( { code => $code, message => "$message" } );
        $c->detach;
    }
}

__PACKAGE__->meta->make_immutable;

package #
    Catalyst::Controller::ElasticSearch::State;
use Moose;
use MooseX::Attribute::Chained;

has [qw(size fields index type es)] => ( is => "rw", traits => ["Chained"] );

sub raw { shift }

sub get {
    my ($self, $id) = @_;
    return $self->es->get(
        $self->fields ? (fields => $self->fields) : (),
        index => $self->index,
        type => $self->type,
        id => $id,
    );
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Catalyst::Controller::ElasticSearch - Thin proxy for ElasticSearch with some protection

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

This controller base class provides some basic protection for your ElasticSearch
server. This will allow you to publish individual indices and types through
your Catalyst application. The controller will prevent malicious requests
such as huge size parameters or scripts.

ElasticSearch's C<_search> endpoint is very powerful. And with power comes great
responsibility. Instead of providing the vanilla search endpoint, it is recommeded
that you predefine searches that process only certain parameters. See L</DISABLING FEATURES>.

B<< Exposing ElasticSearch to the Internet is dangerous. MetaCPAN is doing it, 
and this module is the result of what we've learned so far. >>

=head2 SYNOPSIS

 package MyApp::Model::ElasticSearch;
 use Moose;
 use ElasticSearch
 extends 'Catalyst::Model';

 has es => (
    is => "ro",
    default => sub { ElasticSearch->new },
 );

 package MyApp::Controller::Twitter;
 use Moose;
 extends "Catalyst::Controller::ElasticSearch";

 __PACKAGE__->config(
    model_class => "ElasticSearch",
    index => "twitter",
 );


 package MyApp::Controller::Twitter::Tweet;
 use Moose;
 extends "MyApp::Controller::Twitter";

 __PACKAGE__->config(
    type  => "tweet",

    # defaults
    max_size      => 5000,
    allow_scripts => 0,
    get_raw       => 1,
 );

=head1 CONFIGURATION

=head2 model_class

The name of your model class that connects to ElasticSearch. Basically
the name you would use to access it via L<Catalyst/model>.

This controller is very flexible and accepts any model class that provides
a C<_es> or C<es> method that returns a L<ElasticSearch> instance.

If you want to use L<ElasticSearchX::Model> classes in the controller, provide
a C<esxmodel> method in your model that will return an instance of
L<ElasticSearchX::Model>.

=head2 index

The ElasticSearch index this controller will handle. L</index> and L</type>
can also be ArrayRefs or C<_all>. See L<ElasticSearch> for more information.

=head2 type

The ElasticSearch type this controller will handle. The type is optional.

=head2 max_size

Defaults to 5000. A http status 416 is returned in case the user exceed the size limit.
The size parameter is evaluated both from the query parameter as well as in
the request body.

Setting max_size to C<0> will disabled the check.

=head2 raw_get

Disable to only retrieve the C<_source> or C<fields> key if requesting a
resource by its ID (i.e. no searching). This might be more convenient
because the client doesn't has to traverse to the actual data but it also
breaks clients that expect the ElasticSearch format that includes type and
index information.

=head2 allow_scripts

Malicious scripts for scoring can cause the ElasticSearch server to spin or
even execute commands on the server. By default, scripts are not enabled.

=head1 DISABLING FEATURES

If you want to disable certain features such as search, get or mapping,
feel free to override the corresponding methods.

 sub search {
    my ($self, $c) = @_;
    $c->detach("error", [403, "Disabled _search"]);
 }

 sub by_color : Path  : Args(1) {
    my ($self, $c, $color) = @_;
    my $model = $self->model($c); # does security checks
    eval { $c->stash(
        $model->es->search(
            index => $self->index,
            type => $self->type,
            size => $model->size,
        ) );
    } or do { $c->detach("error", [500, $@]) };
 }

=head1 ENDPOINTS

By default, this controller will create the following endpoints for a controller
named C<MyApp::Controller::Tweet>.

=head2 mapping

  /twitter/tweet/_mapping

This will return the ElasticSearch mapping.

=head2 get

  /twitter/tweet/$id

Will return the document C<$id>. If L</raw_get> is set to false, the returned
JSON will not include the ElasticSearch metadata. Instead the C<_source> or
C<fields> property is returned.

=head2 all

 /twitter/tweet

This endpoint is equivalent to C</tweet/_search?q=*>.

=head2 search

 /twitter/tweet/_search

This endpoint proxies to the search endpoint of ElasticSearch. However, it will
sanitize the query first.

=head1 ACCESS CONTROL

As with other controllers, you would do the access control in the C<auto>
action.

 sub auto : Private {
    my ($self, $c) = @_;
    return $c->detach("error", [403, "Unauthorized"])
        unless $c->user->is_admin;
    return 1; # return 1 to proceed
 }

=head1 PRIVATE ACTIONS

=head2 error

 $c->detach("error", [404, "Not found"]);
 $c->detach("error", [$code, $message]);

This helper action can be used to return a error message to the client.
The client will receive a JSON response that includes the message and
the error code. If the message is a L<ElasticSearch::Error>, the corresponding
error message will be retrieved from the object.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Moritz Onken.

This is free software, licensed under:

  The MIT (X11) License

=cut
