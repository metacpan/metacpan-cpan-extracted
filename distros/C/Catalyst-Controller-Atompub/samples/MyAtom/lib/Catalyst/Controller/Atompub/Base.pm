package Catalyst::Controller::Atompub::Base;

use strict;
use warnings;

use Atompub::DateTime qw(datetime);
use Atompub::MediaType qw(media_type);
use Catalyst::Controller::Atompub;
use HTTP::Status;
use NEXT;

use base qw(Catalyst::Controller);

__PACKAGE__->mk_accessors(qw(info));

sub new {
    my($class, @args) = @_;
    my $self = $class->NEXT::new(@args);
    $self->info( Catalyst::Controller::Atompub::Info->instance($self) );
    $self;
}

sub error {
    my($self, $c, @args) = @_;

    return if ! is_success $c->res->status && $c->res->body;

    my($status, $message)
        = @args  > 1                                      ?  @args
        : @args == 1 && $args[0] =~ /^([1-5]\d\d)\s*(.*)/ ? ($1, $2)
        : @args == 1 && $args[0] =~ /^(.*)/               ? ($2)
        :                                                   ();

    $status ||= RC_INTERNAL_SERVER_ERROR;
    $c->res->status($status);

    $message ||= status_message($status);
    my $report = "$status $message";

    my $entry = XML::Atom::Entry->new;

    my $link = XML::Atom::Link->new;
    $link->rel('related'); # XXX via?
    $link->href($c->req->uri);
    $entry->add_link($link);

    $entry->updated(datetime->w3c);
    $entry->title($report);
    $entry->content($report); # XXX @type=text is better

    $c->res->body($entry->as_xml);
    $c->res->content_type(media_type('entry'));

    $c->log->error($report);

    return;
}

package Catalyst::Controller::Atompub::Info;

use strict;
use warnings;

use Catalyst::Utils;
use XML::Atom::Service;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(appclass));

my $Info;

sub instance {
    my($class, $arg) = @_;
    $Info ||= bless { appclass => Catalyst::Utils::class2appclass($arg) }, $class;
    $Info;
}

sub get {
    my($self, $c, $class) = @_;

    return unless $class = $self->_fullclass($c, $class);
    return unless $self->_is_collection($c, $class);

    my $collection = $self->{info}{$class};
    unless ($collection) {
        my $suffix = Catalyst::Utils::class2classsuffix($class);
        my $config = $c->config->{$suffix}{collection};
        $collection = XML::Atom::Collection->new;
        $collection->title($config->{title} || $class =~ /Controller::(.+)/);
        $collection->accept(@{ $config->{accept} }) if $config->{accept};
        $collection->add_categories($self->_make_categories($c, $_))
            for @{ $config->{categories} };
    }

    $collection->href($class->make_collection_uri($c));

    $collection;
}

sub _fullclass {
    my($self, $c, $class) = @_;
    $class = ref $class || $class || return;
    my $appclass = $self->appclass;
    $class =~ /^$appclass\::/ ? $class : join('::', $appclass, $class );
}

sub _is_collection {
    my($self, $c, $class) = @_;
    UNIVERSAL::isa $class, 'Catalyst::Controller::Atompub::Collection';
}

sub _make_categories {
    my($self, $c, $config) = @_;

    my $cats = XML::Atom::Categories->new;
    $cats->href($config->{href}) if $config->{href};
    $cats->fixed($config->{fixed}) if $config->{fixed};
    $cats->scheme($config->{scheme}) if $config->{scheme};

    my @cat = map { my $cat = XML::Atom::Category->new;
                    $cat->term($_->{term});
                    $cat->scheme($_->{scheme}) if $_->{scheme};
                    $cat->label($_->{label}) if $_->{label};
                    $cat }
                 @{ $config->{category} };
    $cats->category(@cat);

    $cats;
}

1;
__END__

=head1 NAME

Catalyst::Controller::Atompub::Base
- A Catalyst controller for the Publishing Protocol


=head1 DESCRIPTION

L<Catalyst::Controller::Atompub::Base> is a base class of
L<Catalyst::Controller::Atompub::Service> and
L<Catalyst::Controller::Atompub::Collection>.


=head1 METHODS

=head2 $controller->new


=head2 $controller->info

An accessor for Collection information object.


=head2 $controller->error($c, [$status, $message])

Sets an Entry Document containing error message in $c->response->body,
and returns C<undef>.

See L<ERROR HANDLING>.


=head1 ERROR HANDLING

When something wrong happens, return with calling $controller->error method like:

    sub foo {
        my ($controller ,$c) = @_;

        return $controller->error($c, 404, "Entry does not exist")
            if is_something_wrong;
    }

Then, Atompub server responds with an Entry Document including error message:

    HTTP/1.1 404 Not Found
    Content-Type: application/atom+xml;type=entry

    <?xml version="1.0" encoding="UTF-8"?>
    <entry xmlns="http://www.w3.org/2005/Atom">
     <updated>2007-01-01T00:00:00Z</updated>
     <link rel="related"
           href="http://localhost:3000/mycollection/entry_1.atom"/>
     <title>404 Entry does not exist</title>
     <content type="xhtml">
      <div xmlns="http://www.w3.org/1999/xhtml">
       404 Entry does not exist
      </div>
     </content>
    </entry>

This default behavior can be changed by overriding the C<error> method.


=head1 SEE ALSO

L<XML::Atom>
L<XML::Atom::Service>
L<Atompub>
L<Catalyst::Controller::Atompub>


=head1 AUTHOR

Takeru INOUE  C<< <takeru.inoue _ gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
