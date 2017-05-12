use strict;
use Test::More;
use File::Temp qw/tempfile/;
use FindBin qw($Bin);
use File::stat;
use Path::Tiny;

my $sanction_file;

BEGIN {
    (my $fh, $sanction_file) = tempfile();
    print $fh "ABCD\n";
    close($fh);
    $ENV{SANCTION_FILE} = $sanction_file;
}
use Data::Validate::Sanctions qw/is_sanctioned get_sanction_file/;

is(get_sanction_file(), $sanction_file, "sanction file is correct");

ok(is_sanctioned('ABCD'),  "correct file content");
ok(!is_sanctioned('AAAA'), "correct file content");

#sleep 1 to make the mtime greater than old mtime
my $last_mtime = stat($sanction_file)->mtime;
sleep 1;
my $script = "$Bin/../bin/update_sanctions_csv";
my $lib    = "$Bin/../lib";
is(system($^X, "-I$lib", $script, $sanction_file), 0, "download file successfully");
ok($last_mtime < stat($sanction_file)->mtime, "mtime updated");

ok(!is_sanctioned('ABCD'), "correct file content");
my ($head) = path($sanction_file)->lines({
    count => 1,
    chomp => 1
});
$last_mtime = stat($sanction_file)->mtime;
ok(is_sanctioned($head), "correct file content");
path($sanction_file)->spew(qw(ABCD));
ok(utime($last_mtime, $last_mtime, $sanction_file), 'change mtime to pretend the file not changed');
ok(is_sanctioned($head), "the module still use old data because it think the fire is not changed");
done_testing;
