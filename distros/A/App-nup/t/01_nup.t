use strict;
use warnings;
use Test::More;
use File::Spec;
use Config;

# Set PERL5LIB and PATH so child processes can find dependencies
BEGIN {
    my $blib = File::Spec->rel2abs('blib/lib');
    if (-d $blib) {
        $ENV{PERL5LIB} = join(':', $blib, $ENV{PERL5LIB} // '');
    }
    # Add Perl's bin directories to PATH for getoptlong.sh
    my @bindirs = grep { defined && -d } (
        $Config{installsitebin},
        $Config{installvendorbin},
        $Config{installbin},
    );
    $ENV{PATH} = join(':', @bindirs, $ENV{PATH} // '');
}

# Skip tests on platforms without bash or with old bash
BEGIN {
    my $bash_check = `bash --version 2>&1`;
    if ($? != 0) {
        plan skip_all => 'bash is not available on this system';
    }
    if ($bash_check =~ /version (\d+)\.(\d+)/) {
        my ($major, $minor) = ($1, $2);
        if ($major < 4 || ($major == 4 && $minor < 3)) {
            plan skip_all => "bash 4.3+ required (found $major.$minor)";
        }
    }
}

# The settings of the user are not those of the tests: with NUP_OPTS=-L,
# every command would have -L and its labels
delete @ENV{qw(NUP_OPTS NUP_PAGER NUP_PAGE_PAGER NUP_LESSKEY)};

my $script = File::Spec->rel2abs('script/nup');

# The command line by the dry-run.  The syntax highlight depends on the
# command of the highlighter being installed, so it is off here, and is
# tested by nup_highlight.
sub nup {
    nup_highlight('--no-highlight', @_);
}

sub nup_highlight {
    my @args = @_;
    my $cmd = "$script -n @args 2>&1";
    chomp(my $out = `$cmd`);
    $out;
}

subtest 'file view mode (default)' => sub {
    my $out = nup('script/nup cpanfile');
    like $out, qr/optex -Mup/, 'uses optex -Mup';
    like $out, qr/--filename/, '--filename passed to up.pm';
    like $out, qr/-- ansicolumn/, 'runs ansicolumn';
    like $out, qr/script\/nup/, 'includes first file';
    like $out, qr/cpanfile/, 'includes second file';
};

subtest 'single file uses file view' => sub {
    my $out = nup('script/nup');
    like $out, qr/optex -Mup/, 'single file uses optex -Mup';
    like $out, qr/--filename/, '--filename passed to up.pm';
    like $out, qr/-- ansicolumn/, 'single file runs ansicolumn';
};

subtest 'file view with options' => sub {
    my $out = nup('-S 60 --bs=round-box script/nup cpanfile');
    like $out, qr/-S 60/, 'pane-width passed via short option';
    like $out, qr/--bs round-box/, 'border-style passed to up.pm';
};

subtest 'no-filename option' => sub {
    my $out = nup('--no-filename script/nup');
    like $out, qr/--no-filename/, '--no-filename passed to up.pm';
};

subtest 'parallel option' => sub {
    my $out = nup('-V script/nup');
    like $out, qr/-V/, '-V passed to up.pm';
    like $out, qr/--no-paginate/, '-V disables page mode';
};

subtest 'page mode disabled for parallel layout' => sub {
    my $out = nup('script/nup cpanfile');
    like $out, qr/--no-paginate/, 'multiple files disable page mode';
    $out = nup('script/nup');
    unlike $out, qr/--no-paginate/, 'single file keeps page mode';
    $out = nup('script/nup -w 100');
    unlike $out, qr/--no-paginate/, 'options after the file are not files';
    $out = nup('- --boundary=word');
    unlike $out, qr/--no-paginate/, 'options after - are not files';
    $out = nup('script/nup cpanfile -w 100');
    like $out, qr/--no-paginate/, 'two files and options disable page mode';
    $out = nup('date');
    unlike $out, qr/--no-paginate/, 'command mode keeps page mode';
    $out = nup('-V date');
    like $out, qr/--no-paginate/, '-V in command mode disables page mode';
};

subtest 'no-paginate option' => sub {
    my $out = nup('-F script/nup');
    like $out, qr/--no-paginate/, '-F converted to --no-paginate';
};

subtest 'no-fold re-enables paginate' => sub {
    my $out = nup('-F --no-fold script/nup');
    unlike $out, qr/--no-paginate/, '--no-fold re-enables paginate';
};

subtest 'auto-paginate option' => sub {
    my $out = nup('-A script/nup');
    like $out, qr/-A/, '-A passed to up.pm';
};

subtest 'auto command mode' => sub {
    my $out = nup('date');
    like $out, qr/optex -Mup .* -- date$/, 'command auto-detected';
    unlike $out, qr/ansicolumn/, 'command does not use ansicolumn';
};

subtest 'exec option forces command mode' => sub {
    my $out = nup('-e script/nup');
    like $out, qr/optex -Mup .* -- script\/nup$/, '-e forces command mode for file';
    unlike $out, qr/ansicolumn/, '-e does not use ansicolumn';
};

subtest 'grid option' => sub {
    my $out = nup('-G 2x3 date');
    like $out, qr/-G 2x3/, 'grid option via short form';
    like $out, qr/-- date$/, 'command after --';
};

subtest 'pane option' => sub {
    my $out = nup('-C 2 date');
    like $out, qr/-C 2/, 'pane option via short form';
};

subtest 'row option' => sub {
    my $out = nup('-R 3 date');
    like $out, qr/-R 3/, 'row option via short form';
};

subtest 'pane-width option' => sub {
    my $out = nup('-S 100 date');
    like $out, qr/-S 100/, 'pane-width option via short form';
};

subtest 'border-style option' => sub {
    my $out = nup('--bs=round-box date');
    like $out, qr/--bs round-box/, 'border-style option';
};

subtest 'line-style option' => sub {
    my $out = nup('--ls=truncate date');
    like $out, qr/--ls truncate/, 'line-style option';
};

subtest 'run-in options' => sub {
    like nup('--runlen=4 date'), qr/--runlen 4/, 'runlen option';
    like nup('--runin=3 --runout=1 date'), qr/--runin 3 --runout 1/, 'runin and runout options';
    like nup('--boundary=none date'), qr/--boundary none/, 'boundary option';
};

subtest 'pager option' => sub {
    my $out = nup('--pager=less date');
    like $out, qr/--pager=less/, 'pager with value';

    $out = nup('--pager= date');
    like $out, qr/--no-pager/, 'pager empty (disable)';

    $out = nup('--no-pager date');
    like $out, qr/--no-pager/, '--no-pager';
};

subtest 'no pager option' => sub {
    my $out = nup('date');
    unlike $out, qr/--pager/, 'no pager option by default';
};

subtest 'combined options' => sub {
    my $out = nup('-G 2x2 -S 80 --bs=heavy-box date');
    like $out, qr/-G 2x2/, 'grid';
    like $out, qr/-S 80/, 'pane-width';
    like $out, qr/--bs heavy-box/, 'border-style';
    like $out, qr/-- date$/, 'command at end';
};

subtest 'lateral option' => sub {
    like nup('--lateral date'), qr/-Mup .*--lateral .*-- date$/, 'lateral, command';
    like nup('--lateral cpanfile'), qr/--lateral .*-- ansicolumn cpanfile$/, 'lateral, file';
    like nup('-L -C4 date'), qr/-Mup .* -L .*-C 4 .*-- date$/, '-L with -C';
    unlike nup('--lateral cpanfile'), qr/--no-paginate/, 'page mode is kept';
    # files side by side go on to the right, without pages
    like nup('-L cpanfile Changes'), qr/-Mup .* -L .*--no-paginate -- ansicolumn cpanfile Changes$/,
        '-L with two files';
    like nup('-L -V cpanfile'), qr/-Mup .* -L -V .*--no-paginate -- ansicolumn cpanfile$/,
        '-L with -V';
    like nup('-L -V date'), qr/-Mup .* -L .*--no-paginate -- date$/, '-L with -V, command';
    unlike nup('-L cpanfile -w 100'), qr/--no-paginate/, 'an option after the file is not a file';
    # one input without pages has nothing to put on the right
    my $out = nup('-L -F cpanfile');
    like $out, qr/ -L .*--no-lateral .*--no-paginate -- ansicolumn cpanfile$/,
        '-L is turned off with -F and one file';
};

subtest 'NUP_OPTS' => sub {
    local $ENV{NUP_OPTS} = '-L -C3';
    like nup('date'), qr/-Mup .* -L .*-C 3 .*-- date$/, 'options of NUP_OPTS';
    like nup('-C2 date'), qr/-C 3 -C 2 .*-- date$/,
        'options on the command line come after them';
    like nup('cpanfile Changes'), qr/ -L .*--no-paginate -- ansicolumn cpanfile Changes$/,
        'they work as the others';
    $ENV{NUP_OPTS} = '';
    unlike nup('date'), qr/ -L /, 'empty NUP_OPTS';
};

subtest 'pdf options' => sub {
    like nup(q(-o out.pdf --pdf-opts="-m 15 -l 80" date)),
        qr/--pdf-opts -m 15 -l 80 /, 'pdf-opts';
    isnt system("$script -n --pdf date >/dev/null 2>&1"), 0, '--pdf is gone';
};

subtest 'device and output options' => sub {
    like nup('-T a4p date'), qr/-T a4p /, 'device';
    like nup('--device=a4p date'), qr/--device a4p /, 'device, long';
    like nup('-o out.pdf date'), qr/-o out\.pdf /, 'output';
    like nup('-T a3 -o out.pdf date'), qr/-T a3 -o out\.pdf /, 'device and output';
};

subtest 'geometry option' => sub {
    like nup('--geometry'), qr/-Mup .*--geometry .*-- ansicolumn$/, 'no file is needed';
    like nup('-T a4 --geometry - -w 300'), qr/-T a4 .*--geometry .*-- ansicolumn - -w 300$/,
        'options for ansicolumn are kept';
    like nup('--geometry date'), qr/-- ansicolumn date$/, 'a command is not run';
    like `$script --geometry 2>&1 </dev/null`, qr/\A\d+ \d+ tty\n\z/, 'size of the terminal';
};

subtest 'page number at the top' => sub {
    like nup('script/nup'), qr{--label S= %n/%N }, 'one file: at the bottom, with the number of all';
    unlike nup('script/nup'), qr/--label NW=/, 'one file: not at the top';
    like nup('script/nup cpanfile'), qr{--label S= %n/%N .*--label NW= %n \@1},
        'two files: at the top as well';
    like nup('-V script/nup'), qr/--label NW= %n @1/, '-V: at the top as well';
    like nup('-V date'), qr/--label NW= %n @1/, '-V with a command';
    unlike nup('date'), qr/--label NW=/, 'a command: not at the top';
    unlike nup('--no-page-number script/nup cpanfile'), qr/--label/,
        '--no-page-number: no label';
};

subtest 'marks of --lateral' => sub {
    my $mark = qr/--mark LEFT=◂  --mark LEFT_END=◃  --mark RIGHT= ▸ --mark RIGHT_END= ▹ -/;
    my $out = nup('-L script/nup');
    like $out, qr{--label S= %L%n/%N%R  --mark}, 'pages in a row: beside the page number';
    like $out, $mark, 'pages in a row: the marks';
    $out = nup('-L script/nup cpanfile');
    like $out, qr/--label NW= %L%n%R \@1 --mark/, 'files side by side: beside the number at the top';
    like $out, $mark, 'files side by side: the marks';
    like nup('-L -V script/nup'), qr/--label NW= %L%n%R \@1 --mark/, '-L -V';
    unlike nup('script/nup'), qr/%[LR]|--mark/, 'no mark without -L';
    unlike nup('script/nup cpanfile'), qr/%[LR]|--mark/, 'no mark without -L, two files';
    unlike nup('-L -F script/nup'), qr/%[LR]|--mark/, 'no mark when -L is turned off';
    like nup('-L --no-page-number script/nup'), qr/--label S= %L%R  --mark/,
        'the marks without the page number';
    like nup('-L --no-page-number script/nup cpanfile'), qr/--label NW= %L%R \@1 --mark/,
        'the marks without the number, files side by side';
};

subtest 'highlight' => sub {
    use File::Temp qw(tempdir);
    my $dir = tempdir(CLEANUP => 1);
    my $find = sub {
        my $name = shift;
        (grep { -x } map { "$_/$name" } split /:/, $ENV{PATH})[0];
    };

    # with the commands in PATH (dummies; -n runs nothing)
    mkdir "$dir/with" or die;
    for my $command (qw(pandoc skylighting source-highlight)) {
        open my $fh, '>', "$dir/with/$command" or die;
        print $fh "#!/bin/sh\n";
        close $fh;
        chmod 0755, "$dir/with/$command" or die;
    }
    {
        local $ENV{PATH} = "$dir/with:$ENV{PATH}";
        like nup_highlight('script/nup'),
            qr/-Mup .*--highlight=pandoc .*-- ansicolumn script\/nup$/,
            'file view asks up.pm for it, pandoc by default';
        like nup_highlight('--highlight script/nup'),
            qr/--highlight=pandoc /, '--highlight without a name';
        like nup_highlight('--highlight=sourcehighlight script/nup'),
            qr/--highlight=sourcehighlight /, '--highlight=sourcehighlight';
        like nup_highlight('script/nup cpanfile -w 100'),
            qr/-Mup .*--highlight=pandoc .*-- ansicolumn script\/nup cpanfile -w 100$/,
            'the arguments of ansicolumn are as they were';
        unlike nup_highlight('--no-highlight script/nup'), qr/highlight/, '--no-highlight';
        like nup_highlight('--no-highlight script/nup'), qr/-- ansicolumn script\/nup$/,
            '--no-highlight leaves the command as it was';
        unlike nup_highlight('--highlight=sourcehighlight --no-highlight script/nup'),
            qr/highlight/, '--no-highlight after --highlight=NAME';
        like nup_highlight('--no-highlight --highlight=sourcehighlight script/nup'),
            qr/--highlight=sourcehighlight /, '--highlight=NAME after --no-highlight';
        {
            local $ENV{NUP_OPTS} = '--highlight=sourcehighlight';
            like nup_highlight('script/nup'), qr/--highlight=sourcehighlight /,
                'NUP_OPTS gives the default';
            unlike nup_highlight('--no-highlight script/nup'), qr/highlight/,
                '--no-highlight wins over NUP_OPTS';
        }
        # a style of the highlighter after a colon
        like nup_highlight('--highlight=pandoc:breezedark script/nup'),
            qr/--highlight=pandoc:breezedark /, '--highlight=NAME:STYLE';
        like nup_highlight('--hi=gnu:esc256 script/nup'),
            qr/--highlight=gnu:esc256 /, '--hi=NAME:STYLE';
        like nup_highlight('--hi=nosuch:style script/nup'),
            qr/nosuch:style: unknown highlighter/, 'unknown highlighter with a style';
        # --hi is the short name
        like nup_highlight('--hi script/nup'), qr/--highlight=pandoc /, '--hi';
        like nup_highlight('--hi=sourcehighlight script/nup'),
            qr/--highlight=sourcehighlight /, '--hi=sourcehighlight';
        like nup_highlight('--no-hi script/nup'),
            qr{-Mup --filename --label S= %n/%N  -- ansicolumn script/nup$}, '--no-hi';
        like nup_highlight('--hi=sourcehighlight --no-hi script/nup'),
            qr{-Mup --filename --label S= %n/%N  -- ansicolumn script/nup$},
            '--no-hi after --hi=NAME';
        # sky and gnu are the short names of the highlighters, given as they are
        like nup_highlight('--hi=sky script/nup'), qr/--highlight=sky /, '--hi=sky';
        like nup_highlight('--hi=gnu script/nup'),
            qr/--highlight=gnu /, '--hi=gnu';
        like nup_highlight('--highlight=gnu script/nup'),
            qr/--highlight=gnu /, '--highlight=gnu';
        like nup_highlight('--hi=skylighting script/nup'),
            qr/--highlight=skylighting /, '--hi=skylighting';
        like nup_highlight('--hi=pandoc script/nup'), qr/--highlight=pandoc /, '--hi=pandoc';
        {
            local $ENV{NUP_OPTS} = '--hi=gnu';
            like nup_highlight('script/nup'), qr/--highlight=gnu /,
                'NUP_OPTS=--hi=gnu';
        }
        like nup_highlight('--highlight=nosuch script/nup'),
            qr/nosuch: unknown highlighter/, 'unknown name';
        unlike nup_highlight('-e echo hello'), qr/highlight/, 'command mode';
        unlike nup_highlight('date'), qr/highlight/, 'command mode without -e';
        unlike nup_highlight('--geometry'), qr/highlight/, '--geometry';
    }

    # without it: only bash and getoptlong.sh, and the system directories
  SKIP: {
        skip 'pandoc is in a system directory', 2
            if grep { -x "$_/pandoc" } qw(/usr/bin /bin);
        my($bash, $getoptlong) = map { $find->($_) } qw(bash getoptlong.sh);
        skip 'bash or getoptlong.sh is not found', 2
            unless $bash and $getoptlong;
        mkdir "$dir/without" or die;
        symlink $bash, "$dir/without/bash" or die;
        symlink $getoptlong, "$dir/without/getoptlong.sh" or die;
        local $ENV{PATH} = "$dir/without:/usr/bin:/bin";
        my $out = nup_highlight('script/nup');
        like $out, qr/-- ansicolumn script\/nup$/, 'as it was without the highlighter';
        unlike $out, qr/highlight/, 'no --highlight';
    }
};

done_testing;
