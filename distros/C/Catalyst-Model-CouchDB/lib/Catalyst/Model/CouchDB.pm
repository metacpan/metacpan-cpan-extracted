package Catalyst::Model::CouchDB;
use Moose;
extends 'Catalyst::Model';

use namespace::autoclean;
use strict;
use warnings;
use CouchDB::Client;

our $VERSION = '0.02';

sub COMPONENT {
    my ($class, $c, $config) = @_;
	my $self = $class->next::method(@_);
    $self->config($config);
    my $conf = $self->config;
    $self->{couchdb_client} = CouchDB::Client->new($conf);
    $c->log->debug("CouchDB::Client instantiated") if $c->debug;
	return $self;
}

sub AUTOLOAD {
    my ($self, @args) = @_;
    our $AUTOLOAD;
    return if $AUTOLOAD =~ /::DESTROY$/;

    (my $meth = $AUTOLOAD) =~ s/^.*:://;

    return $self->{couchdb_client}->$meth(@args);
}


1;

=pod

=head1 NAME

Catalyst::Model::CouchDB - CouchDB model class for Catalyst

=head1 SYNOPSIS

    # model
    __PACKAGE__->config(
        uri => 'http://localhost:5984/',
    );

    # controller
    sub foo : Local {
        my ($self, $c) = @_;

        eval {
            my $doc = $c->model('MyData')->database('foo')->newDoc('bar')->retrieve;
            $c->stash->{thingie} = $doc->{dahut};
        };
        ...
    }


=head1 DESCRIPTION

This model class exposes L<CouchDB::Client> as a Catalyst model.

=head1 CONFIGURATION

You can pass the same configuration fields as when you call L<CouchDB::Client>.

=head1 METHODS

=head2 CouchDB

All the methods not handled locally are forwarded to L<CouchDB::Client>.

=head2 new

Called from Catalyst.

=head1 AUTHOR

Robin Berjon <robin @t berjon d.t com>,
Julien Gilles <jul.gil@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to bug-catalyst-model-couchdb at rt.cpan.org, or through the
web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Model-CouchDB.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Robin Berjon, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as
Perl itself, either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may
have available.

=cut
