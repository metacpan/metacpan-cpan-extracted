package Catalyst::Action::SerializeBase;
$Catalyst::Action::SerializeBase::VERSION = '1.20';
use Moose;
use namespace::autoclean;

extends 'Catalyst::Action';
use Module::Pluggable::Object;
use Catalyst::Request::REST;
use Catalyst::Utils ();

after BUILDARGS => sub {
    my $class  = shift;
    my $config = shift;
    Catalyst::Request::REST->_insert_self_into( $config->{class} );
};

has [qw(_serialize_plugins _loaded_plugins)] => ( is => 'rw' );

sub _load_content_plugins {
    my $self = shift;
    my ( $search_path, $controller, $c ) = @_;

    unless ( defined( $self->_loaded_plugins ) ) {
        $self->_loaded_plugins( {} );
    }

    # Load the Serialize Classes
    unless ( defined( $self->_serialize_plugins ) ) {
        my @plugins;
        my $mpo =
          Module::Pluggable::Object->new( 'search_path' => [$search_path], );
        @plugins = $mpo->plugins;
        $self->_serialize_plugins( \@plugins );
    }

    # Finally, we load the class.  If you have a default serializer,
    # and we still don't have a content-type that exists in the map,
    # we'll use it.
    my $sclass = $search_path . "::";
    my $sarg;
    my $map;

    my $config;
    
    if ( exists $controller->{'serialize'} ) {
        $c->log->info("Catalyst::Action::REST - deprecated use of 'serialize' for configuration.");
        $c->log->info("Please see 'CONFIGURATION' in Catalyst::Controller::REST.");
        $config = $controller->{'serialize'};
        # if they're using the deprecated config, they may be expecting a
        # default mapping too.
        $config->{map} ||= $controller->{map};
    } else {
        $config = $controller;
    }
    $map = $config->{'map'};

    # pick preferred content type
    my @accepted_types; # priority order, best first
    # give top priority to content type specified by stash, if any
    my $content_type_stash_key = $config->{content_type_stash_key};
    if ($content_type_stash_key
        and my $stashed = $c->stash->{$content_type_stash_key}
    ) {
        # convert to array if not already a ref
        $stashed = [ $stashed ] if not ref $stashed;
        push @accepted_types, @$stashed;
    }
    # then content types requested by caller
    push @accepted_types, @{ $c->request->accepted_content_types };
    # then the default
    push @accepted_types, $config->{'default'} if $config->{'default'};
    # pick the best match that we have a serializer mapping for
    my ($content_type) = grep { $map->{$_} } @accepted_types;

    return $self->unsupported_media_type($c, $content_type)
        if not $content_type;

    # carp about old text/x-json
    if ($content_type eq 'text/x-json') {
        $c->log->info('Using deprecated text/x-json content-type.');
        $c->log->info('Use application/json instead!');
    }

    if ( exists( $map->{$content_type} ) ) {
        my $mc;
        if ( ref( $map->{$content_type} ) eq "ARRAY" ) {
            $mc   = $map->{$content_type}->[0];
            $sarg = $map->{$content_type}->[1];
        } else {
            $mc = $map->{$content_type};
        }
        # TODO: Handle custom serializers more elegantly.. this is a start,
        # but how do we determine which is Serialize and Deserialize?
        #if ($mc =~ /^+/) {
        #    $sclass = $mc;
        #    $sclass =~ s/^+//g;
        #} else {
        $sclass .= $mc;
        #}
        if ( !grep( /^$sclass$/, @{ $self->_serialize_plugins } ) ) {
            return $self->unsupported_media_type($c, $content_type);
        }
    } else {
        return $self->unsupported_media_type($c, $content_type);
    }
    unless ( exists( $self->_loaded_plugins->{$sclass} ) ) {
        my $load_class = $sclass;
        $load_class =~ s/::/\//g;
        $load_class =~ s/$/.pm/g;
        eval { require $load_class; };
        if ($@) {
            $c->log->error(
                "Error loading $sclass for " . $content_type . ": $!" );
            return $self->unsupported_media_type($c, $content_type);
        } else {
            $self->_loaded_plugins->{$sclass} = 1;
        }
    }

    if ($search_path eq "Catalyst::Action::Serialize") {
        unless( $c->response->header( 'Vary' ) ) {
            if ($content_type) {
                $c->response->header( 'Vary' => 'Content-Type' );
            } elsif ($c->request->accept_only) {
                $c->response->header( 'Vary' => 'Accept' );
            }
        }
        $c->response->content_type($content_type);
    }

    return $sclass, $sarg, $content_type;
}

sub unsupported_media_type {
    my ( $self, $c, $content_type ) = @_;
    $c->res->content_type('text/plain');
    $c->res->status(415);
    if (defined($content_type) && $content_type ne "") {
        $c->res->body(
            "Content-Type " . $content_type . " is not supported.\r\n" );
    } else {
        $c->res->body(
            "Cannot find a Content-Type supported by your client.\r\n" );
    }
    return undef;
}

sub serialize_bad_request {
    my ( $self, $c, $content_type, $error ) = @_;
    $c->res->content_type('text/plain');
    $c->res->status(400);
    $c->res->body(
        "Content-Type " . $content_type . " had a problem with your request.\r\n***ERROR***\r\n$error" );
    return undef;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Catalyst::Action::SerializeBase - Base class for Catalyst::Action::Serialize and Catlayst::Action::Deserialize.

=head1 DESCRIPTION

This module implements the plugin loading and content-type negotiating
code for L<Catalyst::Action::Serialize> and L<Catalyst::Action::Deserialize>.

=head1 SEE ALSO

L<Catalyst::Action::Serialize>, L<Catalyst::Action::Deserialize>,
L<Catalyst::Controller::REST>,

=head1 AUTHORS

See L<Catalyst::Action::REST> for authors.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
