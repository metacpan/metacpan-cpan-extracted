use v5.14;
use warnings;
use utf8;
use open qw(:std :encoding(utf-8));
use Test::More;
use File::Temp qw(tempfile tempdir);

use lib '.';
use t::Util;

# --begin of the md module: a function called on the whole text before
# the module does anything to it

my($fh, $md) = tempfile(SUFFIX => '.md', UNLINK => 1);
binmode $fh, ':encoding(utf-8)';
print $fh <<'END';
one two

| a | b |
|---|---|
| X | y |
| z | w |
END
close $fh;

sub plain { $_[0] =~ s/\e\[[0-9;]*[mK]//gr }
sub md_run {
    my $opt = shift;
    plain(run("'-Mmd::config(colorize=0)' $opt -- --filter $md")->stdout);
}

my $base = md_run('');
like($base, qr/^ X │ y $/m, 'without --begin');

# before the table is formatted: the column follows the new width
my $out = md_run(q(--begin 'sub{ s/X/XXXX/ }'));
like($out, qr/^ XXXX │ y $/m, 'sub{...} runs before the table is formatted');
like($out, qr/^ z    │ w $/m, 'and the other rows are aligned to it');

# in the order given
$out = md_run(q(--begin 'sub{ s/X/A/ }' --begin 'sub{ s/A/B/ }'));
like($out, qr/^ B │ y $/m, 'more than one, in the order given');

# before refill too: refill sees the text after the function
$out = plain(run("'-Mmd::config(colorize=0,refill=1)' --begin 'sub{ s/two/two\\nthree/ }' -- --filter $md")->stdout);
like($out, qr/^one two three$/m, 'before refill');

# a function of a module, with parameters
my $dir = tempdir(CLEANUP => 1);
mkdir "$dir/App";
mkdir "$dir/App/Greple";
open $fh, '>', "$dir/App/Greple/mdbegintest.pm" or die;
print $fh <<'END';
package App::Greple::mdbegintest;
sub f { my %a = @_; s/X/$a{to}/; }
1;
END
close $fh;
{
    local $ENV{PERL5LIB} = "$dir:" . ($ENV{PERL5LIB} // '');
    $out = plain(run("-Mmdbegintest '-Mmd::config(colorize=0)' --begin '&App::Greple::mdbegintest::f(to=Q)' -- --filter $md")->stdout);
    like($out, qr/^ Q │ y $/m, '&function with a parameter');
}

# the package of a function is loaded when it is not defined
{
    local $ENV{PERL5LIB} = "$dir:" . ($ENV{PERL5LIB} // q());
    $out = plain(run("'-Mmd::config(colorize=0)' --begin '&App::Greple::mdbegintest::f(to=Q)' -- --filter $md")->stdout);
    like($out, qr/^ Q │ y $/m, q(the package is loaded without -M));

    # a name without a package: in main first, and then the module named
    # after the function
    mkdir "$dir/App/Greple/md";
    open my $short, q(>), "$dir/App/Greple/md/mdtestshort.pm" or die;
    print $short "package App::Greple::md::mdtestshort;\nsub mdtestshort { my %a = \@_; s/X/\$a{to}/; }\n1;\n";
    close $short;
    $out = plain(run("'-Mmd::config(colorize=0)' --begin '&mdtestshort(to=S)' -- --filter $md")->stdout);
    like($out, qr/^ S │ y $/m, q(a short name finds the module named after it));
    open $short, q(>), "$dir/App/Greple/mdbeginmain.pm" or die;
    print $short "package App::Greple::mdbeginmain;\nsub main::mdtestshort { s/X/M/ }\n1;\n";
    close $short;
    $out = plain(run("-Mmdbeginmain '-Mmd::config(colorize=0)' --begin '&mdtestshort' -- --filter $md")->stdout);
    like($out, qr/^ M │ y $/m, q(main comes first));
    open $short, q(>), "$dir/App/Greple/md/mdtestbroken.pm" or die;
    print $short "package App::Greple::md::mdtestbroken;\nsub mdtestbroken { \n";
    close $short;
    isnt(run("'-Mmd::config(colorize=0)' --begin '&mdtestbroken' -- --filter $md")->status, 0, q(a short name with a broken module is an error));

    # a function or a file that does not exist: a warning, and the text is
    # shown without it
    for my $func (qw(&nosuch &main::nosuch &App::Greple::mdbegintest::nosuch &No::Such::Package::f &No::Such::Package::f(a=1))) {
        (my $name = $func) =~ s/^&|\(.*//g;
        my $r = run("'-Mmd::config(colorize=0)' --begin '$func' -- --filter $md");
        is($r->status, 0, "$func: normal exit");
        my $o = plain($r->stdout);
        like($o, qr/--begin: \Q$name\E: function not found/, "$func: a warning");
        like($o, qr/^ X │ y $/m, "$func: the text is still formatted");
    }

    # the other functions still run, and the warning is given only once
    my $o = plain(run("'-Mmd::config(colorize=0)' --begin '&nosuch' --begin 'sub{ s/X/Z/ }' -- --filter $md $md")->stdout);
    is(() = $o =~ /^ Z │ y $/mg, 2, q(the next function runs on each file));
    is(() = $o =~ /function not found/g, 1, q(the warning is given once));

    # a module that exists and does not compile is an error
    open my $bad, q(>), "$dir/App/Greple/mdbeginbad.pm" or die;
    print $bad "package App::Greple::mdbeginbad;\nsub f { \n";
    close $bad;
    my $r = run("'-Mmd::config(colorize=0)' --begin '&App::Greple::mdbeginbad::f' -- --filter $md");
    isnt($r->status, 0, q(a module with a syntax error is an error));
    like($r->stdout, qr/Missing right curly/, q(and says why));

    # a module that needs another one, which does not exist, too
    open $bad, q(>), "$dir/App/Greple/mdbeginneed.pm" or die;
    print $bad "package App::Greple::mdbeginneed;\nuse No::Such::Dependency;\nsub f { }\n1;\n";
    close $bad;
    $r = run("'-Mmd::config(colorize=0)' --begin '&App::Greple::mdbeginneed::f' -- --filter $md");
    isnt($r->status, 0, q(a missing dependency of a module is an error));
}

# an error in the function is reported
my $err = run("'-Mmd::config(colorize=0)' --begin 'sub{ ' -- --filter $md");
like(join('', map { $err->{$_} // '' } qw(stdout stderr)), qr/Error in function|Missing right curly|syntax/i, 'a syntax error is reported');

# for each file
$out = plain(run("'-Mmd::config(colorize=0)' --begin 'sub{ s/one/ONE/ }' -- --filter $md $md")->stdout);
is(() = $out =~ /^ONE two$/mg, 2, 'for each file');

done_testing;
