# ABSTRACT: JsonApi helpers for Dancer2 apps

use 5.38.0;

package Dancer2::Plugin::JsonApi;
our $AUTHORITY = 'cpan:YANICK';
$Dancer2::Plugin::JsonApi::VERSION = '0.0.1';
use Dancer2::Plugin::JsonApi::Registry;
use Dancer2::Plugin;
use Dancer2::Serializer::JsonApi;

has registry => (
    plugin_keyword => 'jsonapi_registry',
    is             => 'ro',
    default        => sub ($self) {
        Dancer2::Plugin::JsonApi::Registry->new( app => $self->app );
    }
);

sub jsonapi : PluginKeyword ( $plugin, $type, $sub ) {

    return sub {
        my $result = $sub->();

        return [
            $type => $result,
            {   vars    => $plugin->app->request->vars,
                request => $plugin->app->request
            }
        ];
    };
}

sub BUILD ( $self, @ ) {
    my $serializer = eval {
         $self->app->serializer_engine 
    };

    unless ($serializer) {
        $self->app->set_serializer_engine(
            Dancer2::Serializer::JsonApi->new );
        $serializer = $self->app->serializer_engine;

    }

    $serializer->registry( $self->registry )
      if ref $serializer eq 'Dancer2::Serializer::JsonApi';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::JsonApi - JsonApi helpers for Dancer2 apps

=head1 VERSION

version 0.0.1

=head1 NAME

Dancer2::Plugin::JsonAPI

=head2 DESCRIPTION

If the serializer is not already explicitly set, the plugin will configure it to be L<Dancer2::Serializer::JsonApi>.

=head2 SEE ALSO

=over

=item * The L<JSON:API|https://jsonapi.org> specs, natch.

=item * L<json-api-serializer|https://www.npmjs.com/package/json-api-serializer> My go to for serializing JSON API documents in JavaScript-land. Also, inspiration for this module.

=back

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
