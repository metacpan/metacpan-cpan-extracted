#!perl

use strict;
use warnings;

use Test::MockObject::Extends;
use Test::More 'no_plan';

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Static::TT" ) }

my $c = Test::MockObject::Extends->new($m);

$c->set_always( config => my $config = {} );
$c->set_always( debug  => 0 );

my @compiled;
$c->mock(
  _compile_static_tt_file => sub {
    shift;
    push @compiled, [ @_ ],
  },
);

$config->{root} = File::Spec->catdir(qw(t root));

my @TESTS = (
  { 
    name   => "basic",
    files  => [
      [ 'static/1.txt.tt',        't/root/static/1.txt' ],
      [ 'static/subdir/2.txt.tt', 't/root/static/subdir/2.txt' ],
    ],
  },

  {
    name   => "output_name",
    config => {
      output_name => sub {
        shift; # ipath
        my $dir = shift;
        File::Spec->catfile(
          $dir, "foo", @_
        ),
      },
    },
    files => [
      [ 'static/1.txt.tt',        'static/foo/1.txt' ],
      [ 'static/subdir/2.txt.tt', 'static/foo/subdir/2.txt' ],
    ],
  },
);

for my $Test (@TESTS) {
  @compiled = ();
  $config->{static_tt} = $Test->{config};
  $c->setup;

  #use Data::Dumper;
  #diag Dumper($config);

  is_deeply(
    \@compiled,
    $Test->{files},
    "$Test->{name}: compiled correct files to destinations",
  );
}
