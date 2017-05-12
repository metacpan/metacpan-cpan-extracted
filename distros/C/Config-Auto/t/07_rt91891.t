use strict;
use warnings;
use Config::Auto;
use File::Spec;
use Test::More 'no_plan';

BEGIN { chdir 't' if -d 't'; }

my $expecting = {
  'SOME_SETTING' => [
    '/a/b/c '
  ],
};

my $ca = Config::Auto->new(
  source => File::Spec->catfile( 'src', '07_rt91891.conf' ),
);

my $config = $ca->parse;
ok( $config, 'Got config' );
is( ref($config), 'HASH', 'Got hash' );
is_deeply( $config, $expecting, 'It looks like it should' );
