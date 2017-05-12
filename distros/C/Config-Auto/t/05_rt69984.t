use strict;
use warnings;
use Config::Auto;
use File::Spec;
use Test::More 'no_plan';

BEGIN { chdir 't' if -d 't'; }

my $expecting = {
  'backup.jobs.list' => [
             'production',
             'development',
             'infrastructure',
             'jaguararray'
  ],
  'foo' => 'bar'
};

my $ca = Config::Auto->new(
  source => File::Spec->catfile( 'src', '05_rt69984.conf' ),
  format => 'equal',
);

my $config = $ca->parse;
ok( $config, 'Got config' );
is( ref($config), 'HASH', 'Got hash' );
is_deeply( $config, $expecting, 'It looks like it should' );
