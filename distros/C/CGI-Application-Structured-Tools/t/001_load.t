#!/usr/bin/perl

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 12;
use File::Temp qw/tempfile tempdir/;
use File::Spec;
use FindBin qw/$Bin/;
use Cwd;
use File::Glob;
use strict;
use Probe::Perl;

use constant TEST_APP => "TestApp1823";
use constant TEST_SUB_MOD=>"SubModXYZ";


BEGIN { use_ok( 'CGI::Application::Structured::Tools::Starter' ); }
# -------------------------------------------------- #
# generate a test project in a temp dir and 
# verify that the major components were created.
# -------------------------------------------------- #

my $tdir = tempdir();

#diag "\ngenerating test app with cas-starter at $tdir\n";

my $as_pl = File::Spec->catfile("$Bin","..","scripts","cas-starter.pl");

chdir($tdir);

system(Probe::Perl->find_perl_interpreter(), $as_pl,"--module",TEST_APP ,"--author","testauth","--email",'test@any.com') == 0 or die "cannot create test application";

chdir(File::Spec->catdir($tdir, TEST_APP));

ok (-d File::Spec->catdir($tdir, TEST_APP), "app dir exists");

ok (-d File::Spec->catdir($tdir, TEST_APP, "lib"), "proj lib dir created");

ok (-f File::Spec->catfile($tdir, TEST_APP, "templates",TEST_APP,"C","Home","index.tmpl"), "default runmode index tt created");
 
ok( -f File::Spec->catfile($tdir, TEST_APP, "lib",TEST_APP,"C","Home.pm"), "default submodule created.");

ok( -f File::Spec->catfile($tdir, TEST_APP,"lib",TEST_APP,"Dispatch.pm"), "dispatch subclass was created");

ok (-f File::Spec->catfile($tdir, TEST_APP,"config","config.pl"), "config.pl was created");

ok (-f File::Spec->catfile($tdir, TEST_APP,"script","create_dbic_schema.pl"), "create_dbic_schema.pl was created.");

ok (-f File::Spec->catfile($tdir, TEST_APP,"script","create_controller.pl"), "create_controller.pl was created.");

ok (-f File::Spec->catfile($tdir, TEST_APP, "server.pl"), "server.pl was created.");

ok (-f File::Spec->catfile($tdir, TEST_APP, "debug.sh"), "debug.sh was created.");



# -------------------------------------------------- #
# Generate a new module with pre-generated scrit.
# Verify that the major components were created.
# -------------------------------------------------- #

system(Probe::Perl->find_perl_interpreter(),"script/create_controller.pl","--name",TEST_SUB_MOD);

my $mod_name = TEST_SUB_MOD . '.pm';

ok (-f File::Spec->catfile($tdir, TEST_APP,"lib",TEST_APP,"C", $mod_name), "create_controller.pl was created.");

