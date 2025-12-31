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

my $script = File::Spec->rel2abs('script/nup');

sub nup {
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
};

subtest 'fold option' => sub {
    my $out = nup('-F script/nup');
    like $out, qr/-F/, '-F passed to up.pm';
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

done_testing;
