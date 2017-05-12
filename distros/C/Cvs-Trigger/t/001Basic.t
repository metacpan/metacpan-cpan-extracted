######################################################################
# Test suite for Cvs::Trigger
# by Mike Schilli <m@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use Log::Log4perl qw(:easy);
use Cvs::Trigger;
use Sysadm::Install qw(:all);
use YAML qw(LoadFile);

my $nof_tests = 10;
plan tests => $nof_tests;

SKIP: {

if(!defined bin_find("cvs")) {
    skip "cvs not installed", $nof_tests;
}

#Log::Log4perl->easy_init({ level => $DEBUG, layout => "%F-%L: %m%n"});

my $c = Cvs::Temp->new();
$c->init();
cd $c->{local_root};
$c->module_import();

my $code = $c->test_trigger_code("commitinfo");
my $script = "$c->{bin_dir}/trigger";
blurt $code, $script;
chmod 0755, $script;

my $commitinfo = "$c->{local_root}/CVSROOT/commitinfo";
chmod 0644, $commitinfo or die "cannot chmod $commitinfo";
blurt "DEFAULT $script", $commitinfo;
$c->admin_rebuild();

    # Single file
$c->files_commit("m/a/a1.txt");
my $yml = LoadFile("$c->{out_dir}/trigger.yml.1");
is($yml->{files}->[0], "a1.txt", "yml trigger check for single file");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");

    # More files in same dir
$c->files_commit("m/a/a1.txt", "m/a/a2.txt");
$yml = LoadFile("$c->{out_dir}/trigger.yml.2");
is($yml->{files}->[0], "a1.txt", "yml trigger check for two files (same dir)");
is($yml->{files}->[1], "a2.txt", "yml trigger check for two files (same dir)");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");

    # More files in different dirs
$c->files_commit("m/a/a1.txt", "m/a/b/b.txt");
$yml = LoadFile("$c->{out_dir}/trigger.yml.3");
is($yml->{files}->[0], "a1.txt", "yml trigger check for two files (same dir)");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a", "yml trigger check repo_dir");

$yml = LoadFile("$c->{out_dir}/trigger.yml.4");
is($yml->{files}->[0], "b.txt", "yml trigger check for two files (same dir)");
is($yml->{repo_dir}, "$c->{cvsroot}/m/a/b", "yml trigger check repo_dir");

    # Check-in message containing a quote
$c->single_file_commit("file_content\n", "m/a/a1.txt", 
                       "message with a ' quote");

$yml = LoadFile("$c->{out_dir}/trigger.yml.5");
is($yml->{files}->[0], "a1.txt", "message with a single quote");

cdback;
}
