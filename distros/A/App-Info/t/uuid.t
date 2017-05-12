#!/usr/bin/perl -w

use strict;
use Test::More tests => 23;
use File::Spec::Functions;

FAKEMOD: {
    # Fake presence of OSSP::uuid so that we can tell whether it's loaded.
    package OSSP::uuid;
    use File::Spec::Functions;
    $INC{ catfile qw(OSSP uuid.pm) } = __FILE__;
}

BEGIN { use_ok('App::Info::Lib::OSSPUUID') }

my $ext     = $^O eq 'MSWin32' ? '.bat' : '';
my $bin_dir = catdir 't', 'scripts';
$bin_dir    = catdir 't', 'bin' unless -d $bin_dir;
my $exe     = catfile $bin_dir, "myuuid$ext";

ok my $uuid = App::Info::Lib::OSSPUUID->new(
    search_bin_dirs   => $bin_dir,
    search_exe_names  => "uuid-config$ext",
    search_uuid_names => "myuuid$ext",
), 'Got Object';

isa_ok $uuid, 'App::Info::Lib::OSSPUUID';
isa_ok $uuid, 'App::Info::Lib';
isa_ok $uuid, 'App::Info';

is $uuid->key_name,      'OSSP UUID', 'Check key name';
ok $uuid->installed,                  'OSSP UUID is installed';
is $uuid->name,          'OSSP uuid', 'Get name';
is $uuid->version,       '1.3.0',     'Test Version';
is $uuid->major_version, '1',         'Test major version';
is $uuid->minor_version, '3',         'Test minor version';
is $uuid->patch_version, '0',         'Test patch version';
is $uuid->lib_dir,       't/testlib', 'Test lib dir';
is $uuid->executable,    $exe,        'Test executable';
is $uuid->uuid,          $exe,        'Test uuid';
is $uuid->bin_dir,       $bin_dir,    'Test bin dir';
is $uuid->so_lib_dir,    't/testlib', 'Test so lib dir';
is $uuid->inc_dir,       't/testinc', 'Test inc dir';
is $uuid->cflags,        '-I/usr/local/include', 'Test configure';
is $uuid->ldflags,       '-L/usr/local/lib',     'Test configure';
ok $uuid->perl_module,                'OSSP::uuid should appear to be installed';

is $uuid->home_url,      'http://www.ossp.org/pkg/lib/uuid/', 'Get home URL';
is $uuid->download_url,  'http://www.ossp.org/pkg/lib/uuid/', 'Get download URL';
