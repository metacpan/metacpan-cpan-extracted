package Catalyst::TraitFor::Controller::Breadcrumb::Followed;

use 5.008;

our $VERSION   = '0.02';
$VERSION = eval $VERSION;

use Moose::Role;

use namespace::autoclean;

sub breadcrumb_start {
    my ($self, $c, $title) = @_;

    my $session_name = $self->_session_name($c);

    $c->session->{$session_name} = [];
    $self->breadcrumb_add($c, $title);
}

sub breadcrumb_add {
    my ($self, $c, $title) = @_;

    my $session_name = $self->_session_name($c);

    my $uri = $c->uri_for($c->action) . '/' . join('/', @{$c->req->arguments});
    my $crumb = {
        class       => 'current',
        title       => $title,
        uri         => $uri,
    };

    # See if the URI is already in the breadcrumb trail
    my $breadcrumb_len = 0;
    if ($c->session->{$session_name}) {
        $breadcrumb_len = scalar(@{$c->session->{$session_name}});
    }
BREADCRUMB:
    for my $i (0..$breadcrumb_len-1) {
        # we may as well set the class to 'done' while we are here
        $c->session->{$session_name}[$i]{class} = 'done';
        if ($uri eq $c->session->{$session_name}[$i]{uri}) {
            # Found so truncate the breadcrumb trail to this item
            splice(@{$c->session->{$session_name}},$i);
            last BREADCRUMB;
        }
    }
    push(@{$c->session->{$session_name}}, $crumb);
    $breadcrumb_len = scalar(@{$c->session->{$session_name}});

    # Make penultimate class 'lastDone'
    if ($breadcrumb_len > 1) {
        $c->session->{$session_name}[$breadcrumb_len - 2]{class} = 'lastDone';
    }
}

sub _session_name {
    my ($self, $c) = @_;

    my $config = $c->config->{'Catalyst::TraitFor::Controller::Breadcrumb::Followed'};
    my $session_name;

    if ($config) {
        $session_name = $config->{session_name};
    }
    else {
        $session_name = 'breadcrumb';
    }

    return $session_name;
}

=pod

=head1 NAME

Catalyst::TraitFor::Controller::Breadcrumb::Followed - Breadcrumb navigation using Moose Roles

=head1 SYNOPSIS

This keeps a Breadcrumb trail of pages that have been visited allowing the user
to go back to any earlier page directly.

Note that this is different from a Breadcrumb which shows you where you are in a site
navigation hierarchy.

In your Catalyst Controller.

    package MyApp::Web::Controller::Root;

    use Moose;
    use namespace::autoclean;

    with 'Catalyst::TraitFor::Controller::BreadCrumb::Followed';

Then later on in your controllers you can do

    sub foo : Local {
        my ($self, $c) = @_;

        $self->breadcrumb_start($c, 'Foo Text');
        ...
    }

    sub bar : Local {
        my ($self, $c) = @_;

        $self->breadcrumb_add($c, 'Bar Text');
        ...
    }

=head1 DESCRIPTION

This implementation of Breadcrumb navigation is of the type that shows
the user where she has navigated. For example, she may start at a list
of Artists, clicking on one of the Artists displays a list of CDs by that
Artist. Clicking on a CD displays a list of Tracks on that CD.

The Breadcrumb would hold the route taken (Artists -> Artist -> CD -> Track) and
retain that information in session data.

The session data holds a data structure that can be used in a Template
to build a list of the visited pages together with navigation links and
rendered with suitable CSS.

The class keeps track of which pages have been visited so if a URL that
is in the list of Breadcrumbs is re-visited then the Breadcrumb trail is
truncated to the first instance.

Whenever the B<breadcrumb_start> method is called, any existing Breadcrumb
trail is truncated and a new one is started.

=head1 METHODS

=head2 breadcrumb_start

Start a new breadcrumb trail.

    sub artists : Local {
        my ($self, $c) = @_;

        $self->breadcrumb_start($c, 'All Artists');
        ...
    }

Calling breadcrumb_start removes any existing breadcrumb trail and starts a new
one.

The method takes two parameters, the $c catalyst object and the title to be shown
in the breadcrumb trail.

=head2 breadcrumb_add

Append to the end of an existing breadcrumb trail.

    sub cds : Local {
        my ($self, $c) = @_;

        $self->breadcrumb_add($c, $artist_name);
        ...
    }

This appends to the existing breadcrumb trail (as started by breadcrumb_start)
and adds the current URI to it.

In the event of the user navigating so that she navigates back to a URI she has
already visited in the breadcrumb trail, the trail is truncated back to the first
instance of that URI.

=head1 session data

The Breadcrumb trail is held in the session data, by default it is held in
$c->session->{breadcrumb} but this can be configured (see below).

The session data is build up into an array of hashes representing each
part of the breadcrumb trail. e.g

    $c->session->{breadcrumb} = [
        {
        class   => 'done',
        uri     => '/artists',
        title   => 'All Artists',
        },
        {
        class   => 'done',
        uri     => '/artist/3',
        title   => 'David Bowie',
        },
        {
        class   => 'lastDone',
        uri     => '/artist/3/cd/4',
        title   => 'Diamond Dogs',
        }
        class   => 'current',
        uri     => '/artist/3/cd/4/track/6',
        title   => 'Rebel Rebel',
        }
    ];

This session data can then be used to create HTML in a Template. One example is
as follows.

    <div class="navigation">
      <ul id="mainNav" class="breadcrumb">
    [% FOREACH crumb IN c.session.breadcrumb %]
        <li class="[% crumb.class %]">
      [% IF crumb.class=='lastDone' || crumb.class=='done' %]
        [% back_uri = crumb.uri %]
          <a href="[% crumb.uri %]">[% crumb.title %]</a>
      [% ELSE %]
          [% crumb.title %]
      [% END %]
        </li>
    [% END %]
      </ul>

    [% IF back_uri %]
      <div class="navigation_buttons">
        <button class="button_previous" onClick="parent.location='[% back_uri %]'"> Back </button>
      </div>
    [% END %]
    </div>

The use of suitable CSS can be used to display this in whatever form you wish.

=head1 configuration

By default the breadcrumb is held in $c->session->{breadcrumb} but you can change this in
your configuration in your application.

    package MyApp::Web;

    ...

    __PACKAGE__->config->{'Catalyst::TraitFor::Controller::Breadcrumb::Followed'} = {
        session_name => 'my_breadcrumb_trail',
    };


=head1 AUTHOR

Ian Docherty pause@icydee.com

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2010 the aforementioned authors. All rights
    reserved. This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut
1;
