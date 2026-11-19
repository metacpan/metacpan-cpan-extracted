use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use FindBin;
require "$FindBin::Bin/../pvim";
my $dir = tempdir(CLEANUP => 1);
sub invoke {
    my ($input, @args) = @_;
    # Use real standard descriptors for inheritance on native Windows too.
    # IPC::Open3's pipe EOF behavior differs there; actual pipes are additionally
    # tested with an independent Perl pipe harness and POSIX controlling-terminal PTYs.
    open my $data, '+>', "$dir/stdin" or die $!; binmode $data;
    print {$data} $input; seek($data, 0, 0) or die $!;
    open my $output, '+>', "$dir/stdout" or die $!;
    open my $errors, '+>', "$dir/stderr" or die $!;
    my ($saved_in, $saved_out, $saved_err);
    open $saved_in, '<&', \*STDIN or die $!;
    open $saved_out, '>&', \*STDOUT or die $!;
    open $saved_err, '>&', \*STDERR or die $!;
    open STDIN, '<&', $data or die $!;
    open STDOUT, '>&', $output or die $!;
    open STDERR, '>&', $errors or die $!;
    my $status = system($^X, "$FindBin::Bin/../pvim", @args);
    open STDIN, '<&', $saved_in or die $!;
    open STDOUT, '>&', $saved_out or die $!;
    open STDERR, '>&', $saved_err or die $!;
    seek($output, 0, 0) or die $!; seek($errors, 0, 0) or die $!;
    local $/; my $stdout = <$output>; my $stderr = <$errors>;
    return ($status, $stdout, $stderr);
}
my $file = "$dir/import.txt";
for my $text ("hi\n", "one\r\ntwo\nlast", '', ":q!\n\x1b:w danger\n", "a\0b\n") {
    my ($status) = invoke($text, '--batch', '-c', "w! $file", '-');
    is($status, 0, 'explicit stdin batch import succeeds');
    open my $fh, '<', $file or die $!; binmode $fh; local $/;
    is(<$fh>, $text, 'stdin bytes and endings preserved, including empty input');
    close $fh;
}
my ($status, $out, $err) = invoke("old\n", '--batch', '-c', 's/old/new/', '-c', "w! $file", '-');
is($status, 0, 'batch commands operate on imported data');
open my $fh, '<', $file or die $!;
is(<$fh>, "new\n", 'batch import edited'); close $fh;
($status, $out, $err) = invoke("hi\n", '--batch', '-c', 'q', '-');
ok($status, 'import has unsaved quit guard'); like($err, qr/Unsaved/i, 'guard explained');
($status) = invoke('', '--batch', '-c', 'q', '-');
ok($status, 'empty import also has unsaved quit guard');
($status) = invoke("hi\n", '--batch', '-c', 'q!', '-');
is($status, 0, 'explicit discard works');
($status) = invoke("ignored\n", '--batch', '-c', 'q');
is($status, 0, 'batch does not auto-import stdin');
($status, $out, $err) = invoke("hi\n");
ok($status, 'redirected stdout refused for automatic interactive import');
like($err, qr/terminal/i, 'no-terminal diagnostic');
unlike($out, qr/\e\[/, 'no screen escapes in redirected stdout');
# Exercise the shared streaming indexer over many read boundaries without a slurp.
open $fh, '+>', "$dir/large" or die $!; binmode $fh;
my $block = ('x' x 65535) . "\r\n";
print {$fh} $block for 1..128;
print {$fh} 'tail'; seek($fh, 0, 0) or die $!;
my $store = PVim::Store->load(undef, $fh);
is($store->{count}, 129, 'stream input indexed across block boundaries');
is($store->line(0), 'x' x 65535, 'CR at chunk boundary handled');
is($store->term(0), 2, 'split CRLF retained');
is($store->line(128), 'tail', 'unterminated tail retained');
ok($store->dirty, 'stream is modified');
ok(!defined($store->{path}), 'stream stays unnamed');
ok(defined(fileno($fh)), 'borrowed input handle remains open');
close $fh;
done_testing;
