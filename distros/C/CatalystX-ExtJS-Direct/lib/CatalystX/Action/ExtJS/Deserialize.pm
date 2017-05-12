#
# This file is part of CatalystX-ExtJS-Direct
#
# This software is Copyright (c) 2014 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Action::ExtJS::Deserialize;
$CatalystX::Action::ExtJS::Deserialize::VERSION = '2.1.5';
# ABSTRACT: Skip deserialization for uploads
use strict;
use warnings;

use base 'Catalyst::Action::Deserialize';
use Catalyst::Utils;
use Carp;

my @traits = qw(Catalyst::TraitFor::Request::REST CatalystX::TraitFor::Request::ExtJS);

# not sure if this is the best place to mess with the request class

sub new {
    my $class    = shift;
    my ($config) = @_;
    $class->apply_request_trait(@_);
    return $class->next::method(@_);
}

sub apply_request_trait {
    my $class = shift;
    my ($config) = @_;
    my $app      = Catalyst::Utils::class2appclass( $config->{class} );
    unless ( $app && $app->can('request_class') ) {
        croak q(Couldn't set the request class. Use REST::ExtJS from your application classes only!);
    }

    my $req_class = $app->request_class;
    
    return if($req_class->does('Catalyst::TraitFor::Request::REST') && $req_class->does('CatalystX::TraitFor::Request::ExtJS'));

    my $meta = $req_class->meta->create_anon_class(
        superclasses => [$req_class],
        roles        => [@traits],
        cache        => 1
    );
    $meta->make_immutable;
    $app->request_class( $meta->name );
}

sub execute {
    my ( $self, $controller, $c ) = @_;
    
    if (   $c->req->is_ext_upload )
    {
        unshift(@{$c->req->accepted_content_types}, 'application/json');
        return 1;
    }
    else {
        return $self->next::method( $controller, $c );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CatalystX::Action::ExtJS::Deserialize - Skip deserialization for uploads

=head1 VERSION

version 2.1.5

=head1 PUBLIC METHODS

=head2 execute

Stops further deserialisation if the current request looks like a request
from ExtJS and has multipart form data, so usually an upload.

=cut

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
