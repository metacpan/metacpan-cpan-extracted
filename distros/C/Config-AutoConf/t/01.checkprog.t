# -*- cperl -*-

use strict;
use warnings;

use Test::More tests => 18;
use Config;
use Config::AutoConf;

END { -e "config.log" and unlink "config.log"; }

ok( Config::AutoConf->check_prog("perl"), "Find perl" );

ok( !Config::AutoConf->check_prog("hopingnobodyhasthiscommand"), "Don't find ''hopingnobodyhasthiscommand" );

like( Config::AutoConf->check_progs( "___perl___", "__perl__", "_perl_", "perl" ), qr/perl(?:\.exe)?$/i, "Find perl only" );
is( Config::AutoConf->check_progs( "___perl___", "__perl__", "_perl_" ), undef, "Find no _xn surrounded perl" );

SCOPE:
{
    my $ac = Config::AutoConf->new();    # avoid cache influences tests below
    local $ENV{AWK} = "/somewhere/over/the/rainbow";
    my $awk = $ac->check_prog_awk;
    is( $awk, $ENV{AWK}, "\$ENV{AWK} honored" );

    local $ENV{SED} = "/somewhere/over/the/rainbow";
    my $sed = $ac->check_prog_sed;
    is( $sed, $ENV{SED}, "\$ENV{SED} honored" );

    local $ENV{EGREP} = "/somewhere/over/the/rainbow";
    my $egrep = $ac->check_prog_egrep;
    is( $egrep, $ENV{EGREP}, "\$ENV{EGREP} honored" );

    local $ENV{YACC} = "/somewhere/over/the/rainbow";
    my $yacc = $ac->check_prog_yacc;
    is( $yacc, $ENV{YACC}, "\$ENV{YACC} honored" );
}

SCOPE:
{
    my $ac = Config::AutoConf->new();    # avoid cache influences tests below
    local $ENV{ac_cv_prog_AWK} = "/somewhere/over/the/rainbow";
    my $awk = $ac->check_prog_awk;
    is( $awk, $ENV{ac_cv_prog_AWK}, "\$ENV{ac_cv_prog_AWK} honored" );

    local $ENV{ac_cv_prog_SED} = "/somewhere/over/the/rainbow";
    my $sed = $ac->check_prog_sed;
    is( $sed, $ENV{ac_cv_prog_SED}, "\$ENV{ac_cv_prog_SED} honored" );

    local $ENV{ac_cv_prog_EGREP} = "/somewhere/over/the/rainbow";
    my $egrep = $ac->check_prog_egrep;
    is( $egrep, $ENV{ac_cv_prog_EGREP}, "\$ENV{ac_cv_prog_EGREP} honored" );

    local $ENV{ac_cv_prog_YACC} = "/somewhere/over/the/rainbow";
    my $yacc = $ac->check_prog_yacc;
    is( $yacc, $ENV{ac_cv_prog_YACC}, "\$ENV{ac_cv_prog_YACC} honored" );
}

diag("Check for some progs to get an overview about world outside");

sub _is_x
{
    $^O =~ m/MSWin32/i and return $_[0] =~ m/\.(?:exe|com|bat|cmd)$/;
    return -x $_[0];
}

SKIP:
{
    my $awk = Config::AutoConf->check_prog_awk;
    $awk or skip "No awk", 1;
    my $awk_bin = ( map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } Text::ParseWords::shellwords $awk )[0];
    ok( _is_x($awk_bin), "$awk_bin is executable" );
    diag("Found AWK as $awk");
}

SKIP:
{
    my $sed = Config::AutoConf->check_prog_sed;
    $sed or skip "No sed", 1;
    my $sed_bin = ( map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } Text::ParseWords::shellwords $sed )[0];
    ok( _is_x($sed_bin), "$sed_bin is executable" );
    diag("Found SED as $sed");
}

SKIP:
{
    my $grep = Config::AutoConf->check_prog_egrep;
    $grep or skip "No egrep", 1;
    my $grep_bin = ( map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } Text::ParseWords::shellwords $grep )[0];
    ok( _is_x($grep_bin), "$grep_bin is executable" );
    diag("Found EGREP as $grep");
}

SKIP:
{
    my $yacc = Config::AutoConf->check_prog_yacc;
    $yacc or skip "No yacc", 1;
    my $yacc_bin = ( map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } Text::ParseWords::shellwords $yacc )[0];
    ok( _is_x($yacc_bin), "$yacc is executable" );
    diag("Found YACC as $yacc");
}

SKIP:
{
    my $lex = Config::AutoConf->check_prog_lex;
    $lex or skip "No lex", 1;
    my $lex_bin = ( map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } Text::ParseWords::shellwords $lex )[0];
    ok( _is_x($lex_bin), "$lex is executable" );
    diag("Found LEX as $lex");
}

SKIP:
{
    my $pkg_config = Config::AutoConf->check_prog_pkg_config;
    $pkg_config or skip "No pkg-config", 1;
    ok( _is_x($pkg_config), "$pkg_config is executable" );
    diag("Found PKG-CONFIG as $pkg_config");
}
