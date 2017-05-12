package TestApp;

use Moose;
use namespace::autoclean;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
  name => 'TestApp',
  'Plugin::I18N::PathPrefixGeoIP' => {
    valid_languages => ['en', 'de', 'fr', 'IT'],
    fallback_language => 'en',
    language_independent_paths => qr{
      ^ language_independent_stuff
    }x,
    geoip_db => 'data/GeoLiteCity.dat',
  },
);

__PACKAGE__->setup( qw(I18N I18N::PathPrefixGeoIP) );

has language_prefix_debug_messages => (
  isa => 'ArrayRef[Str]',
  traits => ['Array'],
  is => 'ro',
  default => sub { [] },
  handles => {
    clear_language_prefix_debug_messages => 'clear',
    append_to_language_prefix_debug_messages => 'push',
  },
  documentation =>
    'The messages logged by the C:P::I18N::PathPrefixGeoIP module.',
);

before prepare_request => sub {
  my ($self) = @_;

  $self->clear_language_prefix_debug_messages;
};

before _language_prefix_debug => sub {
  my ($self, $msg) = @_;

  $self->append_to_language_prefix_debug_messages(debug => $msg);
};

__PACKAGE__->meta->make_immutable;

1;
