use strict;
use warnings;

use inc::latest 'Module::Build';

use lib qw(inc);
use Alien::V8::Build;

Alien::V8::Build->new(
    module_name => "Alien::V8",
    license => "perl",
    share_dir => "share",
    requires => {
        "Archive::Tar" => '1.38',
        "IPC::Cmd" => '0.42'
    }
)->create_build_script;
