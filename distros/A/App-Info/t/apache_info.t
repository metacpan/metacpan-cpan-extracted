#!/usr/bin/perl -w

use strict;
use Test::More tests => 79;
use lib 't/lib';
use File::Spec::Functions;

use EventTest;

##############################################################################
BEGIN { use_ok('App::Info::HTTPD::Apache') }

my $ext        = $^O eq 'MSWin32' ? '.bat' : '';
my $scripts    = 'scripts';
my $bin_dir    = catdir 't', $scripts;
my $conf_dir   = catdir 't', 'testlib';
my $inc_dir    = catdir 't', 'testinc';
# Win32 Thinks the bin directory is the root.
my $httpd_root = $^O eq 'MSWin32' ? $bin_dir : 't';

unless (-d $bin_dir) {
    $bin_dir = catdir 't', 'bin';
    $scripts = 'bin';
}

my @params = (
    search_bin_dirs   => $bin_dir,
    search_exe_names  => "httpd$ext",
    search_apxs_names => "myapxs$ext",
    search_conf_dirs  => $conf_dir,
    search_lib_dirs   => $conf_dir,
    search_inc_dirs   => $inc_dir,
);

# Test info events.
ok( my $info = EventTest->new, "Create info EventTest" );
ok( my $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object");

is( $info->message, "Looking for Apache executable",
    "Check constructor info" );

##########################################################################
# Check name.
$apache->name;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -v`$/,
     "Check name info" );
$apache->name;
ok( ! defined $info->message, "No info" );
$apache->version;
ok( ! defined $info->message, "Still No info" );

##########################################################################
# Check version.
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 2");
$info->message; # Throw away constructor message.
$apache->version;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -v`$/,
     "Check version info" );

$apache->version;
ok( ! defined $info->message, "No info" );
$apache->major_version;
ok( ! defined $info->message, "Still No info" );

##########################################################################
# Check major version.
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 3");
$info->message; # Throw away constructor message.
$apache->major_version;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -v`$/,
     "Check major info" );

##########################################################################
# Check minor version.
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 4");
$info->message; # Throw away constructor message.
$apache->minor_version;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -v`$/,
     "Check minor info" );

##########################################################################
# Check patch version.
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 5");
$info->message; # Throw away constructor message.
$apache->patch_version;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -v`$/,
     "Check patch info" );

##########################################################################
# Check inc_dir method.
$apache->inc_dir;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -V`$/,
      "Check inc_dir info" );
is( $info->message, "Searching for include directory",
    "Check inc info again" );
ok( ! defined $info->message, "No more inc info" );
$apache->inc_dir;
ok( ! defined $info->message, "Still no more inc info" );

# Try again with a new object.
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 7");
$info->message; # Throw away constructor message.

$apache->inc_dir;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -V`$/,
      "Check inc info new" );
is( $info->message, "Searching for include directory",
    "Check inc info again" );
ok( ! defined $info->message, "No more inc new info" );

##########################################################################
# Check lib_dir method.
$apache->lib_dir;
is( $info->message, "Searching for library directory",
    "Check lib info again" );
ok( ! defined $info->message, "No more lib info" );
$apache->lib_dir;
ok( ! defined $info->message, "Still no more lib info" );

# Try again with a new object.
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 8");
$info->message; # Throw away constructor message.

$apache->lib_dir;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -V`$/,
      "Check lib info new" );
is( $info->message, "Searching for library directory",
    "Check lib info again" );
ok( ! defined $info->message, "No more lib new info" );

##########################################################################
# Test httpd_root().
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 9");
$info->message; # Throw away constructor message.

$apache->httpd_root;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -V`$/,
      "Check httpd_root info" );
ok( ! defined $info->message, "No more httpd_root info" );
$apache->httpd_root;
ok( ! defined $info->message, "Still no httpd_root info" );

##########################################################################
# Test magic_number().
$apache->magic_number;
ok( ! defined $info->message, "No magic_number info" );
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 10");
$info->message; # Throw away constructor message.
$apache->magic_number;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -V`$/,
      "Check magic_number info" );
ok( ! defined $info->message, "No more magic_number info" );

##########################################################################
# Test compile_option().
$apache->compile_option('foo');
ok( ! defined $info->message, "No compile_option info" );
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 10");
$info->message; # Throw away constructor message.
$apache->compile_option('foo');
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -V`$/,
      "Check compile_option info" );
ok( ! defined $info->message, "No more compile_option info" );

##########################################################################
# Test conf_file().
$apache->conf_file;
is( $info->message, "Searching for Apache configuration file",
    "Check conf_file info" );
ok( ! defined $info->message, "No more conf_file info" );
$apache->conf_file;
ok( ! defined $info->message, "Still no more conf_file info" );

##########################################################################
# Test user().
$apache->user;
is( $info->message, "Parsing Apache configuration file",
    "Check user info" );
ok( ! defined $info->message, "No more user info" );
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 11");
$info->message; # Throw away constructor message.
$apache->user;
is( $info->message, "Searching for Apache configuration file",
    "Check user info 2" );
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -V`$/,
      "Check user info 3" );
is( $info->message, "Parsing Apache configuration file",
    "Check user info 4" );
ok( ! defined $info->message, "No more user info" );

##########################################################################
# Test group().
$apache->group;
ok( ! defined $info->message, "No group info" );
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 11");
$info->message; # Throw away constructor message.
$apache->group;
is( $info->message, "Searching for Apache configuration file",
    "Check group info 2" );
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -V`$/,
      "Check group info 3" );
is( $info->message, "Parsing Apache configuration file",
    "Check group info 4" );
ok( ! defined $info->message, "No more group info" );

##########################################################################
# Test port().
$apache->port;
ok( ! defined $info->message, "No port info" );
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 11");
$info->message; # Throw away constructor message.
$apache->port;
is( $info->message, "Searching for Apache configuration file",
    "Check port info 2" );
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -V`$/,
      "Check port info 3" );
is( $info->message, "Parsing Apache configuration file",
    "Check port info 4" );
ok( ! defined $info->message, "No more port info" );

##########################################################################
# Tests static_mods().
$apache->static_mods;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -l`$/,
      "Check static_mods info" );
ok( ! defined $info->message, "No more static_mods info" );

##########################################################################
# Tests shared_mods().
$apache->shared_mods;
is( $info->message, 'Looking for apxs',
    'Shared modes should look for apxs' );
like( $info->message,
      qr/^Executing `"t.$scripts.myapxs(?:.bat)?" -q LIBEXECDIR`$/,
      "Check shared_mods info" );
ok( ! defined $info->message, "No more shared_mods info" );

##########################################################################
# Tests mod_so().
$apache->mod_so;
ok( ! defined $info->message, "No mod_so info" );
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 12");
$info->message; # Throw away constructor message.
$apache->mod_so;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -l`$/,
      "Check mod_so info" );
ok( ! defined $info->message, "No more mod_so info" );

##########################################################################
# Tests mod_perl().
$apache->mod_perl;
ok( ! defined $info->message, "No mod_perl info" );
ok( $apache = App::Info::HTTPD::Apache->new( @params, on_info => $info ),
    "Got Object 13");
$info->message; # Throw away constructor message.
$apache->mod_perl;
like($info->message, qr/^Executing `"t.$scripts.httpd(?:.bat)?" -l`$/,
      "Check mod_perl info" );
ok( ! defined $info->message, "No more mod_perl info" );

__END__
