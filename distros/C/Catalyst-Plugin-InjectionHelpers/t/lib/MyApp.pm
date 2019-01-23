package MyApp;

use Catalyst 'ConfigLoader', 
  'InjectionHelpers';

MyApp->config(
  'Model::Foo' => {
    -inject => {
      from_code => sub {
        my ($app, %args) = @_;
        return bless +{ %args, app=>$app }, 'Dummy1';
      },
    },
    bar => 'baz',
  },
);

MyApp->setup;
