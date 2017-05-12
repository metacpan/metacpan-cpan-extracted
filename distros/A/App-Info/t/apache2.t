#!/usr/bin/perl -w

use strict;
use Test::More tests => 32;
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
      qw(httpd2 myapxs)
);

my @mods = qw(core mod_access mod_auth mod_log_config mod_setenvif prefork
    http_core mod_mime mod_status mod_autoindex mod_asis mod_cgi
    mod_negotiation mod_dir mod_imap mod_actions mod_userdir mod_alias
    mod_so);
my @so_mods = qw(mod_dir mod_include mod_perl);

ok( my $apache = App::Info::HTTPD::Apache->new(
    search_bin_dirs   => $bin_dir,
    search_exe_names  => "httpd2$ext",
    search_apxs_names => "myapxs$ext",
    search_conf_dirs  => $conf_dir,
    search_lib_dirs   => $conf_dir,
    search_inc_dirs   => $inc_dir,
), "Got Object");
isa_ok($apache, 'App::Info::HTTPD::Apache');
isa_ok($apache, 'App::Info');

is( $apache->key_name, 'Apache', 'Check key name' );
ok( $apache->installed, 'Apache is installed' );
is( $apache->name, 'Apache', 'Get name' );
is( $apache->version, '2.0.55', 'Test Version' );
is( $apache->major_version, '2', 'Test major version' );
is( $apache->minor_version, '0', 'Test minor version' );
is( $apache->patch_version, '55', 'Test patch version' );
is( $apache->httpd_root, $httpd_root, 'Test httpd root' );
ok( $apache->mod_perl, 'Test mod_perl' );
is( $apache->conf_file, catfile(qw(t testlib httpd.conf)), 'Test conf file' );
is( $apache->user, 'nobody', 'Test user' );
is( $apache->group, 'nobody', 'Test group' );
is( $apache->compile_option('DEFAULT_ERRORLOG'), 'logs/error_log',
    'Check error log from compile_option()' );
is( $apache->lib_dir, $conf_dir, 'Test lib dir' );
is( $apache->bin_dir, $bin_dir, 'Test bin dir' );
is( $apache->executable, $exes{httpd2}, 'Test executable' );
is( $apache->httpd, $exes{httpd2}, 'Test httpd' );
is( $apache->apxs, $exes{myapxs}, 'Test apxs' );
is( $apache->so_lib_dir, $conf_dir, 'Test so lib dir' );
is( $apache->inc_dir, $inc_dir, 'Test inc dir' );
is_deeply( scalar $apache->static_mods, \@mods, 'Check static mods' );
is_deeply( [ sort $apache->shared_mods ], \@so_mods, 'Check so mods' );
is( $apache->magic_number, '20020903:11', 'Test magic number' );
is( $apache->port, '80', 'Test port' );
is( $apache->doc_root, '/test/doc/root', 'Test doc_root' );
ok( $apache->mod_so, 'Test mod_so' );
is( $apache->home_url, 'http://httpd.apache.org/', 'Get home URL' );
is( $apache->download_url, 'http://www.apache.org/dist/httpd/',
    'Get download URL' );
