use Test2::V0 -target => 'Consumer::NonBlock';
use ok $CLASS;

my ($r, $w) = Consumer::NonBlock->pair(batch_size => 5);

$w->write_line("foo $_") for 1 .. 12;

my $w2 = bless({%$w}, $CLASS);

$w->weaken;
$w = undef;
ok($w2->_update->{open}, "Still open");
$w2->close();
ok(!$w2, "Closed w2");
ok(!$r->_update->{open}, "Not open");

my $dir = $r->dir;
opendir(my $dh, $dir) or die "Could not open dir '$dir': $!";
my @files = sort grep { $_ !~ m/\./ } readdir($dh);
is(\@files, [0 .. 2, 'data'], "Got all expected files");

my @lines;
push @lines => $r->read_line for 1 .. 6;

opendir($dh, $dir) or die "Could not open dir '$dir': $!";
@files = sort grep { $_ !~ m/\./ } readdir($dh);
is(\@files, [1 .. 2, 'data'], "Got all expected files, 0 was deleted");

push @lines => $r->read_lines;

opendir($dh, $dir) or die "Could not open dir '$dir': $!";
@files = sort grep { $_ !~ m/\./ } readdir($dh);
is(\@files, ['data'], "Got only data file");

is(
    \@lines,
    [ map { "foo $_" } 1 .. 12 ],
    "Got all lines"
);

closedir($dh);

$r = undef;

ok(!-d $dir, "Directory deleted");

($r, $w) = Consumer::NonBlock->pair(batch_size => 5);
$w->write_raw("foo");
my $check;
local $SIG{ALRM} = sub { die "ALARM" };
alarm 1;
ok(!eval { $check = $r->read_line(); 1 }, "timed out");
like($@, qr/ALARM/, "got alarm");

$w->write_raw('bar');
$w->write_raw("baz\n");

is($r->read_line(), "foobarbaz", "Buffered for complete line");

done_testing;
