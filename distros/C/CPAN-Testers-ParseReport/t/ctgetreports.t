#!perl -- -*- mode: cperl -*-

use strict;
use Test::More;
use File::Spec;
use CPAN::Testers::ParseReport;
use List::AllUtils qw(sum max);
use utf8;
  binmode Test::More->builder->output, ":utf8";
  binmode Test::More->builder->failure_output, ":utf8";

my $plan;

sub reportedvariableis ($$$$) {
    my($extract,$id,$var,$value) = @_;
    is $extract->{$var}, $value, "report $id: $var is $value";
}

{
    BEGIN { $plan += 1 }
    open my $fh, "<", qq{t/var/nntp-testers/1581994} or die "could not open: $!";
    local $/;
    my $article = <$fh>;
    close $fh;
    my $dump = {};
    CPAN::Testers::ParseReport::parse_report(1234567, $dump, article => $article, solve => 1, quiet => 1);
    my $keys = keys %{$dump->{"==DATA=="}[0]};
    ok($keys >= 39, "found at least 39, actually [$keys] keys");
}

{
    BEGIN {
        $plan += 6;
    }
    my %Opt = (
               'q' => ["meta:perl", "meta:from", "qr:(Undefined.*)", "prereq:Test::More"],
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
              );
    CPAN::Testers::ParseReport::parse_distro
          (
           "Scriptalicious",
           %Opt,
          );
    my $Y = CPAN::Testers::ParseReport::_yaml_loadfile("ctgetreports.out");
    my $count = sum map {values %{$Y->{"meta:from"}{$_}}} keys %{$Y->{"meta:from"}};
    is($count, 130, "found $count==130 reports via meta:from");
    is($Y->{"meta:ok"}{PASS}{PASS}, 79, "found 79 PASS");
    is($Y->{"prereq:Test::More"}{0}{PASS}, 70, "found 70 PASS on prereq Test::More==0");
    ok(!$Y->{"env:alignbytes"}, "there is no such thing as an environment alignbytes");
    my $undefined = $Y->{'qr:(Undefined.*)'};
    my($the_warning) = grep {length} keys %$undefined;
    ok($undefined,"found warning: '$the_warning'");
    like($the_warning, qr/&main::/, "the ampersand is escaped");
}

{
    BEGIN {
        $plan += 2;
    }
    my $sample_0 = 40;
    my %Opt = (
               'q' => ["meta:perl", "meta:from", "prereq:Test::More"],
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'sample' => $sample_0,
              );
    CPAN::Testers::ParseReport::parse_distro
          (
           "Scriptalicious",
           %Opt,
          );
    my $Y = CPAN::Testers::ParseReport::_yaml_loadfile("ctgetreports.out");
    unlink "ctgetreports.out" or die "Could not unlink ctgetreports.out: $!";
    my $count_all = sum map {values %{$Y->{"meta:from"}{$_}}} keys %{$Y->{"meta:from"}};
    is($count_all, $sample_0, "found $count_all==$sample_0 reports via meta:from");
    my $count_fail_1 = $Y->{"meta:ok"}{"FAIL"}{"FAIL"};

    # if the first pass brings much, we still want one more, if it
    # brings just a few, we want at least 22 since we know we have
    # more than that
    $Opt{minfail} = max(22,$count_fail_1+1);
    CPAN::Testers::ParseReport::parse_distro
          (
           "Scriptalicious",
           %Opt,
          );
    $Y = CPAN::Testers::ParseReport::_yaml_loadfile("ctgetreports.out");
    my $count_fail_2 = $Y->{"meta:ok"}{"FAIL"}{"FAIL"};
    cmp_ok($count_fail_2, '>', $count_fail_1, "found $count_fail_2 > $count_fail_1: that is more fails with minfail than without");
}

{
    BEGIN {
        $plan += 5;
    }
    my $id = 18981290;
    my %Opt = (
               'q' => ["meta:perl", "meta:from", 'conf:libpth', 'conf:libs', 'conf:perllibs'],
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    reportedvariableis $extract, $id, 'prereq:Text::Ligature', '0.02';
    reportedvariableis $extract, $id, 'prereq:parent', '0';
    # ld='cc', ldflags ='-pthread -Wl,-E  -fstack-protector -L/usr/local/lib'
    # libpth=/usr/lib /usr/local/lib
    # libs=-lgdbm -lm -lcrypt
    # perllibs=-lm -lcrypt
    # libc=, so=so, useshrplib=false, libperl=libperl.a
    # gnulibc_version=''
    reportedvariableis $extract, $id, 'conf:libpth', '/usr/lib /usr/local/lib';
    reportedvariableis $extract, $id, 'conf:libs', '-lgdbm -lm -lcrypt';
    reportedvariableis $extract, $id, 'conf:perllibs', '-lm -lcrypt';
}

{
    BEGIN {
        $plan += 1;
    }
    my %Opt = (
               'q' => ["meta:perl", "meta:from", "prereq:Test::More"],
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'sample' => 999,
              );
    CPAN::Testers::ParseReport::parse_distro
          (
           "Scriptalicious",
           %Opt,
          );
    my $Y = CPAN::Testers::ParseReport::_yaml_loadfile("ctgetreports.out");
    my $count = sum map {values %{$Y->{"meta:from"}{$_}}} keys %{$Y->{"meta:from"}};
    is($count, 130, "found $count==130 reports via meta:from");
}

{
    BEGIN {
        $plan += 3;
    }
    my $id = "3521214";
    my %Opt = (
               'q' => ["meta:perl", "meta:from", "conf:git_commit_id", "env:PERL5_MINISMOKEBOX"],
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    reportedvariableis $extract, $id, 'conf:git_commit_id', '245490700bb744b58c708516d2d3c08f18583dc3';
    reportedvariableis $extract, $id, 'env:AUTOMATED_TESTING', '1';
    reportedvariableis $extract, $id, 'meta:date', '2009-03-20T03:29:23';
}

{
    BEGIN {
        $plan += 4;
    }
    my $id = 3851138;
    my %Opt = (
               'q' => ["meta:perl", "meta:from", "mod:Storable", "env:AUTOMATED_TESTING"],
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/3851138",
           $dumpvars,
           %Opt,
          );
    like $extract->{'conf:archname'}, qr/64int/, "found 64int on archname";
    reportedvariableis $extract, $id, 'env:AUTOMATED_TESTING', '1';
    reportedvariableis $extract, $id, 'mod:Storable', '2.18';
    reportedvariableis $extract, $id, 'meta:date', '2009-05-10T01:39:11';
}

{
    BEGIN {
        $plan += 4;
    }
    my $id = 5698506;
    my %Opt = (
               'q' => ["conf:nvsize", "conf:uselongdouble"],
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/5698506",
           $dumpvars,
           %Opt,
          );
    reportedvariableis $extract, $id, 'conf:nvsize', 16;
    reportedvariableis $extract, $id, 'conf:uselongdouble', 'define';
    reportedvariableis $extract, $id, 'mod:ExtUtils::MakeMaker', '6.55_02';
    reportedvariableis $extract, $id, 'meta:date', '2009-10-21T17:30:27';
}

{
    BEGIN {
        $plan += 4;
    }
    my $id = 5012315;
    my %Opt = (
               'q' => ["conf:nvsize", "conf:uselongdouble"],
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    reportedvariableis $extract, $id, 'conf:nvsize', 8;
    reportedvariableis $extract, $id, 'conf:uselongdouble', 'undef';
    reportedvariableis $extract, $id, 'mod:ExtUtils::MakeMaker', '6.54';
    reportedvariableis $extract, $id, 'meta:date', '2009-08-14T20:18:57';
}

{
    BEGIN { $plan += 1 }
    open my $fh, "-|", qq{"$^X" "-Ilib" "bin/ctgetreports" "--local" "--cachedir" "t/var" "--solve" "--quiet" "Scriptalicious" 2>&1} or die "could not fork: $!";
    my @reg;
    my @full;
    while (<$fh>) {
        push @reg, $1 if /^Regression '(.+)'/;
        push @full, $_;
    }
    close $fh or diag join "", @full;
    is "@reg", "fail:t/04-fork meta:osname+perl meta:writer", "found the top 3 candidates";

# Up to 0.0.15:

# State after regression testing: 68 results, showing top 3
# 
# (1)
# ****************************************************************
# Regression 'mod:Test::Harness'
# ****************************************************************
# Name                         Theta          StdErr     T-stat
# [0='const']                 1.0000          0.1021       9.80
# [1='eq_2.64']              -0.3846          0.1328      -2.90
# [2='eq_3.09']               0.0000          0.3228       0.00
# [3='eq_3.10']              -0.0200          0.1109      -0.18
# [4='eq_3.11']              -0.0000          0.2042      -0.00
# [5='eq_3.12']              -0.7143          0.1309      -5.46
# [6='eq_3.13']              -0.8696          0.1204      -7.22
# [7='eq_3.14']              -0.8667          0.1291      -6.71
# 
# R^2= 0.628, N= 128, K= 8
# ****************************************************************
# (2)
# ****************************************************************
# Regression 'id'
# ****************************************************************
# Name                         Theta          StdErr     T-stat
# [0='const']                 2.4992          0.1514      16.51
# [1='n_id']                 -0.0000          0.0000     -12.66
# 
# R^2= 0.560, N= 128, K= 2
# ****************************************************************
# (3)
# ****************************************************************
# Regression 'meta:date'
# ****************************************************************
# Name                         Theta          StdErr     T-stat
# [0='const']                93.9116          7.3952      12.70
# [1='n_meta:date']          -0.0000          0.0000     -12.62
# 
# R^2= 0.558, N= 128, K= 2
# ****************************************************************

# From 0.0.16:

# State after regression testing: 110 results, showing top 3
# 
# (1)
# ****************************************************************
# Regression 'meta:writer'
# ****************************************************************
# Name                         Theta          StdErr     T-stat
# [0='const']                 0.8929          0.0509      17.54
# [1='eq_CPAN-Reporter-1.1404']       0.1071          0.0992       1.08
# [2='eq_CPAN-Reporter-1.15']         0.1071          0.0720       1.49
# [3='eq_CPAN-Reporter-1.1556']      -0.8929          0.1440      -6.20
# [4='eq_CPAN-Reporter-1.16']        -0.8929          0.2741      -3.26
# [5='eq_CPAN-Reporter-1.1601']      -0.6929          0.1308      -5.30
# [6='eq_CPAN-Reporter-1.1651']      -0.7679          0.0844      -9.10
# [7='eq_CPAN-Reporter-1.17']        -0.6706          0.1032      -6.50
# [8='eq_CPAN-Reporter-1.1702']      -0.7817          0.0814      -9.61
# [9='eq_CPAN::YACSmoke 0.0307']              0.1071          0.1032       1.04
# 
# R^2= 0.717, N= 128, K= 10
# ****************************************************************
# (2)
# ****************************************************************
# Regression 'mod:Test::Harness'
# ****************************************************************
# Name                         Theta          StdErr     T-stat
# [0='const']                 1.0000          0.1021       9.80
# [1='eq_2.64']              -0.3846          0.1328      -2.90
# [2='eq_3.09']               0.0000          0.3228       0.00
# [3='eq_3.10']              -0.0200          0.1109      -0.18
# [4='eq_3.11']              -0.0000          0.2042      -0.00
# [5='eq_3.12']              -0.7143          0.1309      -5.46
# [6='eq_3.13']              -0.8696          0.1204      -7.22
# [7='eq_3.14']              -0.8667          0.1291      -6.71
# 
# R^2= 0.628, N= 128, K= 8
# ****************************************************************
# (3)
# ****************************************************************
# Regression 'id'
# ****************************************************************
# Name                         Theta          StdErr     T-stat
# [0='const']                 2.4992          0.1514      16.51
# [1='n_id']                 -0.0000          0.0000     -12.66
# 
# R^2= 0.560, N= 128, K= 2
# ****************************************************************


}

{
    BEGIN {
        $plan += 9;
    }
    my $id = 5834678;
    my %Opt = (
               'q' => ["conf:nvsize", "conf:uselongdouble"],
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'meta:date'}, '2009-11-01T14:07:11', "report $id: date";
    is $extract->{'conf:nvsize'}, 8, "report $id: found 8 on nvsize";
    is $extract->{'conf:uselongdouble'}, 'undef', "report $id: found uselongdouble";
    is $extract->{'mod:CPANPLUS'}, '0.89_06', "report $id: CPANPLUS version";
    is $extract->{'mod:Cwd'}, '3.2501', "report $id: Cwd version";
    is $extract->{'mod:File::Spec'}, '3.2501', "report $id: File::Spec version";
    is $extract->{'mod:version'}, '0.7701', "report $id: version version";
    is $extract->{'mod:ExtUtils::MakeMaker'}, '6.54', "report $id: ExtUtils::MakeMaker version";
    is $extract->{'mod:l module toolchain versions in'}, undef, "report $id: C:T:PR 0.1.6 had a bug against cpanplus 0.89_06";
}

{
    BEGIN {
        $plan += 8;
    }
    my $id = 5928865;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'mod:Catalyst::Plugin::Session::State::Cookie'}, "0.17", "report $id: C:P:S:S:C version";
    is $extract->{'mod:Catalyst::Controller::ActionRole'}, "0.12", "report $id: C:C:AR mod version";
    is $extract->{'prereq:Catalyst::Controller::ActionRole'}, "0.12", "report $id: C:C:AR prereq version";
    is $extract->{'mod:Moose::Autobox'}, "0.10", "report $id: M:A mod version";
    is $extract->{'prereq:Moose::Autobox'}, "0.09", "report $id: M:A prereq version";
    is $extract->{'mod:CPANPLUS'}, '0.89_07', "report $id: CPANPLUS version";
    is $extract->{'mod:Cwd'}, '3.30', "report $id: Cwd version";
    is $extract->{'meta:date'}, '2009-11-08T14:48:26', "report $id: date";
}

{
    BEGIN {
        $plan += 1;
    }
    my $id = 2129076;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'meta:date'}, '2008-09-02T18:05:00', "report $id: date";
}

{
    BEGIN {
        $plan += 1;
    }
    my $id = 34604012;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'fail:t/20-content-types.t'}, 1;
}

{
    BEGIN {
        $plan += 2;
    }
    my $id = 6422067;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
               'q' => ['qr:(Failed test\s+\S+.*)'],
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'qr:(Failed test\s+\S+.*)'}, q{Failed test 'Pod coverage on App::Pm2Port'}, "report $id: qr...Failed test...";
    is $extract->{'fail:t/pod-coverage.t'}, 1;
}

{
    BEGIN {
        $plan += 1;
    }
    my $id = 6115651;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'meta:perl'}, q{5.11.2}, "report $id: meta:perl";
}

{
    BEGIN {
        $plan += 1;
    }
    my $id = 6525411;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'mod:Image::Imlib2'}, q{0}, "report $id: mod:Image::Imlib2";
}

{
    BEGIN {
        $plan += 3;
    }
    my $id = 8327429;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'prereq:Module::Build'}, q{0.36}, "report $id: prereq:Module::Build";
    is $extract->{'mod:Module::Build'}, q{0.36_13}, "report $id: mod:Module::Build";
    is $extract->{'meta:perl_compiled_at'}, q{2010-07-21T15:14:27}, "report $id: meta:perl_compiled_at";
}

{
    BEGIN {
        $plan += 2;
    }
    my $id = 1678737;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'env:$UID'}, q{1005}, "report $id: UID=1005";
    is $extract->{'env:$GID∋1005'}, q{true}, "report $id: GID∋1005";
}

{
    BEGIN {
        $plan += 2;
    }
    my $id = 1425132;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'env:$UID'}, q{1002}, "report $id: UID=1002";
    is $extract->{'env:$GID∋100'}, q{true}, "report $id: GID∋100";
}

{
    BEGIN {
        $plan += 2;
    }
    my $id = 3521214;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'env:$UID'}, q{502}, "report $id: UID=502";
    is $extract->{'env:$GID∋502'}, q{true}, "report $id: GID∋502";
}

{
    BEGIN {
        $plan += 3;
    }
    my $id = 5834678;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'env:$UID'}, q{1001}, "report $id: UID=1001";
    is $extract->{'env:$GID∋1001'}, q{true}, "report $id: GID∋1001";
    is $extract->{'env:$^X'}, q{/usr/home/cpan/pit/bare/perl-5.10.0/bin/perl}, "report $id: \$^X=/usr/home/cpan/pit/bare/perl-5.10.0/bin/perl";
}

{
    BEGIN {
        $plan += 2;
    }
    my $id = 16833358;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    is $extract->{'meta:perl'}, q{5.12.4}, "report $id: meta:perl";
    is $extract->{'mod:CPANPLUS'}, q{0.9111}, "report $id: mod:CPANPLUS";
}

{
    BEGIN {
        $plan += 7;
    }
    my $id = 18548512;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    $main::att=1;
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    reportedvariableis $extract, $id, 'conf:usesocks', 'undef';
    reportedvariableis $extract, $id, 'conf:use64bitall', 'define';
    reportedvariableis $extract, $id, 'conf:use64bitint', 'define';
    reportedvariableis $extract, $id, 'conf:useposix', 'true';
    reportedvariableis $extract, $id, 'conf:usemymalloc', 'n';
    reportedvariableis $extract, $id, 'conf:d_sfio', 'undef';
    reportedvariableis $extract, $id, 'conf:bincompat5005', 'undef';
}

{
    BEGIN {
        $plan += 11;
    }
    my $id = "Module-Versions-Report";
    my $extract = CPAN::Testers::ParseReport::parse_report(
        "t/var/fake/$id",
        {},
        local => 1,
        quiet => 1,
    );
    is $extract->{'meta:about'}, 'Foo-Bar-v1.2.3',  "$id: sanity check - meta:about";
    is $extract->{'prereq:Module::Build'}, q{0.36}, "$id: sanity check - prereq:Module::Build";
    is $extract->{'mod:Module::Build'}, q{0.36_13}, "$id: sanity check - mod:Module::Build";
    is $extract->{'mod:DBI'}, q{1.614},             "$id: sanity check - mod:DBI";

    is $extract->{'mod:Data'},                      'undef',  "$id: mod:Data";
    is $extract->{'mod:Data::Dumper'},              'v2.151', "$id: mod:Data::Dumper";
    is $extract->{'mod:Data::OptList'},             'v0.109', "$id: mod:Data::OptList";
    is $extract->{'mod:Date'},                      'undef',  "$id: mod:Date";
    is $extract->{'mod:Date::Manip'},               'v6.47',  "$id: mod:Date::Manip";
    is $extract->{'mod:Date::Manip::DM5'},          'v6.47',  "$id: mod:Date::Manip::DM5";
    is $extract->{'mod:Date::Manip::DM5abbrevs'},   'v6.47',  "$id: mod:Date::Manip::DM5abbrevs";
}

{
    BEGIN {
        $plan += 8;
    }
    my $id = 94682624;
    my %Opt = (
               'local' => 1,
               'cachedir' => 't/var',
               'quiet' => 1,
               'dumpvars' => ".",
               'report' => $id,
              );
    my $dumpvars = {};
    $main::att=1;
    my $extract = CPAN::Testers::ParseReport::parse_report
          (
           "t/var/nntp-testers/$id",
           $dumpvars,
           %Opt,
          );
    reportedvariableis $extract, $id, 'conf:usesocks', 'undef';
    reportedvariableis $extract, $id, 'conf:use64bitall', 'define';
    reportedvariableis $extract, $id, 'conf:use64bitint', 'define';
    reportedvariableis $extract, $id, 'conf:useposix', 'true';
    reportedvariableis $extract, $id, 'conf:usemymalloc', 'n';
    reportedvariableis $extract, $id, 'conf:d_sfio', 'undef';
    reportedvariableis $extract, $id, 'conf:bincompat5005', 'undef';
    reportedvariableis $extract, $id, 'mod:File::Path', '2.15';
}

unlink "ctgetreports.out";

BEGIN {
      plan tests => $plan;
}

__END__

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# End:

