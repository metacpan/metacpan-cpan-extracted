package Example;

use Catalyst;

__PACKAGE__->setup_plugins([qw/Errors/]);
__PACKAGE__->config(
  'View::Errors::JSON' => {extra_encoder_args=>{pretty=>1}},
);
__PACKAGE__->setup();
__PACKAGE__->meta->make_immutable();

