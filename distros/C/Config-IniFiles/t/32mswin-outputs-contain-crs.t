#!/usr/bin/perl

# As of version 2.73 the .ini files generated on Microsoft Windows did not
# contain carriage returns (CRs). This is a regression test for that.

# Thanks to Ben Johnson for reporting this and for a preliminary test
# script.

use strict;
use warnings;

use lib "./t/lib";
use Config::IniFiles::Slurp qw( bin_slurp );

use Test::More;

if ( $^O !~ m/\AMSWin/ )
{
    plan skip_all => 'Test is only relevant for Microsoft Windows';
}
else
{
    plan tests => 1;
}

use Config::IniFiles;
use File::Spec;

my $config_filename =
    File::Spec->catdir( File::Spec->curdir(), "t", "testConfig.ini" );

writeNewUserIni($config_filename);

for my $s ( 1 .. 4 )
{
    print "s = $s\n";
    for my $p ( 1 .. 4 )
    {
        print "p = $p\n";
        writeIni( $config_filename, "Section$s", "Param$p", "Value$p" );
    }
}

# TEST
unlike(
    scalar( bin_slurp($config_filename) ),
    qr/[^\x0D]\x0A/,    # \x0D is CR ; \x0A is LF. See "man ascii".
    "Checking that all line feeds are preceded by carriage returns",
);

sub writeNewUserIni
{
    my ($config_fn) = @_;

    open my $fh, '>', $config_fn
        or die "Cannot open $config_fn for writing. - $!";
    print {$fh} "[UserConfigFile]\n";
    close($fh);

    return;
}

sub writeIni
{
    my ( $userConfig_fn, $section, $param, $value ) = @_;

    my $usrCfg = Config::IniFiles->new( -file => $userConfig_fn )
        or die
"Failed! Could not open $userConfig_fn with error @Config::IniFiles::errors\n";

    $usrCfg->newval( $section, $param, $value )
        or die
        "Could not set newval in writeIni for $section, $param -> $value\n";

    my $c = 0;

    while ( $c < 6 )
    {
        if ( $usrCfg->RewriteConfig() )
        {
            $c = 6;
            print "Writing [$section] $param -> $value\n";
        }
        else
        {
            warn "Error: could not write $param=$value to $userConfig_fn\n";
            sleep 1;
            $c++;
            print "c = $c\n";
        }
    }

    return;
}
