package Catalyst::View::Vega;
use strict;
use warnings;
use utf8;
use 5.008_005;
our $VERSION = '0.02';

use Moose;
use Types::Standard qw< :types >;
use JSON::MaybeXS;
use Path::Tiny;
use List::Util qw< first >;
use namespace::autoclean;

=encoding utf-8

=head1 NAME

Catalyst::View::Vega - A Catalyst view for pre-processing Vega specs

=head1 SYNOPSIS

    # In YourApplication.pm
    #
    YourApplication->inject_component( 'View::Vega' => { from_component => 'Catalyst::View::Vega' } );
    YourApplication->config(
        'View::Vega' => {
            path => YourApplication->path_to("root/vega")->stringify,
        }
    );

    # In a controller action
    #
    my $vega = $c->view('Vega');
    $vega->specfile('patient-chart.json');
    $vega->bind_data({
        "patient"     => [{
            id   => $patient->id,
            name => $patient->name,
        }],
        "medications" => [ $meds->all ],
        "samples"     => [ $samples->all ],
    });
    $c->detach($vega);

=head1 DESCRIPTION

This class lets you bind data to the datasets declared in a
L<Vega|https://vega.github.io/vega/> spec and output the spec with the bound
data inlined.  This is useful for inlining data dynamically without using a
templating library.  Inlining data reduces request overhead and creates
standalone Vega specs which can be rendered as easily offline as they are
online.

A new instance of this view is created for each request, so it is safe to set
attributes and use the view's API in multiple controllers or actions.  Each new
view instance is based on the application's global instance of the view so that
initial attribute values are from your application config.

=cut

extends 'Catalyst::View';
with 'Catalyst::Component::InstancePerContext';
with 'MooseX::Clone';

# Create a new instance of this view per request so object attributes are
# per-request.  This lets controllers and actions access the same instance by
# calling $c->view("Vega").
sub build_per_context_instance {
    my ($self, $c, @args) = @_;
    return $self->clone(@args);
}

=head1 ATTRIBUTES

=head2 json

Read-only.  Object with C<encode> and C<decode> methods for reading and writing
JSON.  Defaults to:

    JSON::MaybeXS->new->utf8->convert_blessed->canonical->pretty

You can either set this at application start time via L<Catalyst/config>:

    YourApplication->config(
        'View::Vega' => {
            json => ...
        }
    );

or pass it in during the request-specific object construction:

    my $vega = $c->view("Vega", json => ...);

=head2 path

Read-only.  Filesystem path under which L</specfile>s are located.  Usually set
by your application's config file or via L<Catalyst/config>, e.g.:

    YourApplication->config(
        'View::Vega' => {
            path => YourApplication->path_to("root/vega")->stringify,
        }
    );

=head2 specfile

Read-write.  A file relative to L</path> which contains the Vega spec to
process.  Usually set in your controller's actions.

=cut

has json => (
    is      => 'ro',
    isa     => HasMethods['encode', 'decode'],
    default => sub { JSON->new->utf8->convert_blessed->canonical->pretty },
);

has path => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has specfile => (
    is  => 'rw',
    isa => Str,
);

has _data => (
    is      => 'rw',
    isa     => HashRef,
    default => sub { +{} },
);

=head1 METHODS

=head2 bind_data

Takes a hashref or list of key-value pairs and merges them into the view
object's dataset bindings.

Keys should be dataset names which match those in the Vega L</specfile>.  Any
existing binding in this view for a given dataset name is overwritten.

Values may be either references or strings.  References are serialized and
inlined as the C<values> dataset property.  Strings are serialized as the
C<url> property, which allows you to dynamically reference external datasets.
See L<Vega's documentation on dataset properties|https://github.com/vega/vega/wiki/Data#data-properties>
for more details on the properties themselves.

Note that Vega expects the C<values> property to be an array, although this
view does not enforce that.  Make sure your references are arrayrefs or objects
that serialize to an arrayref.

Returns nothing.

=head2 unbind_data

Takes a dataset name as the sole argument and deletes any data bound in the
view object for that dataset.  Returns the now unbound data, if any.

=cut

sub bind_data {
    my $self = shift;
    my $data = $self->_data;
    if (@_) {
        if (@_ == 1 and ref($_[0]) eq 'HASH') {
            $self->_data({ %$data, %{ $_[0] } });
        }
        elsif (@_ % 2 == 0) {
            $self->_data({ %$data, @_ });
        }
        else {
            die "View::Vega->data() takes a hashref or list of key-value pairs ",
                "but an odd number of arguments were passed";
        }
    }
    return;
}

sub unbind_data {
    my $self = shift;
    my $name = shift;
    return delete $self->_data->{$name};
}

=head2 process_spec

Returns the Vega specification as a Perl data structure, with bound data
inlined into the spec.

=cut

sub process_spec {
    my $self = shift;
    my $spec = $self->read_specfile;

    # Inject data bindings into the Vega spec either as URLs or inline values
    for my $name (keys %{ $self->_data }) {
        my $dataset = first { $_->{name} eq $name } @{ $spec->{data} }
            or die "View::Vega cannot find a dataset named «$name» in the spec";
        my $value   = $self->_data->{$name};
        $dataset->{ ref($value) ? 'values' : 'url' } = $value;
    }

    return $spec;
}

=head2 process

Sets up up a JSON response using the results of L</process_spec>.  You should
usually call this implicitly via L<Catalyst/detach> using the idiom:

    my $vega = $c->view("Vega");
    ...
    $c->detach($vega);

This is the most "viewish" part of this class.

=cut

sub process {
    my ($self, $c) = @_;
    my $res = $c->response;
    $res->content_type('application/json; charset="UTF-8"');
    $res->body( $self->json->encode( $self->process_spec ) );
}

sub read_specfile {
    my ($self, $file) = @_;
    my $spec = path($self->path, $self->specfile);
    return $self->json->decode( $spec->slurp_raw );
}

1;
__END__

=head1 AUTHOR

Thomas Sibley E<lt>trsibley@uw.eduE<gt>

=head1 THANKS

Thanks to Evan Silberman E<lt>silby@uw.eduE<gt> for suggesting dynamic inlining
of datasets.

=head1 COPYRIGHT

Copyright 2016- by the University of Washington

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item L<Vega data specs|https://github.com/vega/vega/wiki/Data>

=item L<Vega documentation|https://github.com/vega/vega/wiki/Documentation>

=item L<Vega|https://vega.github.io/vega/>

=back

=cut
