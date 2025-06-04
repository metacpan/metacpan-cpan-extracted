use Object::Pad;

package App::BS::Common;
role App::BS::Common : does(BS::Common) : does(BS::Path);

use utf8;
use v5.40;

use Carp;
use IPC::Run3;
use TOML::Tiny;
use Const::Fast;
use List::Util qw(uniq any);
use Struct::Dumb;
use Data::Printer;
use Syntax::Keyword::Dynamically;

const our $DEFAULT_ENVPREFIXRE => qr/^(?:BS_)?(.+)/;
const our $DEFAULT_CONFIGPATH  => '/etc/bs/config.toml';

field $config_path : param(config) : mutator =
  [ BS::Path->path($DEFAULT_CONFIGPATH) ];

field $config;
field $getopts_setup : param(getopts) : accessor;
field $cliopts : param(dest) : mutator = {};
field $aliases                         = {};
field $queue : mutator                 = ();

field $env : mutator = {
    pkgext              => '.pkg.tar.zst',
    debug               => 0,
    charset             => 'utf-8',
    default_config_path => $DEFAULT_CONFIGPATH,
    arch                => $cliopts->%{enabled_targets} // [
        $$cliopts{target} // $ENV{CARCH} // qw(x86_64 x86_64_v3 aarch64 armv7l)
    ]
};

ADJUST {
    use utf8;
    use v5.40;
    $ENV{DEBUG} = $self->debug = $BS::Common::DEBUG
};
