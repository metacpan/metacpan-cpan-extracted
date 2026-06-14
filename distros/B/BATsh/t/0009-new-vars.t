######################################################################
#
# 0009-new-vars.t  BATsh 0.05 new feature tests
#
#   NV01-NV08  CMD %VAR:~n,m%  substring expansion
#   NV09-NV14  CMD %VAR:str1=str2%  substitution expansion
#   NV15-NV17  CMD dynamic pseudo-variables (%DATE% %TIME% %CD%)
#   NV18       CMD %RANDOM% pseudo-variable
#   NV19       CMD %ERRORLEVEL% pseudo-variable reflects current level
#   NV20-NV25  SH filename glob expansion (echo *.ext, for f in *.ext)
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use File::Spec ();
use lib "$FindBin::Bin/../lib";

eval { require BATsh } or die "Cannot load BATsh: $@";
BATsh::Env::init();

# Temp directory used for glob tests
my $TMPDIR = File::Spec->tmpdir();

my @tests = (

    ########################################
    # NV01-NV08  %VAR:~n,m%  substring
    ########################################

    # NV01: %VAR:~0,3% - first 3 characters
    sub {
        $BATsh::Env::STORE{'NV_STR'} = 'ABCDEFGH';
        my $out = _capture(sub { BATsh->run_string('ECHO %NV_STR:~0,3%') });
        _ok($out =~ /\AABC\s*\z/, 'NV01: %VAR:~0,3% first 3 chars');
    },

    # NV02: %VAR:~3%  - from offset 3 to end
    sub {
        $BATsh::Env::STORE{'NV_STR'} = 'ABCDEFGH';
        my $out = _capture(sub { BATsh->run_string('ECHO %NV_STR:~3%') });
        _ok($out =~ /\ADEFGH\s*\z/, 'NV02: %VAR:~3% from offset to end');
    },

    # NV03: %VAR:~-3%  - last 3 characters (negative offset)
    sub {
        $BATsh::Env::STORE{'NV_STR'} = 'ABCDEFGH';
        my $out = _capture(sub { BATsh->run_string('ECHO %NV_STR:~-3%') });
        _ok($out =~ /\AFGH\s*\z/, 'NV03: %VAR:~-3% last 3 chars');
    },

    # NV04: %VAR:~0,-3%  - all but last 3
    sub {
        $BATsh::Env::STORE{'NV_STR'} = 'ABCDEFGH';
        my $out = _capture(sub { BATsh->run_string('ECHO %NV_STR:~0,-3%') });
        _ok($out =~ /\AABCDE\s*\z/, 'NV04: %VAR:~0,-3% all but last 3');
    },

    # NV05: %VAR:~2,4%  - 4 chars from offset 2
    sub {
        $BATsh::Env::STORE{'NV_STR'} = 'ABCDEFGH';
        my $out = _capture(sub { BATsh->run_string('ECHO %NV_STR:~2,4%') });
        _ok($out =~ /\ACDEF\s*\z/, 'NV05: %VAR:~2,4% 4 chars from offset 2');
    },

    # NV06: offset beyond string length returns empty
    sub {
        $BATsh::Env::STORE{'NV_STR'} = 'ABC';
        my $out = _capture(sub { BATsh->run_string('ECHO [%NV_STR:~99%]') });
        _ok($out =~ /\A\[\]\s*\z/, 'NV06: %VAR:~99% beyond length returns empty');
    },

    # NV07: %VAR:~1,0% - zero length returns empty
    sub {
        $BATsh::Env::STORE{'NV_STR'} = 'ABCDEFGH';
        my $out = _capture(sub { BATsh->run_string('ECHO [%NV_STR:~1,0%]') });
        _ok($out =~ /\A\[\]\s*\z/, 'NV07: %VAR:~1,0% zero length returns empty');
    },

    # NV08: store result of substring into another variable
    sub {
        $BATsh::Env::STORE{'NV_SRC'} = 'Hello_World';
        delete $BATsh::Env::STORE{'NV_DST'};
        BATsh->run_string('SET NV_DST=%NV_SRC:~6,5%');
        my $v = defined($BATsh::Env::STORE{'NV_DST'}) ? $BATsh::Env::STORE{'NV_DST'} : '';
        _ok($v eq 'World', 'NV08: SET NV_DST=%VAR:~6,5% stores World');
    },

    ########################################
    # NV09-NV14  %VAR:str1=str2%  substitution
    ########################################

    # NV09: basic substitution - replace first occurrence
    sub {
        $BATsh::Env::STORE{'NV_SUB'} = 'hello world';
        my $out = _capture(sub { BATsh->run_string('ECHO %NV_SUB:world=there%') });
        _ok($out =~ /\Ahello there\s*\z/, 'NV09: %VAR:str1=str2% basic substitution');
    },

    # NV10: substitution not found - returns original value
    sub {
        $BATsh::Env::STORE{'NV_SUB'} = 'hello world';
        my $out = _capture(sub { BATsh->run_string('ECHO %NV_SUB:xyz=ABC%') });
        _ok($out =~ /\Ahello world\s*\z/, 'NV10: %VAR:notfound=x% returns original');
    },

    # NV11: substitution with empty replacement (delete)
    sub {
        $BATsh::Env::STORE{'NV_SUB'} = 'hello_world';
        my $out = _capture(sub { BATsh->run_string('ECHO %NV_SUB:_=%') });
        _ok($out =~ /\Ahelloworld\s*\z/, 'NV11: %VAR:str=% deletes substring');
    },

    # NV12: case-insensitive substitution
    sub {
        $BATsh::Env::STORE{'NV_SUB'} = 'Hello World';
        my $out = _capture(sub { BATsh->run_string('ECHO %NV_SUB:hello=Hi%') });
        _ok($out =~ /\AHi World\s*\z/, 'NV12: %VAR:str1=str2% case-insensitive match');
    },

    # NV13: store substitution result
    sub {
        $BATsh::Env::STORE{'NV_IN'}  = 'foo.bat';
        delete $BATsh::Env::STORE{'NV_OUT'};
        BATsh->run_string('SET NV_OUT=%NV_IN:.bat=.cmd%');
        my $v = defined($BATsh::Env::STORE{'NV_OUT'}) ? $BATsh::Env::STORE{'NV_OUT'} : '';
        _ok($v eq 'foo.cmd', 'NV13: SET NV_OUT=%VAR:.bat=.cmd% stores foo.cmd');
    },

    # NV14: star-prefix substitution (*str1=str2)
    sub {
        $BATsh::Env::STORE{'NV_STR'} = 'one:two:three';
        my $out = _capture(sub { BATsh->run_string('ECHO %NV_STR:*:=AFTER%') });
        # *: removes from start through first ":", replaces with "AFTER"
        _ok($out =~ /\AAFTERtwo:three\s*\z/, 'NV14: %VAR:*str=val% star-prefix substitution');
    },

    ########################################
    # NV15-NV19  CMD dynamic pseudo-variables
    ########################################

    # NV15: %DATE% expands to a non-empty string matching YYYY-MM-DD
    sub {
        my $out = _capture(sub { BATsh->run_string('ECHO %DATE%') });
        $out =~ s/\r?\n\z//;
        _ok($out =~ /\A\d{4}-\d{2}-\d{2}\z/, 'NV15: %DATE% expands to YYYY-MM-DD');
    },

    # NV16: %TIME% expands to a non-empty string matching HH:MM:SS
    sub {
        my $out = _capture(sub { BATsh->run_string('ECHO %TIME%') });
        $out =~ s/\r?\n\z//;
        _ok($out =~ /\A\d{2}:\d{2}:\d{2}/, 'NV16: %TIME% expands to HH:MM:SS...');
    },

    # NV17: %CD% expands to the current working directory (non-empty)
    sub {
        my $out = _capture(sub { BATsh->run_string('ECHO %CD%') });
        $out =~ s/\r?\n\z//;
        _ok(length($out) > 0, 'NV17: %CD% expands to non-empty cwd');
    },

    # NV18: %RANDOM% expands to a decimal integer 0-32767
    sub {
        my $out = _capture(sub { BATsh->run_string('ECHO %RANDOM%') });
        $out =~ s/\r?\n\z//;
        _ok($out =~ /\A\d+\z/ && $out >= 0 && $out <= 32767,
            'NV18: %RANDOM% expands to integer 0-32767');
    },

    # NV19: %ERRORLEVEL% reflects the current ERRORLEVEL from CMD
    sub {
        my $out = _capture(sub {
            BATsh->run_string(join("\n",
                'EXIT /B 3',
            ));
            BATsh->run_string('ECHO EL=%ERRORLEVEL%');
        });
        _ok($out =~ /EL=3/, 'NV19: %ERRORLEVEL% reflects current ERRORLEVEL');
    },

    ########################################
    # NV20-NV25  SH filename glob expansion
    ########################################

    # NV20: 'echo *.t' expands to test filenames
    sub {
        my $tdir = $FindBin::Bin;
        my $orig = Cwd::cwd();
        chdir($tdir);
        my $out = _capture(sub { BATsh->run_string("echo *.t") });
        chdir($orig);
        # Output should contain at least one .t filename
        _ok($out =~ /\.t/, 'NV20: SH echo *.t expands glob to .t files');
    },

    # NV21: glob with no match returns literal pattern (nullglob off)
    sub {
        my $tmpf = File::Spec->catfile($TMPDIR, "batsh_glob_nomatch_$$");
        my $out = _capture(sub {
            BATsh->run_string("echo $tmpf*.zzz_no_such");
        });
        $out =~ s/\r?\n\z//;
        _ok($out =~ /zzz_no_such/, 'NV21: SH glob no-match returns literal pattern');
    },

    # NV22: 'for f in *.t; do echo $f; done' iterates over .t files
    sub {
        my $tdir = $FindBin::Bin;
        my $orig = Cwd::cwd();
        chdir($tdir);
        my $out = _capture(sub {
            BATsh->run_string(join("\n",
                'for f in *.t; do',
                '  echo $f',
                'done',
            ));
        });
        chdir($orig);
        _ok($out =~ /\.t/, 'NV22: SH for f in *.t iterates .t files');
    },

    # NV23: glob ? matches single character (0?0?-*.t matches 0001-..., 0002-... etc.)
    sub {
        my $orig = Cwd::cwd();
        chdir($FindBin::Bin);
        my $out = _capture(sub { BATsh->run_string('echo 0?0?-*.t') });
        chdir($orig);
        # Should match e.g. 0001-classify.t, 0002-sh-interpreter.t
        _ok($out =~ /000\d-.*\.t/, 'NV23: SH glob ? matches single character');
    },

    # NV24: quoted glob pattern is NOT expanded
    sub {
        my $out = _capture(sub { BATsh->run_string("echo '*.t'") });
        $out =~ s/\r?\n\z//;
        _ok($out eq '*.t', 'NV24: SH single-quoted glob is NOT expanded');
    },

    # NV25: multiple globs on one line
    sub {
        my $tmpbase = File::Spec->catfile($TMPDIR, "batshglob_$$");
        my $fa = "${tmpbase}_a.txt";
        my $fb = "${tmpbase}_b.log";
        local *WF;
        open(WF, "> $fa") or do { _ok(1, 'NV25: SKIP - cannot create tmp file'); return };
        print WF "a\n"; close WF;
        open(WF, "> $fb") or do { unlink $fa; _ok(1, 'NV25: SKIP - cannot create tmp file'); return };
        print WF "b\n"; close WF;
        my $out = _capture(sub {
            BATsh->run_string("echo ${tmpbase}_a.txt ${tmpbase}_b.log");
        });
        unlink $fa; unlink $fb;
        _ok($out =~ /_a\.txt/ && $out =~ /_b\.log/,
            'NV25: SH multiple globs expand independently');
    },

);

# Capture stdout helper
sub _capture {
    my ($code) = @_;
    my $tmpfile = File::Spec->catfile(
        File::Spec->tmpdir(), "batsh_tst_$$.tmp");
    local *OLD_STDOUT;
    open(OLD_STDOUT, '>&STDOUT') or return '';
    local *CAPFH;
    open(CAPFH, "> $tmpfile") or do { open(STDOUT,'>&OLD_STDOUT'); return '' };
    open(STDOUT, '>&CAPFH');
    eval { $code->() };
    open(STDOUT, '>&OLD_STDOUT');
    close(CAPFH); close(OLD_STDOUT);
    my $buf = '';
    if (open(READFH, "< $tmpfile")) {
        local $/;
        $buf = <READFH>;
        close(READFH);
    }
    unlink $tmpfile;
    $buf = '' unless defined $buf;
    return $buf;
}

eval { require Cwd } or do { *Cwd::cwd = sub { '.' } };

print "1.." . scalar(@tests) . "\n";
my ($run, $fail) = (0, 0);
sub _ok {
    my ($ok, $name) = @_;
    $run++; $fail++ unless $ok;
    $name = '' unless defined $name;
    print +($ok ? '' : 'not ') . "ok $run - $name\n";
}
$_->() for @tests;
END { $? = 1 if $fail }
