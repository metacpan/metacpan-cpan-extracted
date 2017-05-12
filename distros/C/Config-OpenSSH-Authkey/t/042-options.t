#!perl
#
# Tests for Config::OpenSSH::Authkey::Entry::Options

use strict;
use warnings;

use Test::More tests => 17;

BEGIN { use_ok('Config::OpenSSH::Authkey::Entry::Options') }
ok( defined $Config::OpenSSH::Authkey::Entry::Options::VERSION,
  '$VERSION defined' );

can_ok(
  'Config::OpenSSH::Authkey::Entry::Options',
  qw/new parse as_string
    get_option get_options set_option
    unset_option unset_options/
);

# Class method tests
{
  my $op = Config::OpenSSH::Authkey::Entry::Options->new();
  isa_ok( $op, 'Config::OpenSSH::Authkey::Entry::Options' );

  my $options_ref =
    Config::OpenSSH::Authkey::Entry::Options->split_options('b,s="v"');
  is_deeply(
    $options_ref,
    [ { name => 'b' }, { name => 's', value => 'v' } ],
    'test split_options'
  );

  my @result =
    Config::OpenSSH::Authkey::Entry::Options->split_options('a,s="v",q');
  is_deeply(
    \@result,
    [ { name => 'a' }, { name => 's', value => 'v' }, { name => 'q' } ],
    'test split_options'
  );
}

# Instance method tests
{

  my $op = Config::OpenSSH::Authkey::Entry::Options->new('no-pty,no-user-rc');
  my @options = $op->get_options;
  is( "@options", 'no-pty no-user-rc', 'options in, options out' );
  is( $op->get_options, 2, 'options out in scalar context' );

  is( $op->get_option('no-pty'),    'no-pty', 'get an option' );
  is( $op->get_option('nosuchopt'), '',       'get unset option' );

  $op->set_option( 'from', '127.0.0.1' );
  is( $op->get_option('from'), '127.0.0.1', 'get an option with value' );

  $op->unset_option('no-pty');
  @options = $op->get_options;
  is( "@options", 'no-user-rc from', 'options in, options out' );

  is( $op->as_string, 'no-user-rc,from="127.0.0.1"', 'check as_string' );

  is( $op->parse('a,b'), 2, 'check parse method' );
  $op->unset_options();
  is( $op->get_options, 0, 'options count after clear' );

  my $embed_quotes = 'command="echo \"test\"",from="127.0.0.1",no-pty';
  $op->parse($embed_quotes);
  is( $op->as_string, $embed_quotes, 'check whether \" handled properly' );
  diag $op->as_string;

  $op->unset_options();
  $op->set_option( 'command', 'echo "test"' );
  is(
    $op->as_string,
    'command="echo \"test\""',
    'check whether \" handled properly'
  );
}

