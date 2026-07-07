use v5.14;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use JSON::PP;

use App::Greple::xlate;
use App::Greple::xlate::llm::gpt5;

$App::Greple::xlate::show_progress = 0;

my $bin = File::Spec->rel2abs('t/bin');
my $tmpdir = tempdir(CLEANUP => 1);
my $log = "$tmpdir/gpt5.log";
$ENV{PATH} = "$bin:$ENV{PATH}";
$ENV{LLM_STUB_LOG} = $log;

$App::Greple::xlate::llm::gpt5::lang_to = 'EN-US';

my @to = App::Greple::xlate::llm::gpt5::xlate("hello world\n");
is_deeply(\@to, ["HELLO WORLD\n"], 'translation via stub');

open my $fh, '<', $log or die "$log: $!";
my $rec = JSON::PP->new->decode(scalar <$fh>);
my @argv = @{$rec->{argv}};
my $argv_str = join ' ', @argv;

is($argv[0], '-m', 'first option is -m');
is($argv[1], 'gpt-5.5', 'model is gpt-5.5');
like($argv_str, qr/-o reasoning_effort none/, 'reasoning_effort none');
like($argv_str, qr/-o verbosity low/, 'verbosity low');
like($argv_str, qr/--no-stream/, 'no-stream');
like($argv_str, qr/--no-log/, 'no-log');
unlike($argv_str, qr/temperature/, 'temperature is not sent');
unlike($argv_str, qr/max_tokens/, 'max_tokens is not sent (llm 0.31 Chat API rejects it)');

my($i) = grep { $argv[$_] eq '-s' } 0 .. $#argv;
my $system = $argv[$i + 1];
like($system, qr/\ATranslate the following JSON array into American English\./,
     'system prompt with language expanded');
like($system, qr/XML-style marker tag/, 'mask tag instruction preserved');
like($system, qr/conventions for that kind of element/,
     'element-type convention instruction present');
like($system, qr/<person id=2 \/>/, 'category tag example present');

is_deeply(JSON::PP->new->decode($rec->{stdin}), ["hello world\n"],
          'stdin is JSON array of lines');

done_testing;
