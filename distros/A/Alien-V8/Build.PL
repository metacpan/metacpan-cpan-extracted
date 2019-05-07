use strict;
use warnings;

use lib '.';
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
    },
    meta_merge => {
      "meta-spec" => { version => 2 },
      dynamic_config => 0,
      resources => {
        x_IRC => 'irc://irc.perl.org/#v8',
        repository => {
          type => 'git',
          url => 'git@github.com:mohawk2/Alien-V8.git',
          web => 'https://github.com/mohawk2/Alien-V8',
        },
        bugtracker  => {
          web => 'https://github.com/mohawk2/Alien-V8/issues',
        },
        license => [ 'http://dev.perl.org/licenses/' ],
      },
    },
)->create_build_script;
