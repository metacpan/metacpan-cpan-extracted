
use strict;
use warnings;

use Test::More 'tests' => 36;
my $Per_Driver_Tests = 12;

use Config::Context;

my %Config_Text;

$Config_Text{'ConfigGeneral'} = <<'EOF';
    Perl_Module      = 0
    Installed_Module = 0
    Core_Module      = 0
    Config_Module    = 0
    Section          = Default

    # section 1
    <FileMatch .pm$>
        Perl_Module      = 1
        Section          = .pm
    </FileMatch>

    # section 2
    <File /usr/lib/perl5/ >
        Installed_Module = 1
        Core_Module      = 1
        Section          = /usr/lib/perl5
    </File>

    # section 3
    <FileMatch ^/.*/lib/perl5/site_perl>
        Core_Module = 0
        Section     = site_perl
    </FileMatch>

    # section 4
    <Module Config::>
        Config_Module = 1
        Section       = Config::
    </Module>
EOF

# This works as well.
# $Config_Text{'ConfigScoped'} = <<'EOF';
#     Section          = Default;
#
#     # section 1
#     FileMatch '.pm$' {
#         Perl_Module      = 1
#         Section          = .pm
#     }
#
#     # section 2
#     File /usr/lib/perl5/ {
#         Installed_Module = 1
#         Core_Module      = 1
#         Section          = /usr/lib/perl5
#     }
#
#     # section 3
#     FileMatch '^/.*/lib/perl5/site_perl' {
#         Core_Module = 0
#         Section     = site_perl
#     }
#
#     # section 4
#     Module 'Config::' {
#         Config_Module = 1
#         Section       = Config::
#     }
# EOF

$Config_Text{'ConfigScoped'} = <<'EOF';
    Perl_Module      = 0
    Installed_Module = 0
    Core_Module      = 0
    Config_Module    = 0
    Section          = Default;

    # section 1
    FileMatch = {
        '.pm$' = {
            Perl_Module      = 1
            Section          = .pm
        }
        # section 3
        '^/.*/lib/perl5/site_perl' = {
            Core_Module = 0
            Section     = site_perl
        }
    }

    # section 2
    File = {
        /usr/lib/perl5/  = {
            Installed_Module = 1
            Core_Module      = 1
            Section          = /usr/lib/perl5
        }
    }

    # section 4
    Module = {
        'Config::' = {
            Config_Module = 1
            Section       = Config::
        }
    }
EOF

$Config_Text{'XMLSimple'} = <<'EOF';
<opt>
     <Perl_Module>0</Perl_Module>
     <Installed_Module>0</Installed_Module>
     <Core_Module>0</Core_Module>
     <Config_Module>0</Config_Module>
     <Section>Default</Section>

     # section 1
     <FileMatch name=".pm$">
         <Perl_Module>1</Perl_Module>
         <Section>.pm</Section>
     </FileMatch>

     # section 2
     <File name="/usr/lib/perl5/ ">
         <Installed_Module>1</Installed_Module>
         <Core_Module>1</Core_Module>
         <Section>/usr/lib/perl5</Section>
     </File>

     # section 3
     <FileMatch name="^/.*/lib/perl5/site_perl">
         <Core_Module>0</Core_Module>
         <Section>site_perl</Section>
     </FileMatch>

     # section 4
     <Module name="Config::">
         <Config_Module>1</Config_Module>
         <Section>Config::</Section>
     </Module>
    </opt>
EOF


sub runtests {
    my $driver = shift;

    my $conf = Config::Context->new(
        driver => $driver,
        string => $Config_Text{$driver},
        match_sections => [
            {
                name           => 'Module',
                match_type     => 'path',
                path_separator => '::',
                section_type   => 'module',
                merge_priority => 2,
            },
            {
                name           => 'FileMatch',
                match_type     => 'regex',
                section_type   => 'file',
                merge_priority => 1,
            },
            {
                name           => 'File',
                match_type     => 'path',
                section_type   => 'file',
                merge_priority => 1,
            },
        ],
        driver_options => {
            ConfigGeneral => {
                -CComments       => 0,
            },
        }

    );

    my %config;
    %config = $conf->context(
        file   => '/usr/lib/perl5/site_perl/5.6.1/Config/Simple.pm',
        module => 'Config::Simple',
    );

    is($config{'Perl_Module'},      1, "$driver: [c::s] Perl_Module:       1");
    ok(!$config{'Core_Module'},        "$driver: [c::s] Core_Module:       0");
    is($config{'Config_Module'},    1, "$driver: [c::s] Config_Module:     1");
    is($config{'Installed_Module'}, 1, "$driver: [c::s] Installed_Module:  1");

    %config = $conf->context(
        file   => '/home/mgraham/dev/perlmod/Config-General-Match/lib/Config/General/Match.pm',
        module => 'Config::General::Match',
    );

    is($config{'Perl_Module'},      1, "$driver: [c::g::m] Perl_Module:       1");
    ok(!$config{'Core_Module'},        "$driver: [c::g::m] Core_Module:       0");
    is($config{'Config_Module'},    1, "$driver: [c::g::m] Config_Module:     1");
    ok(!$config{'Installed_Module'},   "$driver: [c::g::m] Installed_Module:  0");

    %config = $conf->context(
        file   => '/usr/lib/perl5/5.6.1/File/Spec.pm',
        module => 'File::Spec',
    );

    is($config{'Perl_Module'},      1, "$driver: [File::Spec] Perl_Module:       1");
    is($config{'Core_Module'},      1, "$driver: [File::Spec] Core_Module:       1");
    ok(!$config{'Config_Module'},       "$driver: [File::Spec] Config_Module:     0");
    is($config{'Installed_Module'}, 1, "$driver: [File::Spec] Installed_Module:  1");
}

SKIP: {
    if (test_driver_prereqs('ConfigGeneral')) {
        runtests('ConfigGeneral');
    }
    else {
        skip "Config::General not installed", $Per_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('ConfigScoped')) {
        runtests('ConfigScoped');
    }
    else {
        skip "Config::Scoped not installed", $Per_Driver_Tests;
    }
}
SKIP: {
    if (test_driver_prereqs('XMLSimple')) {
        runtests('XMLSimple');
    }
    else {
        skip "XML::Simple, XML::SAX or XML::Filter::XInclude not installed", $Per_Driver_Tests;
    }
}

sub test_driver_prereqs {
    my $driver = shift;
    my $driver_module = 'Config::Context::' . $driver;
    eval "require $driver_module;";
    die $@ if $@;

    eval "require $driver_module;";
    my @required_modules = $driver_module->config_modules;

    foreach (@required_modules) {
        eval "require $_;";
        if ($@) {
            return;
        }
    }
    return 1;

}
