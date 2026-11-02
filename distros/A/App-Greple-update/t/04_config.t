use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use Data::Dumper;

use lib '.';
use t::Util;

# Parameters can be set by -Mupdate::config(...), and the options keep
# working.

my $dir = tempdir(CLEANUP => 1);

sub target {
    my $file = "$dir/target.txt";
    unlink glob "$file*";
    open my $fh, '>', $file or die;
    print $fh "the fox\nsecond line\n";
    close $fh;
    $file;
}

sub config { greple("-Mupdate::config($_[0])", @_[1..$#_]) }

my $file = target();
config('with_backup', qw(fox --cm sub{uc} --update), $file)->run;
ok(-f "$file.bak", 'config(with_backup): backup with the default suffix');
like(slurp($file), qr/FOX/, 'config(with_backup): the file is updated');
like(slurp("$file.bak"), qr/fox/, 'config(with_backup): the backup has the original');

$file = target();
config('with_backup=.orig', qw(fox --cm sub{uc} --update), $file)->run;
ok(-f "$file.orig", 'config(with_backup=.orig): given suffix');
ok(!-f "$file.bak", 'config(with_backup=.orig): no default suffix');

$file = target();
my $out = config('diff_context=0', qw(fox --cm sub{uc} --diff), $file)->run->{stdout};
like($out, qr/^\@\@ -1 \+1 \@\@/m, 'config(diff_context=0): context length of diff');

for my $opts ([qw(--diff-context=0)], [qw(-U0)], [qw(-U 0)]) {
    $file = target();
    my $out = update(qw(fox --cm sub{uc} --diff), @$opts, $file)->run->{stdout};
    like($out, qr/^\@\@ -1 \+1 \@\@/m, "@$opts: context length of diff");
}

for my $opts ([q(--diff-command=diff -c)]) {
    $file = target();
    my $out = update(qw(fox --cm sub{uc} --diff), @$opts, $file)->run->{stdout};
    like($out, qr/^\*{15}$/m, "@$opts: diff command");
}

$file = target();
update(qw(fox --cm sub{uc} --update --with-backup=.opt), $file)->run;
ok(-f "$file.opt", '--with-backup=.opt still works');

$file = target();
update('fox', qw(--cm sub{uc} --update --), $file)->run;
like(slurp($file), qr/FOX/, 'a -- before the file is left to greple');

done_testing;
