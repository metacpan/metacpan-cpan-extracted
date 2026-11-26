use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec;

# Set PERL5LIB so child processes can find dependencies
BEGIN {
    my $blib = File::Spec->rel2abs('blib/lib');
    if (-d $blib) {
        $ENV{PERL5LIB} = join(':', $blib, $ENV{PERL5LIB} // '');
    }
}

use lib '.';
use t::Util;

# The settings of the user are not those of the tests
delete @ENV{qw(NUP_OPTS NUP_PAGER NUP_PAGE_PAGER NUP_LESSKEY LESSKEY_CONTENT)};

is(run()->status, 2, 'no arg');
is(run('--version')->status, 0, '--version');

is(run('-Mup --version')->status, 0, '-Mup --version');
is(run('-Mup --no-pager -- true')->status, 0, '-Mup true');

# Test with --no-pager to avoid interactive mode
like(run('-Mup --no-pager -- echo hello')->stdout, qr/hello/, '-Mup echo hello');

# Test column layout by checking data distribution
# With -C2 -P8, 1..10 should split into two columns (1-8 and 9-10)
subtest 'column layout' => sub {
    my $out = optex('-Mup', '--no-pager', '-C2', '-P8', '--bs=none', '--',
                    'perl', '-e', 'print "$_\n" for 1..10')->run->stdout;
    like($out, qr/^.*\b1\b.*\b9\b.*$/m, '1 and 9 on same line (2 columns)');
    like($out, qr/^.*\b2\b.*\b10\b.*$/m, '2 and 10 on same line (2 columns)');
};

# Test grid option
is(run('-Mup -G2x2 --no-pager -- true')->status, 0, '-G2x2 option works');
is(run('-Mup -G3,2 --no-pager -- true')->status, 0, '-G3,2 option works');

# Test invalid grid format
isnt(run('-Mup -Gabc --no-pager -- true')->status, 0, 'invalid grid fails');

# Test pane option with rows
is(run('-Mup -C2,2 --no-pager -- true')->status, 0, '-C2,2 option works');
isnt(run('-Mup -C2, --no-pager -- true')->status, 0, '-C2, fails');
isnt(run('-Mup -C,2 --no-pager -- true')->status, 0, '-C,2 fails');
isnt(run('-Mup -C2.2 --no-pager -- true')->status, 0, '-C2.2 fails');
isnt(run('-Mup -C2x2 --no-pager -- true')->status, 0, '-C2x2 fails');
subtest 'rows by -C' => sub {
    my @opt = ('--no-pager', '--bs=none', '--', 'perl', '-e', 'print "$_\n" for 1..40');
    my $c = optex('-Mup', '-C2,2', @opt)->run->stdout;
    my $g = optex('-Mup', '-G2x2', @opt)->run->stdout;
    is($c, $g, '-C2,2 is the same as -G2x2');
};

# Test pane and row options
is(run('-Mup -C2 --no-pager -- true')->status, 0, '-C2 option works');
is(run('-Mup -R2 --no-pager -- true')->status, 0, '-R2 option works');
is(run('-Mup -C2 -R2 --no-pager -- true')->status, 0, '-C2 -R2 options work');

# Test border-style option
is(run('-Mup --bs=round-box --no-pager -- true')->status, 0, '--bs option works');

# Test line-style option
is(run('-Mup --ls=truncate --no-pager -- true')->status, 0, '--ls=truncate works');
is(run('-Mup --ls=wrap --no-pager -- true')->status, 0, '--ls=wrap works');

# Test pager selection by NUP_PAGER / NUP_PAGE_PAGER
subtest 'pager environment' => sub {
    local $ENV{NUP_PAGER}      = q(perl -pe s/^/NORMAL:/);
    local $ENV{NUP_PAGE_PAGER} = q(perl -pe s/^/PAGE:/);
    like(run('-Mup -- echo hello')->stdout, qr/^PAGE:/m,
         'page mode uses NUP_PAGE_PAGER');
    like(run('-Mup --no-paginate -- echo hello')->stdout, qr/^NORMAL:/m,
         'no-paginate mode uses NUP_PAGER');
    like(run(q(-Mup --pager='perl -pe s/^/CLI:/' -- echo hello))->stdout,
         qr/^CLI:/m, '--pager overrides environment');
    {
        local %ENV = %ENV;
        delete $ENV{NUP_PAGE_PAGER};
        like(run('-Mup -- echo hello')->stdout, qr/^NORMAL:/m,
             'page mode falls back to NUP_PAGER');
    }
};

# Test --lateral: all the pages in one row, however wide it becomes
subtest 'lateral' => sub {
    use File::Temp ();
    my @cmd = ('--', 'perl', '-e', 'print "$_\n" for 1..40');
    my @opt = ('--no-pager', '--bs=none', '-S20', '-P8');
    my $out = optex('-Mup', '--lateral', @opt, @cmd)->run->stdout;
    is(($out =~ tr/\n//), 8, 'five pages of 8 lines are one row of 8 lines');
    like($out, qr/^.*\b1\b.*\b9\b.*\b17\b.*\b25\b.*\b33\b.*$/m,
         'the first lines of all pages are on the same line');

    # less is told not to wrap the lines and to shift by the pane width
    my $bin = File::Temp->newdir;
    open my $fh, '>', "$bin/less" or die;
    # FAKE_LESS tells the version, and "align-shift" if it has the option
    print $fh <<'SH';
#!/bin/sh
case "$*" in *--version*)
    case "$FAKE_LESS" in *align-shift*) ;;
        *) echo 'There is no --align-shift option ("less --help" for help)' ;;
    esac
    echo "less ${FAKE_LESS%% *} (fake)"
    exit 0 ;;
esac
echo "ARGS: $*"
printf "KEYS: %s\n" "$LESSKEY_CONTENT"
cat >/dev/null
SH
    close $fh;
    chmod 0755, "$bin/less";
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    local %ENV = %ENV;
    delete $ENV{NUP_PAGE_PAGER};
    delete $ENV{LESSKEY_CONTENT};
    $ENV{NUP_PAGER} = 'less --file-size';
    # The screen shows as many panes as without --lateral: as many
    # as fit, or the number given by -C, in the width of the screen
    my($width) = run('-Mup --geometry -- true')->stdout =~ /^(\d+) /
        or die 'no geometry';
    my $pane = sub { my $c = shift; int($width / $c) };
    my $fit  = sub { my $w = shift; $pane->(int($width / $w) || 1) };
    like(optex('-Mup', '--lateral', '-S20', @cmd)->run->stdout,
         qr/^ARGS: --file-size -S --shift=@{[ $fit->(20) ]} --rscroll=-$/m,
         'less shifts by the width of a pane');
    unlike(optex('-Mup', '-S20', @cmd)->run->stdout, qr/--shift/,
           'no shift without --lateral');
    unlike(optex('-Mup', '--lateral', '--no-lateral', '-S20', @cmd)->run->stdout,
           qr/--shift/, '--no-lateral turns it off');

    # The arrow keys, and ESC-) and ESC-( with the same actions, scroll
    # to the right and to the left, H, L, g, G, < and > go to the ends,
    # and space and b move by the panes on the screen: a count of ESC-)
    # and ESC-( with --align-shift, them as many times without.  So
    # do j and k and the down and up arrows: the pages have the height
    # of the screen, and there is nothing to scroll down to.
    my $on_screen = sub { my $w = shift; int($width / $fit->($w)) };
    my $keys = sub {
        my($right, $align) = @_;
        my $n = $on_screen->(20);
        my($fwd, $back) = map { $align ? "$n$_" : $_ x $n } '\e)', '\e(';
        my $end = $align ? "noaction ${n}L" : 'end-scroll';
        "h left-scroll;l $right;, left-scroll;. $right;\\kl left-scroll;\\kr $right;\\e( left-scroll;\\e) $right;H no-scroll;L end-scroll;"
        . "g no-scroll;G $end;< no-scroll;> $end;"
        . "\\  noaction $fwd;f noaction $fwd;b noaction $back;"
        . "j noaction $fwd;k noaction $back;\\kd noaction $fwd;\\ku noaction $back;"
        . "d noaction $fwd;u noaction $back;^D noaction $fwd;^U noaction $back;"
        . "\\r noaction $fwd;\\n noaction $fwd;"
        . "J $end;K no-scroll";
    };
    like(optex('-Mup', '--lateral', '-S20', @cmd)->run->stdout,
         qr/^KEYS: \Q@{[ $keys->('right-scroll', 0) ]}\E$/m,
         'keys are given to less');
    # Without --lateral, the pages fill the screen and go on below:
    # the keys to go down and up move by the screen as space and b.
    # Without pages, they move by the line as usual.
    my $page_keys = 'j forw-screen;k back-screen;\\kd forw-screen;\\ku back-screen;d forw-screen;u back-screen;^D forw-screen;^U back-screen;\\r forw-screen;\\n forw-screen;J goto-end;K goto-line';
    like(optex('-Mup', '-C2', @cmd)->run->stdout,
         qr/^KEYS: \Q$page_keys\E$/m, 'keys of the pages without --lateral');
    like(optex('-Mup', '-C2', '--no-paginate', @cmd)->run->stdout,
         qr/^KEYS: $/m, 'no keys without pages');
    like(optex('-Mup', '-C1', '-A', @cmd)->run->stdout,
         qr/^KEYS: $/m, 'no keys with one pane and --auto-paginate');
    {
        local $ENV{LESSKEY_CONTENT} = 'x quit';
        like(optex('-Mup', '-C2', @cmd)->run->stdout,
             qr/^KEYS: x quit\n#command\n\Q$page_keys\E$/m,
             'keys of the pages are added to LESSKEY_CONTENT of the user');
        local $ENV{NUP_LESSKEY} = '';
        like(optex('-Mup', '-C2', @cmd)->run->stdout,
             qr/^KEYS: x quit$/m, 'no keys of the pages with empty NUP_LESSKEY');
        $ENV{NUP_LESSKEY} = 'y quit';
        like(optex('-Mup', '-C2', @cmd)->run->stdout,
             qr/^KEYS: x quit$/m, 'NUP_LESSKEY is for --lateral');
    }
    {
        # The keys go after the LESSKEY_CONTENT of the user, in a
        # #command section, so that they win over the same keys there
        local $ENV{LESSKEY_CONTENT} = 'x quit';
        like(optex('-Mup', '--lateral', '-S20', @cmd)->run->stdout,
             qr/^KEYS: x quit\n#command\n\Q@{[ $keys->('right-scroll', 0) ]}\E$/m,
             'keys are added to LESSKEY_CONTENT of the user');
    }
    {
        # NUP_LESSKEY gives the keys in place of those of nup, and
        # an empty one gives none, leaving LESSKEY_CONTENT as it is
        local $ENV{NUP_LESSKEY} = 'y quit';
        like(optex('-Mup', '--lateral', @cmd)->run->stdout,
             qr/^KEYS: y quit$/m, 'keys of NUP_LESSKEY');
        local $ENV{LESSKEY_CONTENT} = 'x quit';
        like(optex('-Mup', '--lateral', @cmd)->run->stdout,
             qr/^KEYS: x quit\n#command\ny quit$/m,
             'keys of NUP_LESSKEY are added to LESSKEY_CONTENT');
        $ENV{NUP_LESSKEY} = '';
        like(optex('-Mup', '--lateral', @cmd)->run->stdout,
             qr/^KEYS: x quit$/m, 'LESSKEY_CONTENT is kept with empty NUP_LESSKEY');
        delete $ENV{LESSKEY_CONTENT};
        like(optex('-Mup', '--lateral', @cmd)->run->stdout,
             qr/^KEYS: $/m, 'no keys with empty NUP_LESSKEY');
    }
    # A less of 710 or later stops the right arrow at the right end,
    # and one that has --align-shift keeps the shift at the boundaries
    # of the panes
    for (['709x',             'right-scroll',       ''],
         ['710',              'right-limit-scroll', ''],
         ['713x align-shift', 'right-limit-scroll', ' --align-shift']) {
        my($less, $right, $align) = @$_;
        local $ENV{FAKE_LESS} = $less;
        my $out = optex('-Mup', '--lateral', '-S20', @cmd)->run->stdout;
        like($out, qr/^ARGS: --file-size -S --shift=@{[ $fit->(20) ]} --rscroll=-\Q$align\E$/m,
             "less $less: options");
        like($out, qr/^KEYS: \Q@{[ $keys->($right, $align) ]}\E$/m,
             "less $less: right is $right" . ($align ? ', space and b by a count' : ''));
    }
    like(optex('-Mup', '-L', "--pager=$bin/less -R", @cmd)->run->stdout,
         qr/^ARGS: -R -S --shift=@{[ $fit->(85) ]} --rscroll=-$/m,
         '-L, less given by --pager with a path, default pane width');
    # +Gg of the default pager is left out: g and G are keys of the
    # row there, and would leave less at its right end
    {
        local $ENV{NUP_PAGER};
        delete $ENV{NUP_PAGER};
        like(optex('-Mup', '--lateral', '-S20', @cmd)->run->stdout,
             qr/^ARGS: -F -S --shift=@{[ $fit->(20) ]} --rscroll=-$/m,
             '--lateral: no +Gg in the default pager');
        like(optex('-Mup', '-S20', @cmd)->run->stdout,
             qr/^ARGS: -F \+Gg$/m, '+Gg stays without --lateral');
    }
    like(optex('-Mup', '--lateral', '-C4', @cmd)->run->stdout,
         qr/^ARGS: --file-size -S --shift=@{[ $pane->(4) ]} --rscroll=-$/m,
         '-C4 shows four panes on the screen');
    {
        my $row = optex('-Mup', '--lateral', '-C4', '-P8', '--no-pager', @cmd)->run->stdout;
        my($top) = $row =~ /\A(.*)\n/;
        $top =~ s/\e\[[\d;]*[mK]//g;
        utf8::decode($top) unless utf8::is_utf8($top);
        # a page of 8 lines has 6 lines of text inside the border
        is(length $top, $pane->(4) * 7, 'seven panes, each a quarter of the screen');
    }
    # Without pages, as for the files side by side, only the arrow
    # keys, ESC-) and ESC-(, H, L, < and > are put, and the other keys
    # move up and down as usual
    like(optex('-Mup', '--lateral', '--no-paginate', '-S20', @cmd)->run->stdout,
         qr/^KEYS: h left-scroll;l right-scroll;, left-scroll;\. right-scroll;\\kl left-scroll;\\kr right-scroll;\\e\( left-scroll;\\e\) right-scroll;H no-scroll;L end-scroll;< no-scroll;> end-scroll$/m,
         'without pages, only the arrows, H, L, < and >');
    like(optex('-Mup', '--lateral', '--no-paginate', '-S20', @cmd)->run->stdout,
         qr/^ARGS: --file-size -S --shift=@{[ $fit->(20) ]} --rscroll=-$/m,
         'without pages, less shifts by the width of a pane');

    $ENV{NUP_PAGER} = q(perl -pe s/^/OTHER:/);
    my $other = optex('-Mup', '--lateral', '-S20', @cmd)->run;
    like($other->stdout, qr/^OTHER:/m, 'another pager is used as it is');
    is($other->status, 0, 'another pager gets no option of less');

    # what makes no sense with one row of pages
    for my $with ('-R2', '-C2,2', '-G2x2', '-T a4', '-o out.pdf') {
        isnt(run("-Mup --lateral $with --no-pager -- true")->status, 0,
             "--lateral with $with fails");
    }
    ok(!-e 'out.pdf', 'no file is written');
};

# Test PDF output: a device other than tty is a paper, printed by ansi2pdf
subtest 'device and output' => sub {
    plan skip_all => 'ansi2pdf is not available'
        unless (qx(ansi2pdf --geometry -p a4p 2>/dev/null) // '') =~ /^\d+ \d+$/;
    use File::Temp qw(tempdir);
    my $dir = tempdir(CLEANUP => 1);
    my $box = sub {
        my $pdf = shift;
        $pdf =~ m{/MediaBox \[0 0 ([\d.]+) ([\d.]+)\]} or return 'no page';
        $1 > $2 ? 'landscape' : 'portrait';
    };
    # PDF is binary, and the runner reads the output as UTF-8
    local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /does not map to Unicode/ };
    my $pdf = sub { run("-Mup @_ -- echo hello")->stdout };
    my $file = sub {
        open my $fh, '<:raw', "$dir/$_[0]" or return '';
        local $/; scalar <$fh>;
    };

    like $pdf->('-T pdf'), qr/%PDF-/, '-T pdf writes PDF to stdout';
    is $box->($pdf->('-T pdf')),  'landscape', '-T pdf is landscape';
    is $box->($pdf->('-T a4')),   'landscape', '-T a4 is landscape';
    is $box->($pdf->('-T a4p')),  'portrait',  '-T a4p is portrait';
    is $box->($pdf->('-T a4l')),  'landscape', '-T a4l is landscape';
    is $box->($pdf->('--device=a4p')), 'portrait', '--device';
    is $box->($pdf->('-T a4p --pdf-opts=-L')), 'landscape', 'pdf-opts come last';
    unlike $pdf->('-T tty --no-pager'), qr/%PDF-/, '-T tty is not PDF';

    unlike $pdf->("-T a4p -o $dir/a.pdf"), qr/%PDF-/, '-o: no PDF to stdout';
    is $box->($file->('a.pdf')), 'portrait', '-T a4p -o FILE';
    $pdf->("-o $dir/b.pdf");
    is $box->($file->('b.pdf')), 'landscape', '-o FILE.pdf alone is PDF';

    # -o writes what is shown on the terminal, when the device is tty
    unlike $pdf->("-o $dir/d.txt"), qr/hello/, '-o FILE: nothing to stdout';
    like   $file->('d.txt'), qr/hello/, '-o FILE writes the text';
    unlike $file->('d.txt'), qr/%PDF-/, '-o FILE is not PDF';
    $pdf->("-T tty -o $dir/e.pdf");
    like   $file->('e.pdf'), qr/hello/, '-T tty -o FILE.pdf writes the text';
    unlike $file->('e.pdf'), qr/%PDF-/, '-T tty -o FILE.pdf is not PDF';
    isnt run("-Mup -T nosuch --no-pager -- true")->status, 0,
        'unknown paper fails';

    # --geometry tells the size of the device and its kind
    my $geom = sub { run("-Mup @_ --geometry -- echo hello")->stdout };
    my $paper = sub { chomp(my $g = qx(ansi2pdf -C1 --no-border -L @_ --geometry)); $g };
    is $geom->('-T a4p'), $paper->('-p a4p') . " pdf\n", '--geometry -T a4p';
    is $geom->('-T pdf'), $paper->() . " pdf\n", '--geometry -T pdf';
    is $geom->("-o $dir/g.pdf"), $paper->() . " pdf\n", '--geometry -o FILE.pdf';
    ok !-e "$dir/g.pdf", '--geometry writes no file';
    is $geom->('-T a4 -P 40 -C2,2'), $paper->('-p a4 -l 80') . " pdf\n", '--geometry with -P and rows';
    like $geom->('-T a4 -P 40 -C2,2'), qr/^\d+ 80 pdf$/, '--geometry tells the lines of a sheet';
    unlike $geom->('-T a4p'), qr/hello/, '--geometry does not run the command';
    like $geom->("-o $dir/g.txt"), qr/^\d+ \d+ tty$/, '--geometry -o FILE is tty';
    ok !-e "$dir/g.txt", '--geometry writes no file for tty';
};

# On paper, the start of each pane is marked for ansi2pdf (ansicolumn
# --pane-osc), so that the text of a PDF is in the order of the panes;
# an ansi2pdf of the test keeps what it is given
subtest 'panes marked on paper' => sub {
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/ansi2pdf" or die;
    print $fh "#!/bin/sh\n",
        "case \" \$* \" in *' --geometry '*) echo '100 40'; exit;; esac\n",
        "cat > $dir/in.txt\n";
    close $fh;
    chmod 0755, "$dir/ansi2pdf";
    local $ENV{PATH} = "$dir:$ENV{PATH}";
    my $read = sub { local $/; open my $fh, '<', "$dir/in.txt" or return ''; <$fh> };
    optex('-Mup', '-C2', '-T', 'a4', '-o', 'x.pdf', '--', 'perl', '-e', 'print "$_\n" for 1..60')->run;
    my $n = () = $read->() =~ /\e\]7772;\e\\/g;
    is $n, 2, 'a mark for each pane';
    like $read->(), qr/\e\]7772;\e\x5c1\b/, 'at the start of the text';
    unlink "$dir/in.txt";
    my $tty = optex('-Mup', '-C2', '--pager', "cat > $dir/in.txt", '--', 'echo', 'hello')->run;
    like   $read->(), qr/hello/, 'to the pager';
    unlike $read->(), qr/\e\]7772;/, 'no mark on the terminal';
};

# --highlight gives ansicolumn the option to read the files through
# the highlighter
subtest 'highlight' => sub {
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    # an ansicolumn which shows its arguments
    open my $fh, '>', "$dir/ansicolumn" or die;
    print $fh qq{#!/bin/sh\nprintf '[%s]' "\$@"\n};
    close $fh;
    chmod 0755, "$dir/ansicolumn" or die;
    local $ENV{PATH} = "$dir:$ENV{PATH}";

    # ansicolumn needs Text::ANSI::Highlight::IO for the option, and
    # fails by it without the module: --highlight does nothing unless
    # it is there
  SKIP: {
        skip 'Text::ANSI::Highlight::IO is installed', 1
            if grep { -f "$_/Text/ANSI/Highlight/IO.pm" } @INC, split /:/, $ENV{PERL5LIB} // '';
        unlike run('-Mup --highlight=pandoc --no-pager -- ansicolumn FILE')->stdout,
            qr/highlight/, 'not without the module';
    }

    # with it: the module file is only looked for, not loaded
    mkdir "$dir/lib" and mkdir "$dir/lib/Text" and mkdir "$dir/lib/Text/ANSI"
        and mkdir "$dir/lib/Text/ANSI/Highlight" or die;
    {
        open my $fh, '>', "$dir/lib/Text/ANSI/Highlight/IO.pm" or die;
        print $fh "die 'not to be loaded';\n";
        close $fh;
    }
    local $ENV{PERL5LIB} = join ':', "$dir/lib", $ENV{PERL5LIB} // ();

    like run('-Mup --highlight=pandoc:breezedark --no-pager -- ansicolumn FILE')->stdout,
        qr/\A\[--highlight=pandoc:breezedark\]/, 'a style after the name';
    unlike run("-Mup '--highlight=a b' --no-pager -- ansicolumn FILE")->stdout,
        qr/highlight/, 'not a name';
    like run('-Mup --highlight=pandoc --no-pager -- ansicolumn FILE -w 100')->stdout,
        qr/\A\[--highlight=pandoc\]\[--bs=.*\[FILE\]\[-w\]\[100\]\z/,
        'ansicolumn gets --highlight';
    like run('-Mup --highlight=gnu --no-pager -- ansicolumn FILE')->stdout,
        qr/\A\[--highlight=gnu\]/, 'the name is given as it is';
    unlike run('-Mup --highlight=a/b --no-pager -- ansicolumn FILE')->stdout,
        qr/highlight/, 'a name which is not a word is not given';
    unlike run('-Mup --no-pager -- ansicolumn FILE')->stdout, qr/highlight/,
        'not without --highlight';
    unlike run('-Mup --highlight=pandoc --no-pager -- echo hello')->stdout, qr/highlight/,
        'not in command mode';
};

like run('-Mup --geometry -- echo hello')->stdout, qr/\A\d+ \d+ tty\n\z/, '--geometry on the terminal';

done_testing;
