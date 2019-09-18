use warnings;
use strict;
use Test::More;

my $app = eval <<'HERE' or die $@;
use Applify;

my $i = 0;

hook before_options_parsing => sub {
  $ENV{TEST_OPTIONS} = join ':', @{$_[1]};
  shift->option_parser->configure(qw(bundling no_pass_through)) if $i++;
};

hook before_exit => sub { die "before_exit:$_[1]" };

app {$ENV{TEST_EXIT_CODE}};
HERE

$ENV{TEST_EXIT_CODE} = 42;
my $script = $app->_script;

ok_option_parser_config([qw(no_auto_help no_auto_version pass_through)], 'original option_parser config');

eval {
  local @ARGV = qw(a b c);
  $script->app;
  ok 0, 'should never come to this';
} or do {
  like $@, qr{^before_exit:42}, 'before_exit';
  is $ENV{TEST_OPTIONS}, 'a:b:c', 'before_options_parsing argv';
  ok_option_parser_config([qw(no_auto_help no_auto_version bundling no_pass_through)], 'modified option_parser config');
};

done_testing;

sub ok_option_parser_config {
  my ($expected, $desc) = @_;
  my $save = Getopt::Long::Configure(@$expected);
  is_deeply($script->option_parser->{settings}, Getopt::Long::Configure($save), $desc);
}
