package Catalyst::Controller::Atompub::Service;

use strict;
use warnings;

use Atompub::MediaType qw(media_type);
use XML::Atom::Service;

use base qw(Catalyst::Controller::Atompub::Base);

sub default :Private {
    my($self, $c) = @_;

    my $service = $self->_make_service($c);
    $service = $self->modify_service($c, $service) or return $self->error($c);

    $c->res->content_type(media_type('service')) unless $c->res->content_type;

    $c->res->body($service->as_xml) unless length $c->res->body;
}

sub modify_service {
    my($self, $c, $service) = @_;
    return $service;
}

sub _make_service {
    my($self, $c) = @_;

    my $service = XML::Atom::Service->new;

    my $suffix = Catalyst::Utils::class2classsuffix(ref $self);

    my @configs = @{ $c->config->{$suffix}{workspace} || [] };
    unless (@configs) {
        my @collections
            = grep { $self->info->get($c, $_) } keys %{ $c->components };
        @configs = ({
            title      => Catalyst::Utils::class2appclass($self),
            collection => \@collections,
        });
    }

    for my $config (@configs) {
        my $work = XML::Atom::Workspace->new;
        $work->title($config->{title});
        $work->add_collection($_) for grep { defined $_ }
                                       map { $self->info->get($c, $_) }
                                          @{ $config->{collection} || [] };
        $service->add_workspace($work);
    }

    $service;
}

1;
__END__

=head1 NAME

Catalyst::Controller::Atompub::Service
- A Catalyst controller for the Atom Service Document


=head1 SYNOPSIS

    # Use the Catalyst helper
    $ perl script/myatom_create.pl controller MyService Atompub::Service

    # And edit lib/MyAtom/Controller/MyService.pm
    package MyAtom::Controller::MyService;
    use base 'Catalyst::Controller::Atompub::Service';

    # Access to http://localhost:3000/myservice and get Service Document


=head1 DESCRIPTION

L<Catalyst::Controller::Atompub::Service> generates a Service Document
based on collection configuration.


=head1 SUBCLASSING

Just a single subclass is required in your Atompub server implementation.
No methods are needed to be overridden.


=head1 METHODS

The following methods can be overridden to change the default behaviors.


=head2 $controller->modify_service

By overriding C<modify_service>, modifies the default Service Documents:

    sub modify_service {
        my($self, $c, $service) = @_;

        # Edit $service (XML::Atom::Service) if you'd like to modify the
        # Service Document

        return $service;
    }


=head1 INTERNAL INTERFACES

=head2 $controller->default

=head2 $controller->_make_service


=head1 CONFIGURATION

By default (no configuration), this module provides a Service Document
with a single I<atom:workspace>.
The order of I<atom:collection>s is not defined.

You can specify the title and the order of I<atom:workspace>s and I<atom:collection>s like:

Controller::Service:
    workspace:
      - title: My Blog
        collection:
          - Controller::EntryCollection
          - Controller::MediaCollection


=head1 ERROR HANDLING

See ERROR HANDLING in L<Catalyst::Controller::Atompub::Base>.


=head1 SAMPLES

See SAMPLES in L<Catalyst::Controller::Atompub>.


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
