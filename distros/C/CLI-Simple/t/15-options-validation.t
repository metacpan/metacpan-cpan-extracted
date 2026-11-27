use strict;
use warnings;

use Test::More;
use Role::Tiny::With;

{
  package Local::OptionValidation;
  use Role::Tiny::With;
  with 'CLI::Simple::Options';
  sub new { return bless { _cli_simple_option_metadata => $_[1] }, $_[0]; }
  sub get_port { return $_[0]->{port}; }
  sub get_name { return $_[0]->{name}; }
  sub get_mode { return $_[0]->{mode}; }
  sub get_items { return $_[0]->{items}; }
  sub get_tags { return $_[0]->{tags}; }
}

subtest 'source-independent requiredness and bounds' => sub {
  my ( $specs, $meta ) = Local::OptionValidation->normalize_option_specs({
    'port|p=i' => { required => 1, min => 1, max => 65535 },
  });
  my $obj = Local::OptionValidation->new($meta);
  eval { $obj->validate_options; 1 };
  like( $@, qr/Required option 'port' is undefined/, 'undef fails required' );
  $obj->{port} = 0;
  eval { $obj->validate_options; 1 };
  like( $@, qr/must be >= 1/, 'defined zero passes requiredness, fails min' );
  $obj->{port} = 8080;
  ok( eval { $obj->validate_options; 1 }, 'valid resolved value accepted' );
  $obj->{port} = 'bad';
  eval { $obj->validate_options; 1 };
  like( $@, qr/must be an integer/, 'type checked' );
};

subtest 'optional, enum and length' => sub {
  my ( undef, $meta ) = Local::OptionValidation->normalize_option_specs({
    'name=s' => { min_length => 2, max_length => 4 },
    'mode=s' => { enum => [qw(dev prod)] },
  });
  my $obj = Local::OptionValidation->new($meta);
  ok( eval { $obj->validate_options; 1 }, 'undefined optional options accepted' );
  $obj->{name} = '';
  eval { $obj->validate_options; 1 };
  like( $@, qr/shorter than/, 'empty defined string checked for length' );
  $obj->{name} = 'demo';
  $obj->{mode} = 'stage';
  eval { $obj->validate_options; 1 };
  like( $@, qr/unrecognized value/, 'enum rejected' );
  $obj->{mode} = 'prod';
  ok( eval { $obj->validate_options; 1 }, 'all constraints satisfied' );
};

subtest 'collection shape and per-element constraints' => sub {
  my ( undef, $meta ) = Local::OptionValidation->normalize_option_specs({
    'items=i@' => { min => 1 },
    'tags=s%' => { enum => [qw(ok yes)] },
  });
  my $obj = Local::OptionValidation->new($meta);
  $obj->{items} = [ 1, 2 ];
  $obj->{tags} = { a => 'ok' };
  ok( eval { $obj->validate_options; 1 }, 'collections accepted' );
  $obj->{items} = [ 1, 0 ];
  eval { $obj->validate_options; 1 };
  like( $@, qr/must be >= 1/, 'array element validated' );
  $obj->{items} = [ 1 ];
  $obj->{tags} = [ 'ok' ];
  eval { $obj->validate_options; 1 };
  like( $@, qr/requires a hash reference/, 'incorrect collection type rejected' );
};

subtest 'invalid declarations fail during normalization' => sub {
  for my $definition (
    { 'port=i' => { min => 5, max => 1 } },
    { 'port=i' => { min_length => 1 } },
    { 'port=i' => { type => 'directory' } },
    { 'port=i' => { enum => [] } },
    { 'port=i' => { required => 2 } },
  ) {
    my $ok = eval { Local::OptionValidation->normalize_option_specs($definition); 1 };
    ok( !$ok, 'invalid declaration rejected' );
  }
};

done_testing;
1;
