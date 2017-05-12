#!/usr/bin/perl -w

use strict;
use Test::More tests => 33;
use File::Spec::Functions;

BEGIN { use_ok('App::Info::HTTPD::Apache') }

my $ext = $^O eq 'MSWin32' ? '.bat' : '';
my $bin_dir = catdir 't', 'scripts';
$bin_dir = catdir 't', 'bin' unless -d $bin_dir;
my $conf_dir = catdir 't', 'testlib';
my $inc_dir = catdir 't', 'testinc';
# Win32 Thinks the bin directory is the root.
my $httpd_root = $^O eq 'MSWin32' ? $bin_dir : 't';
my %exes = (
    map { $_ => catfile $bin_dir, "$_$ext" }
      qw(httpd myapxs)
);

my @mods = qw(http_core mod_env mod_log_config mod_mime mod_negotiation
              mod_status mod_include mod_autoindex mod_dir mod_cgi mod_asis
              mod_imap mod_actions mod_userdir mod_alias mod_rewrite
              mod_access mod_auth mod_so mod_setenvif mod_ssl mod_perl);

ok( my $apache = App::Info::HTTPD::Apache->new(
    search_bin_dirs   => $bin_dir,
    search_exe_names  => "httpd$ext",
    search_apxs_names => "myapxs$ext",
    search_conf_dirs  => $conf_dir,
    search_lib_dirs   => $conf_dir,
    search_inc_dirs   => $inc_dir,
), "Got Object");
isa_ok($apache, 'App::Info::HTTPD::Apache');
isa_ok($apache, 'App::Info');

is( $apache->key_name, 'Apache', "Check key name" );
ok( $apache->installed, "Apache is installed" );
is( $apache->name, "Apache", "Get name" );
is( $apache->version, "1.3.31", "Test Version" );
is( $apache->major_version, '1', "Test major version" );
is( $apache->minor_version, '3', "Test minor version" );
is( $apache->patch_version, '31', "Test patch version" );
is( $apache->httpd_root, $httpd_root, "Test httpd root" );
ok( $apache->mod_perl, "Test mod_perl" );
is( $apache->conf_file, catfile(qw(t testlib httpd.conf)), "Test conf file" );
is( $apache->user, "nobody", "Test user" );
is( $apache->group, "nobody", "Test group" );
is( $apache->compile_option('DEFAULT_ERRORLOG'), 'logs/error_log',
    "Check error log from compile_option()" );
is( $apache->lib_dir, $conf_dir, "Test lib dir" );
is( $apache->bin_dir, $bin_dir, "Test bin dir" );
is( $apache->executable, $exes{httpd}, "Test executable" );
is( $apache->httpd, $exes{httpd}, "Test httpd" );
is( $apache->apxs, $exes{myapxs}, "Test apxs" );
is( $apache->so_lib_dir, $conf_dir, "Test so lib dir" );
is( $apache->inc_dir, $inc_dir, "Test inc dir" );
ok( eq_set( scalar $apache->static_mods, \@mods, ), "Check static mods" );
is( $apache->magic_number, '19990320:16', "Test magic number" );
is( $apache->port, '80', "Test port" );
is( $apache->doc_root, '/test/doc/root', 'Test doc_root' );
is( $apache->cgibin_virtual, '/test/cgi-bin/', 'Test cgibin_virtual');
is( $apache->cgibin_physical, '/this/is/a/test/cgi-bin/', 'Test cgibin_physical');
ok( $apache->mod_so, "Test mod_so" );
is( $apache->home_url, 'http://httpd.apache.org/', "Get home URL" );
is( $apache->download_url, 'http://www.apache.org/dist/httpd/',
    "Get download URL" );
