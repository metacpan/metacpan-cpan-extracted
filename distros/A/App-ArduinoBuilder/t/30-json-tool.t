use strict;
use warnings;
use utf8;

use Test2::V0;
use Test2::IPC;

use App::ArduinoBuilder::JsonTool;
use Log::Any::Simple ':from_argv';

use FindBin;

my $json_tool = "${FindBin::Bin}/data/fake_json_tool.pl";
my $cmd = "${^X} ${json_tool}";

sub new {
  return App::ArduinoBuilder::JsonTool->new($cmd);
}

{
  my $t = new();
  is($t->send("hello\n"), {foo => 'bar', bin => [qw(test1 test2)], baz => {key => 'value'}});
}

{
  my $t = new();
  is($t->send("hello\n"), {foo => 'bar', bin => [qw(test1 test2)], baz => {key => 'value'}});
  is($t->send("other\n"), {text => 'more text'});
  is($t->send("other\n"), {text => 'more text'});
  is($t->send("hello\n"), {foo => 'bar', bin => [qw(test1 test2)], baz => {key => 'value'}});
}

{
  my $t = new();
  is($t->send("hello\n"), {foo => 'bar', bin => [qw(test1 test2)], baz => {key => 'value'}});
  is($t->send("other\n"), {text => 'more text'});
  is($t->send("quit\n"), {cmd => 'bye!'});
}

done_testing;
