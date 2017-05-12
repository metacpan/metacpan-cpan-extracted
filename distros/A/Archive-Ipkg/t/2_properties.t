# Test 2: Properties

use Test::More tests => 36;

use Archive::Ipkg;

# just test functionality with 'sloppy checks'

my $name             = "weird_name";
my $priority         = "weird_priority";
my $section          = "weird_section";
my $version          = "weird_version";
my $architecture     = "weird_architecture";
my $maintainer       = "weird_maintainer";
my $depends          = "weird_depends";
my $description      = "weird_description";
my @config_files     = qw(weird config files);
my $script           = "#!/bin/sh\necho 'I am weird'\nexit 0";

my $ipkg = Archive::Ipkg->new();

ok(defined $ipkg, "Constructor");

$ipkg->sloppy_checks;

# required: package, version, architecture, maintainer, section, description

ok(defined $ipkg->verify, "Verify 1");
ok(!defined $ipkg->filename, "No default filename");

# name
ok (!defined $ipkg->name, "No default name");
ok($ipkg->name($name) eq $name, "Setting name");
ok(defined $ipkg->verify, "Verify 2");
ok(defined $ipkg->filename, "Filename available after setting name");

# section
ok($ipkg->section eq $ipkg->default_section, "Reading default section");
ok($ipkg->section($section) eq $section, "Setting section");
ok(defined $ipkg->verify, "Verify 4");

# version
ok($ipkg->version eq $ipkg->default_version, "Reading default version");
ok($ipkg->version($version) eq $version, "Setting version");
ok(defined $ipkg->verify, "Verify 5");

# architecture
ok($ipkg->architecture eq $ipkg->default_architecture, "Reading default architecture");
ok($ipkg->architecture($architecture) eq $architecture, "Setting architecture");
ok(defined $ipkg->verify, "Verify 6");

# maintainer
ok(!defined $ipkg->maintainer, "No default maintainer");
ok($ipkg->maintainer($maintainer) eq $maintainer, "Setting maintainer");
ok(defined $ipkg->verify, "Verify 7");

# description
ok(!defined $ipkg->description, "No default description");
ok($ipkg->description($description) eq $description, "Setting description");
ok(!defined $ipkg->verify, "Successful verify");

# optional priorities

# priority
ok($ipkg->priority eq $ipkg->default_priority, "Reading default priority");
ok($ipkg->priority($priority) eq $priority, "Setting priority");

# depends
ok(!defined $ipkg->depends, "No default depends");
ok($ipkg->depends($depends) eq $depends, "Setting depends");

# config files
ok(!defined $ipkg->config_files, "No default config files");
my $new_conf = $ipkg->config_files(\@config_files);
my $equal = 1;
foreach (0..$#{$new_conf}) {
    $equal = 0 if ($new_conf->[$_] ne $config_files[$_]);
}
ok($equal, "Setting config files");

# installation/removal scripts

ok(!defined $ipkg->preinst_script, "No default preinst script");
ok($ipkg->preinst_script($script) eq $script, "Setting preinst script");

ok(!defined $ipkg->postinst_script, "No default postinst script");
ok($ipkg->postinst_script($script) eq $script, "Setting postinst script");

ok(!defined $ipkg->prerm_script, "No default prerm script");
ok($ipkg->prerm_script($script) eq $script, "Setting prerm script");

ok(!defined $ipkg->postrm_script, "No default postrm script");
ok($ipkg->postrm_script($script) eq $script, "Setting postrm script");

