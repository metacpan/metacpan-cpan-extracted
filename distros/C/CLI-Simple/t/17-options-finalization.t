use strict;
use warnings;

use Test::More;
use Role::Tiny::With;

{
  package Local::Finalization;
  use Role::Tiny::With;
  with 'CLI::Simple::Options';

  sub new {
    my ( $class, $metadata ) = @_;
    return bless { _cli_simple_option_metadata => $metadata }, $class;
  }

  sub get_port   { return $_[0]->{port}; }
  sub set_port   { $_[0]->{port} = $_[1]; return $_[0]->{port}; }
  sub get_config { return $_[0]->{config}; }
  sub set_config { $_[0]->{config} = $_[1]; return $_[0]->{config}; }
  sub get_name   { return $_[0]->{name}; }
  sub set_name   { $_[0]->{name} = $_[1]; return $_[0]->{name}; }
}

subtest 'validation occurs before finalization' => sub {
  my $calls = 0;
  my ( undef, $metadata ) = Local::Finalization->normalize_option_specs({
    'port=i' => {
      min => 1,
      finalize => sub { $calls++; return sprintf q{tcp:%s}, $_[1]; },
    },
  });
  my $obj = Local::Finalization->new($metadata);
  $obj->{port} = 0;
  my $ok = eval { $obj->validate_options; $obj->finalize_options; 1 };
  ok( !$ok, 'invalid value fails' );
  is( $calls, 0, 'finalizer not called for invalid value' );
  $obj->{port} = 8080;
  ok( eval { $obj->validate_options; $obj->finalize_options; 1 }, 'valid value finalized' );
  is( $obj->get_port, 'tcp:8080', 'return value replaces numeric value without revalidation' );
  is( $calls, 1, 'callback called once' );
};

subtest 'optional undef and reference output' => sub {
  my $calls = 0;
  my ( undef, $metadata ) = Local::Finalization->normalize_option_specs({
    'config=s' => { finalize => sub { $calls++; return { path => $_[1] }; } },
  });
  my $obj = Local::Finalization->new($metadata);
  $obj->validate_options->finalize_options;
  is( $calls, 0, 'undefined optional value skipped' );
  $obj->{config} = 'settings.json';
  $obj->validate_options->finalize_options;
  is_deeply( $obj->get_config, { path => 'settings.json' }, 'reference result retained' );
};

subtest 'finalizer only and undef result' => sub {
  my ( undef, $metadata ) = Local::Finalization->normalize_option_specs({
    'name=s' => { finalize => sub { return undef; } },
  });
  my $obj = Local::Finalization->new($metadata);
  $obj->{name} = 'example';
  $obj->validate_options->finalize_options;
  ok( !defined $obj->get_name, 'undefined callback result is authoritative' );
};

subtest 'invalid callback and exceptions' => sub {
  my $ok = eval {
    Local::Finalization->normalize_option_specs({ 'name=s' => { finalize => 'not-code' } });
    1;
  };
  ok( !$ok, 'non-code callback rejected' );
  like( $@, qr/finalize must be a code reference/, 'useful declaration error' );

  my ( undef, $metadata ) = Local::Finalization->normalize_option_specs({
    'name=s' => { finalize => sub { die "bad content\n"; } },
  });
  my $obj = Local::Finalization->new($metadata);
  $obj->{name} = 'example';
  $ok = eval { $obj->validate_options->finalize_options; 1 };
  ok( !$ok, 'finalizer exception propagates' );
  like( $@, qr/Finalization failed for option 'name': bad content/, 'error includes option' );
  is( $obj->get_name, 'example', 'failed finalizer does not overwrite the value' );
};

done_testing;
1;
