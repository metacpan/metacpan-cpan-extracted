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
echo "KEYS: $LESSKEY_CONTENT"
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

    # h and l of less scroll to the left and to the right
    like(optex('-Mup', '--lateral', @cmd)->run->stdout,
         qr/^KEYS: h left-scroll;l right-scroll;H no-scroll;L end-scroll$/m,
         'h, l, H and L are given to less');
    like(optex('-Mup', @cmd)->run->stdout,
         qr/^KEYS: $/m, 'no keys without --lateral');
    {
        local $ENV{LESSKEY_CONTENT} = 'x quit';
        like(optex('-Mup', '--lateral', @cmd)->run->stdout,
             qr/^KEYS: x quit$/m, 'LESSKEY_CONTENT of the user is kept');
    }
    # A less of 710 or later stops l at the right end, and one that has
    # --align-shift keeps the shift at the boundaries of the panes
    my $keys = sub { "h left-scroll;l $_[0];H no-scroll;L end-scroll" };
    for (['709x',             'right-scroll',       ''],
         ['710',              'right-limit-scroll', ''],
         ['713x align-shift', 'right-limit-scroll', ' --align-shift']) {
        my($less, $right, $align) = @$_;
        local $ENV{FAKE_LESS} = $less;
        my $out = optex('-Mup', '--lateral', '-S20', @cmd)->run->stdout;
        like($out, qr/^ARGS: --file-size -S --shift=@{[ $fit->(20) ]} --rscroll=-\Q$align\E$/m,
             "less $less: options");
        like($out, qr/^KEYS: \Q@{[ $keys->($right) ]}\E$/m, "less $less: l is $right");
    }
    like(optex('-Mup', '-L', "--pager=$bin/less -R", @cmd)->run->stdout,
         qr/^ARGS: -R -S --shift=@{[ $fit->(85) ]} --rscroll=-$/m,
         '-L, less given by --pager with a path, default pane width');
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
    $ENV{NUP_PAGER} = q(perl -pe s/^/OTHER:/);
    my $other = optex('-Mup', '--lateral', '-S20', @cmd)->run;
    like($other->stdout, qr/^OTHER:/m, 'another pager is used as it is');
    is($other->status, 0, 'another pager gets no option of less');

    # what makes no sense with one row of pages
    for my $with ('-R2', '-C2,2', '-G2x2', '--no-paginate', '-T a4', '-o out.pdf') {
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

like run('-Mup --geometry -- echo hello')->stdout, qr/\A\d+ \d+ tty\n\z/, '--geometry on the terminal';

done_testing;
