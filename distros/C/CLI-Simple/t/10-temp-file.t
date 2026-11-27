use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);

{

  package Test::TempConsumer;
  use Role::Tiny::With;
  with 'CLI::Simple::TempFile';
  sub new { my ($class) = @_; return bless {}, $class; }
}

{

  package Test::TempScalar;
  use Role::Tiny::With;
  with 'CLI::Simple::TempFile';
  sub new { my ($class) = @_; my $v = 0; return bless \$v, $class; }
}

subtest 'accessor and ownership' => sub {
  my $obj  = Test::TempConsumer->new;
  my $path = $obj->create_temp_file( accessor => 'report', suffix => '.csv' );
  ok( -f $path, 'created' );
  like( $path, qr/\.csv\z/, 'suffix' );
  is( $obj->get_report, $path, 'generated accessor' );
  $obj->set_report('other');
  undef $obj;
  ok( !-e $path, 'original owned path cleaned even after setter changes' );
};

subtest 'multiple resources and no cleanup' => sub {
  my $obj = Test::TempConsumer->new;
  my $a   = $obj->create_temp_file( accessor => 'first' );
  my $b   = $obj->create_temp_file( accessor => 'second', cleanup => 0 );
  isnt( $a, $b, 'distinct paths' );
  is( $obj->get_first,  $a, 'first accessor' );
  is( $obj->get_second, $b, 'second accessor' );
  undef $obj;
  ok( !-e $a, 'first cleaned' );
  ok( -f $b,  'persistent file survives' );
  unlink $b;
};

{

  package Local::NoAccessors;

  use Role::Tiny::With;

  with 'CLI::Simple::TempFile';
}

subtest 'no accessors on hash-based object' => sub {
  my $obj = bless {}, 'Local::NoAccessors';

  my $path = $obj->create_temp_file(
    no_accessors => 1,
    cleanup      => 1,
  );

  ok( -f $path,                    'temporary file created' );
  ok( !$obj->can('get_temp_file'), 'accessor not generated' );

  undef $obj;

  ok( !-e $path, 'temporary file removed when owner is destroyed' );
};

subtest 'validations and collisions' => sub {
  my $obj = Test::TempConsumer->new;
  eval { $obj->create_temp_file( accessor => 'bad-name' ) };
  like( $@, qr/Invalid accessor name/, 'invalid accessor rejected' );
  eval { $obj->create_temp_file( accessor => 'x', no_accessors => 1 ) };
  like( $@, qr/cannot be combined/, 'conflict rejected' );
  eval { $obj->create_temp_file( accessor => 'new', rogue => 1 ) };
  like( $@, qr/Unknown temporary file attribute/, 'unknown attribute rejected' );
  eval { $obj->create_temp_file( accessor => 'report', cleanup => 2 ) };
  like( $@, qr/cleanup must be/, 'invalid cleanup rejected' );
  my $p = $obj->create_temp_file( accessor => 'report' );
  ok( -f $p, 'creates file after invalid attempts' );
};

subtest 'per-instance ownership' => sub {
  my $one = Test::TempConsumer->new;
  my $two = Test::TempConsumer->new;
  my $a   = $one->create_temp_file;
  my $b   = $two->create_temp_file;
  undef $one;
  ok( !-e $a, 'first cleanup' );
  ok( -e $b,  'second still exists' );
  undef $two;
  ok( !-e $b, 'second cleanup' );
};

done_testing;
1;
