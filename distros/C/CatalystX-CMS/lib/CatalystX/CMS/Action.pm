package CatalystX::CMS::Action;
use strict;
use warnings;
use base 'Catalyst::Action';
use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro 'c3';
use CatalystX::CMS;

our $VERSION = '0.011';

my $DEBUG = 0;

__PACKAGE__->mk_accessors(qw( cms ));

#use Scalar::Util qw( blessed );
#use Data::Dump::Streamer;

=head1 NAME

CatalystX::CMS::Action - action base class

=head1 SYNOPSIS

 package MyApp::Controller::Foo;
 use base (
    'CatalystX::CMS::Controller',    # MUST come first
    'Other::Controller::Base::Class'
 );
 
 sub bar : Local {
     
 }
 
 1;
 
 # if /foo/bar?cxcms=1 then can edit foo/bar.tt
 
=head1 DESCRIPTION

CatalystX::CMS::Action isa Catalyst::Action class that handles
all the template management. It is typically accessed
via a subclass of CatalystX::CMS::Controller.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 new([ cms => CatalystX::CMS->new ])

Overrides new() method to call next::method() and then
instantiate a CatalystX::CMS object.

You can pass in a B<cms> key/value pair. The value
should be an object that conforms to the CatalystX::CMS
API.

=cut

sub new {
    my $self = shift->next::method(@_);
    $self->{cms} ||= CatalystX::CMS->new( $self->class->config->{cms} );
    return $self;
}

=head2 execute( I<args> )

Checks for the presence the C<cxcms> request parameter.
If present and true, calls the cms() method instead of the
action's target method.

=cut

sub execute {
    my ( $self, $controller, $c, @arg ) = @_;

    #Dump( $self->{code} )->To( \*STDERR )->Out();

    if ( !$c->stash->{cms_mode}
        and exists $c->req->params->{cxcms} )
    {
        $c->stash( cms_mode => $c->req->params->{cxcms} );
        $self->do_cms( $controller, $c,
            $controller->cms_template_for( $c, @arg ) );

        $c->forward('_END');
    }
    else {
        return $self->next::method( $controller, $c, @arg );
    }

}

#sub match {
#
#    #carp 'match: ' . dump \@_;
#    my $self = shift;
#    my $ret  = $self->next::method(@_);
#    return $ret;
#}

=head2 do_cms( I<controller>, I<c>, I<arg> )

The primary engine of the CMS. Called via execute() if the
C<cxcms> param is true.

Possible values for the C<cxcms> parameter:

=over

=item 

create

=item 

edit

=item

cancel

=item

save

=item

preview

=item

diff

=item

history

=item

blame

=back

See the documentation for CatalystX::CMS for the method name matching
the C<cxcms> value.

=cut

sub do_cms {
    my ( $self, $controller, $c, $page ) = @_;
    unless ( $controller->cms_may_edit($c) ) {
        $c->error('permission denied');
        return;
    }

    $page ||= $controller->cms_template_for( $c, $c->action );
    my $method = $self->get_http_method($c);
    $c->log->debug("$method -> $page") if $c->debug;
    my $res = $self->cms->$method( $c, $controller, $page );
    $c->log->debug( "cms $method returned " . dump $res ) if $c->debug;

    $DEBUG and warn "cms $method returned " . dump($res);

    # set current_view in case we have many
    $c->stash->{current_view} ||= $self->cms->view_name;

    # set base url for this page since it requires $controller
    $c->stash->{cmspage_url} ||= $c->uri_for( $page->url );

    if ( !defined $res ) {
        $c->stash(
            cms_mode => 'edit',
            cmspage  => $page,
            template => 'cms/yui/editor.tt',
            error    => join( "\n", @{ $c->error } ),
        );
        $c->clear_errors;
        return;
    }
    elsif ( $res->{uri} ) {
        $c->res->redirect( $res->{uri} );
        if ( $c->can('flash') and exists $res->{message} ) {
            $c->flash( message => $res->{message} );
        }
    }
    elsif ( $res->{body} ) {
        $c->res->body( $res->{body} );
        $c->res->status( $res->{status} || 200 );
    }
    else {
        $c->stash( %$res, cmspage => $page );
    }

    return 1;
}

=head2 get_http_method

Works just like the http_method in CatalystX::CRUD::REST. Returns
the request method, deferring to the C<x-tunneled-method> or
C<_http_method> params if present.

=cut

sub get_http_method {
    my ( $self, $c ) = @_;
    return
        uc(    $c->req->params->{'x-tunneled-method'}
            || $c->req->params->{'_http_method'}
            || $c->req->method );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-cms@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
