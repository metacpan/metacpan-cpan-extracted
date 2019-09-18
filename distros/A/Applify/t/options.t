use warnings;
use strict;
use Test::More;

my $app    = eval 'use Applify; app {0};' or die $@;
my $script = $app->_script;

isa_ok $script->option_parser, 'Getopt::Long::Parser';

eval { $script->option(undef) };
like($@, qr{^Usage:.*type =>}, 'option() require type');
eval { $script->option(str => undef) };
like($@, qr{^Usage:.*name =>}, 'option() require name');
eval { $script->option(str => foo => undef) };
like($@, qr{^Usage:.*documentation}, 'option() require documentation');

$script->option(str => foo_bar => 'Foo can something');
is_deeply(
  $script->options,
  [{arg => 'foo-bar', documentation => 'Foo can something', name => 'foo_bar', type => 'str',}],
  'add foo as option'
);

$script->option(str => foo_2 => 'foo_2 can something else', 42);
is $script->options->[1]{default}, 42, 'foo_2 has default value';

$script->option(str => foo_3 => 'foo_3 can also something', 123, required => 1);
is $script->options->[2]{default},  123, 'foo_3 has default value';
is $script->options->[2]{required}, 1,   'foo_3 is required';

$script->option(str => foo_4 => 'foo_4 can something else' => sub { });
is ref($script->options->[3]{default}), 'CODE', 'foo_4 has default code';

$script->option(str => foo_5 => 'foo_5 can something else', default => sub { });
is ref($script->options->[4]{default}), 'CODE', 'foo_5 has default code';

is $script->_calculate_option_spec({name => 'a_b', arg => 'a-b', type => 'bool'}), 'a_b|a-b!',  'a_b!';
is $script->_calculate_option_spec({name => 'a_b', arg => 'a-b', type => 'flag'}), 'a_b|a-b!',  'a_b!';
is $script->_calculate_option_spec({name => 'a_b', arg => 'a-b', type => 'inc'}),  'a_b|a-b+',  'a_b+';
is $script->_calculate_option_spec({name => 'a_b', arg => 'a-b', type => 'str'}),  'a_b|a-b=s', 'a_b=s';
is $script->_calculate_option_spec({name => 'a_b', arg => 'a-b', type => 'int'}),  'a_b|a-b=i', 'a_b=i';
is $script->_calculate_option_spec({name => 'a_b', arg => 'a-b', type => 'num'}),  'a_b|a-b=f', 'a_b=f';
is $script->_calculate_option_spec({name => 'a_b', arg => 'a-b', type => 'num', n_of => '@'}), 'a_b|a-b=f@', 'a_b=f@';
is $script->_calculate_option_spec({name => 'a_b', arg => 'a-b', type => 'num', n_of => '0,3'}), 'a_b|a-b=f{0,3}',
  'a_b=f{0,3}';

{
  local $TODO = 'Add proper support for file/dir';
  is $script->_calculate_option_spec({name => 'a_b', arg => 'a-b', type => 'file'}), 'a_b|a-b=s', 'a_b=s';
  is $script->_calculate_option_spec({name => 'a_b', arg => 'a-b', type => 'dir'}),  'a_b|a-b=s', 'a_b=s';
}

eval { $script->_calculate_option_spec({name => 'a_b', type => 'uri'}); };
like $@, qr/^Usage: option /, 'die on unsupported option type';


$app = eval <<"HERE" or die $@;
use Applify;
option str => iii => 'd1';
option str => input_file => 'd2';
option str => output_file => d3 => default => 'file.out';
option str => template => template => default => 'empty';
sub has_template {
  return 0;
}
app { };
HERE

$script = $app->_script;

my $instance = app_instance($script, qw{-input-file /tmp/test});
is $instance->has_input_file, 1, 'Moose style';
is !$instance->has_iii, 1, 'does not exist';
ok !$instance->has_output_file, 'default does not exist yet';
$instance->output_file;
ok $instance->has_output_file, 'default applied';
is $instance->has_template,    0, 'has_template not replaced see _sub()';
is $instance->template,        'empty', 'default exists';

sub app_instance {
  my $script = shift;
  local @ARGV = @_;
  my $app = $script->app;
  return $app;
}

done_testing;
