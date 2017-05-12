use strict;
use warnings;
use Test::Clustericious::Config;
use Test::Clustericious::Log;
use Test::More tests => 5;
use Path::Class;

my $nested_file = file(home_directory_ok, qw( foo bar baz here.txt ));
$nested_file->parent->mkpath(0,0700);
$nested_file->spew('hi there');

create_config_ok Foo => <<EOF;
---
test_dir: <%= dir home, qw( foo bar baz ) %>
test_file: <%= file home, qw( foo bar baz here.txt ) %>
conf_file: <%= __FILE__ %>
conf_line: <%= __LINE__ %>
EOF

my $config = Clustericious::Config->new('Foo');
isa_ok $config, 'Clustericious::Config';

my $dir = $config->test_dir;
ok $dir && -d $dir, "dir = $dir";

my $file = $config->test_file;
ok $file && -f $file, "file = $file";

note "conf_file: " . $config->conf_file;
note "conf_line: " . $config->conf_line;
