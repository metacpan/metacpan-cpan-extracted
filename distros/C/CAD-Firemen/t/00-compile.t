use strict;
use warnings;

# This test was generated via Dist::Zilla::Plugin::Test::Compile 2.018

use Test::More 0.88;



use Capture::Tiny qw{ capture };

my @module_files = qw(
CAD/Firemen.pm
CAD/Firemen/Analyze.pm
CAD/Firemen/Change.pm
CAD/Firemen/Change/Type.pm
CAD/Firemen/Common.pm
CAD/Firemen/Load.pm
CAD/Firemen/Option/Check.pm
CAD/Firemen/ParseHelp/Creo3.pm
CAD/Firemen/ParseHelp/Wildfire5.pm
);

my @scripts = qw(
bin/fm_admin
bin/fm_check_config
bin/fm_check_struct
bin/fm_create_help
bin/fm_diff_cdb
bin/fm_diff_config
bin/fm_option_info
);

# no fake home requested

my @warnings;
for my $lib (@module_files)
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Mblib', '-e', qq{require q[$lib]});
    };
    is($?, 0, "$lib loaded ok");
    warn $stderr if $stderr;
    push @warnings, $stderr if $stderr;
}

use Test::Script 1.05;
foreach my $file ( @scripts ) {
    script_compiles( $file, "$file compiles" );
}


is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};



done_testing;
