package Catalyst::Action::Serialize;
$Catalyst::Action::Serialize::VERSION = '1.20';
use Moose;
use namespace::autoclean;

extends 'Catalyst::Action::SerializeBase';
use Module::Pluggable::Object;
use MRO::Compat;

has _encoders => (
   is => 'ro',
   isa => 'HashRef',
   default => sub { {} },
);

sub execute {
    my $self = shift;
    my ( $controller, $c ) = @_;

    $self->maybe::next::method(@_);

    return 1 if $c->req->method eq 'HEAD';
    return 1 if $c->response->has_body;
    return 1 if scalar @{ $c->error };
    return 1 if $c->response->status =~ /^(?:204)$/;
    return 1 if defined $c->stash->{current_view};
    return 1 if defined $c->stash->{current_view_instance};

    # on 3xx responses, serialize if there's something to
    # serialize, no-op if not
    my $stash_key = (
       $controller->{'serialize'} ?
           $controller->{'serialize'}->{'stash_key'} :
                $controller->{'stash_key'}
           ) || 'rest';
    return 1 if $c->response->status =~ /^(?:3\d\d)$/ && ! defined $c->stash->{$stash_key};

    my ( $sclass, $sarg, $content_type ) =
      $self->_load_content_plugins( "Catalyst::Action::Serialize",
        $controller, $c );
    unless ( defined($sclass) ) {
        if ( defined($content_type) ) {
            $c->log->info("Could not find a serializer for $content_type");
        } else {
            $c->log->info(
                "Could not find a serializer for an empty content-type");
        }
        return 1;
    }
    $c->log->debug(
        "Serializing with $sclass" . ( $sarg ? " [$sarg]" : '' ) ) if $c->debug;

    $self->_encoders->{$sclass} ||= $sclass->new;
    my $sobj = $self->_encoders->{$sclass};

    my $rc;
    eval {
        if ( defined($sarg) ) {
            $rc = $sobj->execute( $controller, $c, $sarg );
        } else {
            $rc = $sobj->execute( $controller, $c );
        }
    };
    if ($@) {
        return $self->serialize_bad_request( $c, $content_type, $@ );
    } elsif (!$rc) {
        return $self->unsupported_media_type( $c, $content_type );
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Catalyst::Action::Serialize - Serialize Data in a Response

=head1 SYNOPSIS

    package Foo::Controller::Bar;

    __PACKAGE__->config(
        'default'   => 'text/x-yaml',
        'stash_key' => 'rest',
        'map'       => {
            'text/html'          => [ 'View', 'TT', ],
            'text/x-yaml'        => 'YAML',
            'text/x-data-dumper' => [ 'Data::Serializer', 'Data::Dumper' ],
        }
    );

    sub end :ActionClass('Serialize') {}

=head1 DESCRIPTION

This action will serialize the body of an HTTP Response.  The serializer is
selected by introspecting the HTTP Requests content-type header.

It requires that your Catalyst controller is properly configured to set up the
mapping between Content Type's and Serialization classes.

The specifics of serializing each content-type is implemented as a plugin to
L<Catalyst::Action::Serialize>.

Typically, you would use this ActionClass on your C<end> method.  However,
nothing is stopping you from choosing specific methods to Serialize:

  sub foo :Local :ActionClass('Serialize') {
     .. populate stash with data ..
  }

When you use this module, the request class will be changed to
L<Catalyst::Request::REST>.

=head1 CONFIGURATION

=head2 map

Takes a hashref, mapping Content-Types to a given serializer plugin.

=head2 default

This is the 'fall-back' Content-Type if none of the requested or acceptable
types is found in the L</map>. It must be an entry in the L</map>.

=head2 stash_key

Specifies the key of the stash entry holding the data that is to be serialized.
So if the value is "rest", we will serialize the data under:

  $c->stash->{'rest'}

=head2 content_type_stash_key

Specifies the key of the stash entry that optionally holds an overriding
Content-Type. If set, and if the specified stash entry has a valid value,
then it takes priority over the requested content types.

This can be useful if you want to dynamically force a particular content type,
perhaps for debugging.

=head1 HELPFUL PEOPLE

Daisuke Maki pointed out that early versions of this Action did not play
well with others, or generally behave in a way that was very consistent
with the rest of Catalyst.

=head1 CUSTOM ERRORS

For building custom error responses when serialization fails, you can create
an ActionRole (and use L<Catalyst::Controller::ActionRole> to apply it to the
C<end> action) which overrides C<unsupported_media_type> and/or C<serialize_bad_request>
methods.

=head1 SEE ALSO

You likely want to look at L<Catalyst::Controller::REST>, which implements
a sensible set of defaults for doing a REST controller.

L<Catalyst::Action::Deserialize>, L<Catalyst::Action::REST>

=head1 AUTHORS

See L<Catalyst::Action::REST> for authors.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
