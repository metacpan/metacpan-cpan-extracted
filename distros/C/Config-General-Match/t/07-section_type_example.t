
use strict;
use warnings;

use Test::More 'no_plan';


use Config::General::Match;

my $conf_text = <<'EOF';
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

my $conf = Config::General::Match->new(
    -MatchSections => [
        {
            -Name          => 'Module',
            -MatchType     => 'path',
            -PathSeparator => '::',
            -SectionType   => 'module',
            -MergePriority => 2,
        },
        {
            -Name          => 'FileMatch',
            -MatchType     => 'regex',
            -SectionType   => 'file',
            -MergePriority => 1,
        },
        {
            -Name          => 'File',
            -MatchType     => 'path',
            -SectionType   => 'file',
            -MergePriority => 1,
        },
    ],
    -String          => $conf_text,
    -CComments       => 0,

);

my %config;
%config = $conf->getall_matching(
    file   => '/usr/lib/perl5/site_perl/5.6.1/Config/Simple.pm',
    module => 'Config::Simple',
);

is($config{'Perl_Module'},      1, '[c::s] Perl_Module:       1');
is($config{'Core_Module'},      0, '[c::s] Core_Module:       0');
is($config{'Config_Module'},    1, '[c::s] Config_Module:     1');
is($config{'Installed_Module'}, 1, '[c::s] Installed_Module:  1');

%config = $conf->getall_matching(
    file   => '/home/mgraham/dev/perlmod/Config-General-Match/lib/Config/General/Match.pm',
    module => 'Config::General::Match',
);

is($config{'Perl_Module'},      1, '[c::g::m] Perl_Module:       1');
is($config{'Core_Module'},      0, '[c::g::m] Core_Module:       0');
is($config{'Config_Module'},    1, '[c::g::m] Config_Module:     1');
is($config{'Installed_Module'}, 0, '[c::g::m] Installed_Module:  0');

%config = $conf->getall_matching(
    file   => '/usr/lib/perl5/5.6.1/File/Spec.pm',
    module => 'File::Spec',
);

is($config{'Perl_Module'},      1, '[File::Spec] Perl_Module:       1');
is($config{'Core_Module'},      1, '[File::Spec] Core_Module:       1');
is($config{'Config_Module'},    0, '[File::Spec] Config_Module:     0');
is($config{'Installed_Module'}, 1, '[File::Spec] Installed_Module:  1');
