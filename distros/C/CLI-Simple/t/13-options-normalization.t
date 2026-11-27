use strict;
use warnings;

use Test::More;
use Role::Tiny::With;

{
  package Local::NormalizeOptions;
  use Role::Tiny::With;
  with 'CLI::Simple::Options';
}

subtest 'legacy array is preserved and not modified' => sub {
  my $input = [ qw(help|h port|p=i) ];
  my ( $specs, $metadata ) = Local::NormalizeOptions->normalize_option_specs($input);
  is_deeply( $specs, $input, 'same specifications' );
  is( $metadata->{help}{type}, 'boolean', 'flag type inferred' );
  is( $metadata->{port}{type}, 'integer', 'integer type inferred' );
  isnt( $specs, $input, 'separate array reference' );
};

subtest 'metadata is associated with normalized canonical name' => sub {
  my ($specs, $metadata) = Local::NormalizeOptions->normalize_option_specs({
    'port-number|p=i' => { description => 'Listen port', min => 1, max => 65535 },
  });
  is_deeply( $specs, ['port-number|p=i'], 'parsing specification retained' );
  is_deeply( $metadata->{'port_number'}, {
    spec => 'port-number|p=i', description => 'Listen port', min => 1, max => 65535,
    type => 'integer', inferred_type => 'integer',
  }, 'metadata preserved' );
};

subtest 'declaration errors' => sub {
  foreach my $bad ( undef, 1, 'port=i', [] ) {
    next if ref $bad;
    my $ok = eval { Local::NormalizeOptions->normalize_option_specs($bad); 1 };
    ok( !$ok, 'invalid input rejected' );
  }
  my $ok = eval { Local::NormalizeOptions->normalize_option_specs({ 'port=i' => [] }); 1 };
  ok( !$ok, 'nonhash metadata rejected' );
  $ok = eval { Local::NormalizeOptions->normalize_option_specs({
    'port|p=i' => {}, 'port|q=i' => {},
  }); 1 };
  ok( !$ok, 'duplicate canonical name rejected' );
};

subtest 'type inference and explicit override' => sub {
  my ( $specs, $metadata ) = Local::NormalizeOptions->normalize_option_specs({
    'name|n=s' => { description => 'Name' },
    'ratio:f'  => {},
    'limit:i'  => {},
    'verbose!' => {},
    'debug+'   => {},
    'output=s' => { type => 'directory' },
    'items=s@' => {},
    'lookup=s%' => {},
    'other=o'  => {},
  });
  is( $metadata->{name}{type}, 'string', 'string inferred' );
  is( $metadata->{ratio}{type}, 'number', 'optional float inferred' );
  is( $metadata->{limit}{type}, 'integer', 'optional integer inferred' );
  is( $metadata->{verbose}{type}, 'boolean', 'negatable flag inferred' );
  is( $metadata->{debug}{type}, 'integer', 'incremental counter inferred as integer' );
  is( $metadata->{output}{type}, 'directory', 'explicit type retained' );
  is( $metadata->{output}{inferred_type}, 'string', 'parsing type retained separately' );
  is( $metadata->{items}{type}, 'string', 'repeatable string inferred' );
  is( $metadata->{lookup}{type}, 'string', 'hash destination string inferred' );
  ok( !exists $metadata->{other}{type}, 'unknown syntax not guessed' );
};

done_testing;
1;
