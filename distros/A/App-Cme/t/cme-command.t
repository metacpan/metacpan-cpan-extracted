# -*- cperl -*-
use strict;
use warnings;
use utf8;
use 5.10.1;
use open ':std', ':encoding(utf8)';

use Encode;

use Path::Tiny;
use Term::ANSIColor 2.01 qw(colorstrip);

use Test::More;
use Test::File::Contents;

use App::Cmd::Tester;
use App::Cme ;
use Config::Model 2.148 qw/initialize_log4perl/;

# work around a problem in IO::TieCombine (used by App::Cmd::Tester)
# to avoid messing up output of stderr of tested command (See
# ACHTUNG!! notes in IO::TieCombine doc)
$\ = '';

if ( $^O !~ /linux|bsd|solaris|sunos/ ) {
    plan skip_all => "Test with system() in build systems don't work well on this OS ($^O)";
}

my $arg = shift || '';
my ( $log, $show ) = (0) x 2;

my $trace = $arg =~ /t/ ? 1 : 0;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

## testing exit status

# pseudo root where config files are written by config-model
my $wr_root = path('wr_root');

# cleanup before tests
$wr_root -> remove_tree;

my $test1     = 'popcon1';
my $wr_dir    = $wr_root->child($test1);

my $conf_dir = $wr_dir->child('/etc');
$conf_dir->mkpath;

my $conf_file = $conf_dir->child("popularity-contest.conf");
# created with -backup option
my $backup_file = $conf_dir->child("popularity-contest.conf.old");

subtest "list command" => sub {
    my @test_cmd = qw/list/;
    my $result = test_app( 'App::Cme' => \@test_cmd );
    say "-- stdout --\n", $result->stdout,"-----"  if $trace;
    is($result->error, undef, 'threw no exceptions');
};

subtest "modification without config file" => sub {
    my $test_cmd = [
        qw/modify popcon/,
        '-root-dir' => $wr_dir->stringify,
        "PARTICIPATE=yes"
    ];

    my $oops = test_app( 'App::Cme' => $test_cmd );
    is ($oops->exit_code, 2, 'error detected' );
    like($oops->error, qr/cannot find configuration file/, 'missing config file detected' );
};

# put popcon data in place
my @orig = <DATA>;

$conf_file->spew_utf8(@orig);

subtest "check" => sub {
    # use -save to force a file save to update file header
    my @test_cmd = (qw/check popcon -root-dir/, $wr_dir->stringify);
    my $ok = test_app( 'App::Cme' => \@test_cmd );
    is( $ok->exit_code, 0, 'all went well' ) or diag("Failed command @test_cmd");
    is($ok->stderr.'', '', 'check: no log on stderr' );
    is($ok->stdout.'', '', 'check: no message on stdout' );
};

subtest "check verbose mode" => sub {
    # use -save to force a file save to update file header
    my @test_cmd = (qw/check popcon --verbose -root-dir/, $wr_dir->stringify);
    my $ok = test_app( 'App::Cme' => \@test_cmd );
    is( $ok->exit_code, 0, 'all went well' ) or diag("Failed command @test_cmd");
    is($ok->stderr.'', '', 'check: no log on stderr' );
    is($ok->stdout.'', "Loading data...\nChecking data..\nCheck done.\n" ,
       'check: got messages on stdout' );
};

subtest "minimal modification" => sub {
    $conf_file->spew_utf8(@orig);
    # test minimal modif (re-order)
    my @test_cmd = (qw/modify popcon -save -backup -canonical -root-dir/, $wr_dir->stringify);
    my $ok = test_app( 'App::Cme' => \@test_cmd );
    is ($ok->exit_code, 0, 'all went well' ) or diag("Failed command cme @test_cmd");
    is($ok->error, undef, 'threw no exceptions');
    is($ok->stderr.'', '', 'modify: no log on stderr' );
    is($ok->stdout.'', '', 'modify: no message on stdout' );

    file_contents_like $conf_file->stringify,   qr/cme/,       "updated header";
    # with perl 5.14 5.16, IO::Handle writes an extra \n with print.
    my $re = $^V lt 5.18.1 ? qr/yes"\n+MY/ : qr/yes"\nMY/;
    file_contents_like $conf_file->stringify,   $re, "reordered file";
    file_contents_unlike $conf_file->stringify, qr/removed/,   "double comment is removed";

    # check backup
    ok($backup_file->is_file, "backup file was created");
    file_contents_like $backup_file->stringify, qr/should be removed/, "backup file contains original comment";
};

subtest "modification with wrong parameter" => sub {
    $conf_file->spew_utf8(@orig);
    my @test_cmd = (qw/modify popcon -root-dir/, $wr_dir->stringify, qq/PARITICIPATE=yes/);
    my $oops = test_app( 'App::Cme' => \@test_cmd );
    isnt ($oops->exit_code, 0, 'error detected' );
    like($oops->error.'' , qr/object/, 'check unknown element' );
    isnt( $oops->exit_code, 0, 'wrong parameter detected' );

};

subtest "modification with good parameter" => sub {
    $conf_file->spew_utf8(@orig);
    # use -save to force a file save to update file header
    my @test_cmd = (qw/modify popcon -save -root-dir/, $wr_dir->stringify, qq/PARTICIPATE=yes/);
    my $ok = test_app( 'App::Cme' => \@test_cmd );
    is( $ok->exit_code, 0, 'all went well' ) or diag("Failed command @test_cmd");
    is($ok->stderr.'', '', 'modify: no log on stderr' );
    is($ok->stdout.'', '', 'modify: no message on stdout' );
    file_contents_like $conf_file->stringify,   qr/cme/,      "updated header";
    file_contents_unlike $conf_file->stringify, qr/removed`/, "double comment is removed";
};

subtest "modification with verbose option" => sub {
    $conf_file->spew_utf8(@orig);
    my @test_cmd = (qw/modify popcon -verbose -root-dir/, $wr_dir->stringify, qq/PARTICIPATE=yes/);
    my $ok = test_app( 'App::Cme' => \@test_cmd );
    is ($ok->exit_code, 0, 'no error detected' ) or diag("Failed command @test_cmd");
    is(colorstrip($ok->stderr), qq!command 'PARTICIPATE=yes': Setting leaf 'PARTICIPATE' boolean to 'yes'.\n!,
       'check log content' );
};

subtest "search" => sub {
    my @test_cmd = (qw/search popcon -root-dir/, $wr_dir->stringify, qw/-search y -narrow value/);
    my $search = test_app( 'App::Cme' => \@test_cmd );
    is( $search->error, undef, 'threw no exceptions');
    is( $search->exit_code, 0, 'search went well' ) or diag("Failed command @test_cmd");
    like( $search->stdout, qr/PARTICIPATE/, "got PARTICIPATE" );
    like( $search->stdout, qr/USEHTTP/,     "got USEHTTP" );
};

subtest "modification with utf8 parameter" => sub {
    $conf_file->spew_utf8(@orig);
    my $utf8_name = "héhôßœ";
    my @test_cmd = ((qw/modify popcon -root-dir/, $wr_dir->stringify),
        encode('UTF-8',qq/MY_HOSTID="$utf8_name"/) );
    my $ok = test_app( 'App::Cme' => \@test_cmd );
    is( $ok->error, undef, 'threw no exceptions');
    is( $ok->exit_code, 0, 'all went well' ) or diag("Failed command @test_cmd");

    file_contents_like $conf_file->stringify,   qr/$utf8_name/,
        "updated MY_HOSTID with weird utf8 hostname" ,{ encoding => 'UTF-8' };
};

my $expect_namefoobar = << 'EOF';

Changes applied to popcon configuration:
- MY_HOSTID: 'aaaaaaaaaaaaaaaaaaaa' -> '$namefoobar'
EOF

my @script_tests = (
    {
        label => __LINE__.": modification with a script and args",
        script => [ "app:  popcon", 'load ! MY_HOSTID=\$name$name'],
        args => [qw!--arg name=foobar!],
        test => qr/"\$namefoobar"/,
        stderr => $expect_namefoobar,
    },
    {
        label => "line ".__LINE__.": modification with a script and a default value",
        script => [ "app:  popcon", "default: name foobar", 'load ! MY_HOSTID=\$name$name'],
        test => qr/"\$namefoobar"/,
        stderr => $expect_namefoobar,
    },
    {
        label => "line ".__LINE__.": modification with a script and a var that uses a default value",
        script => [ "app:  popcon",
                    "default: defname foobar",
                    'var: $var{name} = $args{defname}',
                    'load ! MY_HOSTID=\$name$name'
                ],
        test => qr/"\$namefoobar"/,
        stderr => $expect_namefoobar,

    },
    {
        label => "line ".__LINE__.": modification with a YAML script and a var that uses a default value",
        script => [
            "# Format:  YAML",
            "---",
            "app: popcon",
            "default: ",
            "  defname: foobar",
            'var: "$var{name} = $args{defname}"',
            'load: "! MY_HOSTID=\\\\$name$name"'
        ],
        test => qr/"\$namefoobar"/,
        stderr => $expect_namefoobar
    },
    {
        label => "line ".__LINE__.": quiet modification with a script and var section",
        script => [ "app:  popcon", 'var: $var{name}="foobar2"','load ! MY_HOSTID=\$name$name'],
        test => qr/"\$namefoobar2"/,
        args => ['-quiet'],
    },
    {
        label => "line ".__LINE__.": modification with a script and var section which uses args",
        script => [ "app:  popcon", 'var: $var{name}=$args{fooname}."bar2"','load ! MY_HOSTID=\$name$name'],
        args => [qw/--arg fooname=foo/],
        test => qr/"\$namefoobar2"/,
        stderr => q(
Changes applied to popcon configuration:
- MY_HOSTID: 'aaaaaaaaaaaaaaaaaaaa' -> '$namefoobar2'
)
    },
    {
        label => "line ".__LINE__.": modification with a script with load =~ regex and quotes and \\s",
        script => [
            "app:  popcon",
            '---var',
            '$var{change_it} = qq{',
            '( s/^(a)a+/',   # comment
            '\$1.\\"$args{fooname}\\" x2',
            '/xe )}',
            '---',
            'load: ! MY_HOSTID=~"$change_it"',
        ],
        args => [qw/--arg fooname=foo/],
        test => qr/MY_HOSTID="afoofoo"/,
        stderr => q(
Changes applied to popcon configuration:
- MY_HOSTID: 'aaaaaaaaaaaaaaaaaaaa' -> 'afoofoo'
)
    },
    {
        label =>"line ". __LINE__.": modification with a Perl script run by cme run with args",
        script => [
            "#!/usr/bin/env perl",
            "use Config::Model qw(cme);",
            'my ($opt,$val,$name) = @ARGV;',
            'cme(application => "popcon", root_dir => $val)->modify("! MY_HOSTID=\$name$name");'
        ],
        args => ['foobar3'],
        test => qr/"\$namefoobar3"/,
        exec_mode => 1,
        stderr => q(
Changes applied to popcon configuration:
- MY_HOSTID: 'aaaaaaaaaaaaaaaaaaaa' -> '$namefoobar3'
)

    },
    {
        label => "line ".__LINE__.": modification with a script and var section which uses regexp and capture",
        script => [
            "app:  popcon",
            'load: ! MY_HOSTID=aaaaab MY_HOSTID=~s/(a{$times})/$1x$times/',
        ],
        args => [qw/--arg times=4 --verbose/],
        test => qr/aaaax4ab/,
        stderr => q[command '!': Going from root node to root node
command 'MY_HOSTID=aaaaab': Setting leaf 'MY_HOSTID' uniline to 'aaaaab'.
command 'MY_HOSTID=~s/(a{4})/$1x4/': Applying regexp 's/(a{4})/$1x4/' to leaf 'MY_HOSTID' uniline. Result is 'aaaax4ab'.

Changes applied to popcon configuration:
- MY_HOSTID: 'aaaaaaaaaaaaaaaaaaaa' -> 'aaaaab'
- MY_HOSTID: 'aaaaab' -> 'aaaax4ab'
],
    },
    {
        label => "line ".__LINE__.": modification with a script with code",
        script => [
            "app:  popcon",
            '---code',
            q!$root->fetch_element('MY_HOSTID')->store($to_store);!,
            '---',
        ],
        args => [qw/--arg to_store=with_code/],
        test => qr/MY_HOSTID="with_code"/,
        stderr => q(
Changes applied to popcon configuration:
- MY_HOSTID: 'aaaaaaaaaaaaaaaaaaaa' -> 'with_code'
)
    },
    {
        label => "line ".__LINE__.": modification with a script with Perl format",
        script => [
            <<'EOS'
# Format:perl
{
   app => 'popcon',
   sub => sub ($root, $arg ) { $root->fetch_element('MY_HOSTID')->store($arg->{to_store});  },
};
EOS
        ],
        args => [qw/--arg to_store=with_code/],
        test => qr/MY_HOSTID="with_code"/,
        stderr => q(
Changes applied to popcon configuration:
- MY_HOSTID: 'aaaaaaaaaaaaaaaaaaaa' -> 'with_code'
)
    },
);


# test cme run real script with arguments
my $i=0;
foreach my $test ( @script_tests) {
    subtest $test->{label} => sub {
        $conf_file->spew_utf8(@orig);
        my $script = $wr_dir->child('my-script'.$i++.'.cme');
        $script->spew_utf8( map { "$_\n"} @{$test->{script}});
        $script->chmod("0755") if $test->{exec_mode};

        my $cmd = [
            run => $script->stringify,
            '-root-dir' => $wr_dir->stringify,
            @{$test->{args} // []}
        ];
        note("cme command: cme @$cmd");
        my $ok = test_app('App::Cme' => $cmd);
        is( $ok->error, undef, 'threw no exceptions');
        is( $ok->exit_code, 0, "all went well" ) or diag("Failed command: @$cmd");

        file_contents_like $conf_file->stringify, $test->{test},
            "updated MY_HOSTID with script" ,{ encoding => 'UTF-8' };
        is(colorstrip($ok->stderr), $test->{stderr} || '', 'run "'.$test->{label}.'" stderr content' );
        is(colorstrip($ok->stdout.''), $test->{stdout} || '', 'run "'.$test->{label}.'": stdout content' );
    };
}

# test failure case for run script
my @bad_script_tests = (
    {
        label => "line ".__LINE__.": modification with a Perl script run by cme run with missing arg",
        script => [ "app:  popcon", 'load ! MY_HOSTID=\$name$name'],
        args => [],
        error_regexp => qr/use option '-arg name=xxx'/
    },
    {
        label => "line ".__LINE__.": modification with a Perl script run by cme run with 2 missing args",
        script => [ "app:  popcon", 'load ! MY_HOSTID=$name1$name2'],
        args => [],
        error_regexp => qr/use option '-arg name1=xxx -arg name2=xxx'/
    },
    {
        label => "line ".__LINE__.": modification with a Perl script run by cme run with missing args in var line",
        script => [
            "app:  popcon",
            'var: $var{name} = $args{name1}.$args{name2}',
            'load: ! MY_HOSTID=$name'],
        args => [],
        error_regexp => qr/use option '-arg name1=xxx -arg name2=xxx'/
    },
    {
        label => "line ".__LINE__.":  load and code section",
        script => [
            "app:  popcon",
            'load: ! MY_HOSTID=$name',
            q!code: $root->load("MY_HOSTID=$name")!,
        ],
        args => [],
        error_regexp => qr/Cannot mix code and load section/
    },
);

foreach my $test ( @bad_script_tests) {
    subtest $test->{label} => sub {
        $conf_file->spew_utf8(@orig);
        my $script = $wr_dir->child('my-script.cme');
        $script->spew_utf8( map { "$_\n"} @{$test->{script}});

        my $cmd = [
            run => $script,
            '-root-dir' => $wr_dir->stringify,
            @{$test->{args}}
        ];
        note("cme command: @$cmd");
        my $oops = test_app('App::Cme' => $cmd);
        isnt( $oops->exit_code, 0, 'wrong command detected' );
        my $re = $test->{error_regexp};
        like( $oops->error.'', $re , "check error message of cme command");
    };
}

done_testing;

__END__
# Config file for Debian's popularity-contest package.
#
# To change this file, use:
#        dpkg-reconfigure popularity-contest

## should be removed

MY_HOSTID="aaaaaaaaaaaaaaaaaaaa"
# we participate
PARTICIPATE="yes"
USEHTTP="yes" # always http
DAY="6"

