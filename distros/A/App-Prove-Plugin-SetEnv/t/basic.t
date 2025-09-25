use strict;
use warnings;

use Test::More import => [ qw( is ) ], tests => 2;

use App::Prove ();

my $default_PATH = '/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin';
local @ENV{ qw( FOO PATH ) } = ( '', $default_PATH );
my $app = App::Prove->new;
$app->process_args( '-PSetEnv=FOO=bar,PATH=baz:$PATH' );
$app->_load_extensions( $app->plugins, App::Prove::PLUGINS() );

is $ENV{ FOO }, 'bar', 'set new FOO environment variable';
is $ENV{ PATH }, "baz:$default_PATH",
  'expand string in PATH environment variable'
