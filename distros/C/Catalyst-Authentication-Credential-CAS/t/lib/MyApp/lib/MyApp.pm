package MyApp;

use namespace::autoclean;
use Moose;

use Catalyst::Runtime 5.80;
use Catalyst qw( Authentication );

extends qw( Catalyst );

our $VERSION = '0.01';
$VERSION = eval $VERSION;


__PACKAGE__->config(
  name => 'MyApp',
  disable_component_resolution_regex_fallback => 1,
  'Plugin::Authentication' => {
    default_realm => 'default',
    use_session   => 0,
    default       => {
      credential => {
        class   => 'CAS',
        uri     => 'uri://cas',
        version => $ENV{_CAS_VERSION},
      },
      store => {
        class => 'Minimal',
        users => {
          user => { name => 'User' },
        },
      },
    },
  },
);


__PACKAGE__->setup();

1
__END__
