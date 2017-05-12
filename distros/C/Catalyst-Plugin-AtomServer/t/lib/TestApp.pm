# $Id: TestApp.pm 1257 2006-06-27 17:07:05Z btrott $

package TestApp;
use strict;

use Catalyst qw( AtomServer
                 Authentication
                 Authentication::Credential::Atom
                 Authentication::Store::Minimal
               );

use TestApp::View::XML;
use XML::Atom::Entry;
use XML::Atom::Feed;

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'TestApp',
    authentication => {
        users => {
            foo => {
                password => 'bar',
            },
        },
    },
);

__PACKAGE__->setup;

sub default : Private {
    my($self, $c) = @_;
    $c->request->is_atom(1);

    my $method = $c->request->method;
    if ($method eq 'GET') {
        $c->forward('get_entries');
    } elsif ($method eq 'POST') {
        $c->forward('post_entry');
    }
}

sub get_entries : Private {
    my($self, $c) = @_;
    $c->login_atom or die "Unauthenticated";

    my $feed = XML::Atom::Feed->new;
    $feed->title('Blog');
    $feed->add_link({ rel => 'alternate', type => 'text/html',
                      href => 'http://btrott.typepad.com/typepad/' });
    $c->stash->{xml_atom_object} = $feed;
}

sub post_entry : Private {
    my($self, $c) = @_;
    my $entry = XML::Atom::Entry->new( Doc => $c->request->body_parsed )
        or die XML::Atom::Entry->errstr;
    $entry->title('Bar');
    $c->response->status(201);
    $c->stash->{xml_atom_object} = $entry;
}

sub end : Private {
    my($self, $c) = @_;
    $c->forward('TestApp::View::XML');
}

1;
