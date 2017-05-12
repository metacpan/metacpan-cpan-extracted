use strict;
use warnings;

use Test::More tests => 3;

{
    package MyTest::Process;
    use base qw/CouchDB::ExternalProcess/;

    sub foo :Action {
        return {
            json => {
                foo => "bar"
            }
        };
    }

    # Getter/setter for file handle destroy will log to
    sub destroyLoggerFh {
        my ($self, $loggerFh) = @_;
        $self->{destroyLoggerFh} = $loggerFh if $loggerFh;
        return ($self->{destroyLoggerFh} || *STDERR);
    }

    sub _destroy {
        my $self = shift;
        my $fh = $self->destroyLoggerFh();
        print $fh "Destroy called!$/";
    }

    1;
}

my $testProcess = MyTest::Process->new;

isa_ok($testProcess,'MyTest::Process');

my $goodRequestJson = '{"path":["database","process","foo"]}';

pipe(PROC_READ, PROC_WRITE);
pipe(TEST_READ, TEST_WRITE);
pipe(DESTROY_READ, DESTROY_WRITE);

$testProcess->destroyLoggerFh(*DESTROY_WRITE);

my $pid = fork();

$| = 1;
if($pid) {
    # Only for the child to write to us (the parent)
    close(TEST_WRITE);
    close(DESTROY_WRITE);

    # Write some data to the child
    print PROC_WRITE $goodRequestJson.$/;

    # And close the stream
    close(PROC_WRITE);

    # Wait for the child to exit
    wait();
} else {
    # Only for the parent to write to us (the child)
    close(PROC_WRITE);

    # Run until our input stream is closed (by the parent)
    $testProcess->run(in_fh => *PROC_READ, out_fh => *TEST_WRITE);

    # Don't keep running the parent's code as the child!
    exit();
}

my $processOutputJson;
my $destroyOutput;
my $ret = read(TEST_READ, $processOutputJson, 100);
$ret = read(DESTROY_READ, $destroyOutput, 100);

is($destroyOutput, "Destroy called!$/", "_destroy output");

my $processOutput = $testProcess->jsonParser->jsonToObj($processOutputJson);
is($processOutput->{json}->{foo}, "bar","Good Response Data");
