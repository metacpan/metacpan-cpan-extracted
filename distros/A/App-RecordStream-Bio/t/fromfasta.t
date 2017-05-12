use strict;
use warnings;
use Test::More 'no_plan';

use App::RecordStream::Test::Tester;
use App::RecordStream::Test::OperationHelper;
use File::Temp ();
use JSON ();

use App::RecordStream::Operation::fromfasta;

my $input;
my $output;

my $tester = App::RecordStream::Test::Tester->new('fromfasta');

diag "basic input";
$input = <<'INPUT';
>foo baz bar
TCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGG
GGAAACTACGTGTGTTATCTCCCAACGATGACATAATATATTACT
TCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGG
GGAAACTACGTGTGTTATCTCCCAACGATGACATAATATATTACT
> baz 
SLYNTVAVLYYVHQR
>empty
>bogus
TCATTATATAATACAGTAGC>>CCCTCTATTGTGTGCATCAAAGG
>empty2
INPUT
$output = <<'OUTPUT';
{"id":"foo","description":"baz bar","name":"foo baz bar","sequence":"TCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGG\nGGAAACTACGTGTGTTATCTCCCAACGATGACATAATATATTACT\nTCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGG\nGGAAACTACGTGTGTTATCTCCCAACGATGACATAATATATTACT"}
{"id":"baz","description":null,"name":"baz", "sequence":"SLYNTVAVLYYVHQR"}
{"id":"empty","description":null,"name":"empty","sequence":null}
{"id":"bogus","description":null,"name":"bogus","sequence":"TCATTATATAATACAGTAGC>>CCCTCTATTGTGTGCATCAAAGG"}
{"id":"empty2","description":null,"name":"empty2","sequence":null}
OUTPUT
$tester->test_input([], $input, $output);

diag "--oneline";
$output = <<'OUTPUT';
{"id":"foo","description":"baz bar","name":"foo baz bar","sequence":"TCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGGGGAAACTACGTGTGTTATCTCCCAACGATGACATAATATATTACTTCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGGGGAAACTACGTGTGTTATCTCCCAACGATGACATAATATATTACT"}
{"id":"baz","description":null,"name":"baz", "sequence":"SLYNTVAVLYYVHQR"}
{"id":"empty","description":null,"name":"empty","sequence":null}
{"id":"bogus","description":null,"name":"bogus","sequence":"TCATTATATAATACAGTAGC>>CCCTCTATTGTGTGCATCAAAGG"}
{"id":"empty2","description":null,"name":"empty2","sequence":null}
OUTPUT
$tester->test_input(['--oneline'], $input, $output);

diag "Test multiple input files with --filename-key";
$output = "";
my $output_template = <<'OUTPUT';
{"id":"foo","description":"baz bar","file":__TMPFILE__,"name":"foo baz bar","sequence":"TCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGG\nGGAAACTACGTGTGTTATCTCCCAACGATGACATAATATATTACT\nTCATTATATAATACAGTAGCAACCCTCTATTGTGTGCATCAAAGG\nGGAAACTACGTGTGTTATCTCCCAACGATGACATAATATATTACT"}
{"id":"baz","description":null,"file":__TMPFILE__,"name":"baz", "sequence":"SLYNTVAVLYYVHQR"}
{"id":"empty","description":null,"file":__TMPFILE__,"name":"empty","sequence":null}
{"id":"bogus","description":null,"file":__TMPFILE__,"name":"bogus","sequence":"TCATTATATAATACAGTAGC>>CCCTCTATTGTGTGCATCAAAGG"}
{"id":"empty2","description":null,"file":__TMPFILE__,"name":"empty2","sequence":null}
OUTPUT

my $JSON = JSON->new->utf8->allow_nonref;

my @files;
for (1..3) {
    my $fh = File::Temp->new;
    push @files, $fh;

    print { $fh } $input;
    $fh->flush;
    ok -s $fh->filename, "Temporary input file has data";

    $output .= $output_template;
    $output =~ s/__TMPFILE__/$JSON->encode($fh->filename)/ge;
}

App::RecordStream::Test::OperationHelper->do_match(
    'fromfasta' => ['--filename-key', 'file', map { $_->filename } @files],
    '',
    $output,
);
undef @files;
