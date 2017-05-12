#!perl
#
# Tests for Config::OpenSSH::Authkey::Entry.

use strict;
use warnings;

use Test::More tests => 90;

BEGIN { use_ok('Config::OpenSSH::Authkey::Entry') }
ok( defined $Config::OpenSSH::Authkey::Entry::VERSION, '$VERSION defined' );

my $options_ref = Config::OpenSSH::Authkey::Entry->split_options('b,s="v"');
is_deeply(
  $options_ref,
  [ { name => 'b' }, { name => 's', value => 'v' } ],
  'test split_options'
);

can_ok(
  'Config::OpenSSH::Authkey::Entry',
  qw{new parse key protocol keytype as_string duplicate_of unset_duplicate
    comment unset_comment
    options unset_options get_option set_option unset_option}
);

# tests that should fail
eval { my $foo = Config::OpenSSH::Authkey::Entry->new('# this should fail'); };
like( $@, qr/no public key data/, 'pass a comment' );

eval { my $foo = Config::OpenSSH::Authkey::Entry->new( 'a' x10_000 ); };
like( $@, qr/exceeds size limit/, 'input too large' );

my %test_keys = (
  ssh_rsa1_key => {
    key =>
      '2048 35 23630799405370890416560346190537777785339716260610817007644701482767637183635788616731779505074624040404827730720266982065698778424027842034826555001721628064939174824766308386967707155164362363991698487348781354189797242968016655394176912989543069715362632220409720250786009962138979546047682544784860114598850781879398089994304229934591147159198321743231107534608044912053911505580573361893000830368443236767720370606205145581490011425551562167740691933279863658401131812902705134767386343614437365129779679548793545187003730664381417798591992680489156542035937349672614849148711907215522304878355526605508062096379',
    protocol => 1,
    keytype  => 'rsa1',
  },
  ssh_rsa_key => {
    key =>
      'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEAuNNRYuFbHH3QmQSe5v/hLEisqjboSk+XOQD1RjrxXadc8P9aaOp4TNxSK3nxBio3SoLZcAbxorTnEbjSSrMydFUMMeWGP2JBpr33etKSYRgH2002YmIk1K4E3l9QoXQmTwQHF5kka5ge1mMJCeC8Se7Q67IGg9NeMGSML+KiR1U=',
    protocol => 2,
    keytype  => 'rsa',
  },
  ssh_dsa_key => {
    key =>
      'ssh-dss AAAAB3NzaC1kc3MAAACBANBTUdn8uBorJ9lVoQU7aaXmj7muzTykuSqnQA0qZC8h/GIyeP44EJFHcg40rg8+lSgh8zCnA5uUHu2wSgDcpKWL6oSqJX6Rrm0BKFQssT8UHwTGjjorYPYapU5edNQ7lIWJwXRYf898ZjcMUdLtG7wTAh1P6/gdayIiN0jae99tAAAAFQD4BfmIA0W1gwqR5AZ28KrDuoKthwAAAIEAxkW3+mod/KfOswY0IQGU6YLovC5iX+vJXSWdGzXauU/phkHiv9UNgc+OpAWX5PkTntqhQP4yrpZS9yViVGF3qsvMNQjqv32iKIcMmYDaP2rnPxoIOCfE7Joa1cvMusQFym2mNc5MvdQOVw+O+6zoAwIcKvbpYQZYqrjTHRoTULgAAACBAIFwzKPBsN/Z4VMVUb98pam9uE1xgFVfgi8sq/Ym5RXfbi5eZy4CDM/yNpbpWqdn+AG0vpH4Ea1XPrnHQexamIPuGCtyvoyCf88+s8ir1WLCODChzxt20e8/VcWxxkEn63bBl/zFLd/FArGnd161jfN8Ouz/6KFZfi4OqlfmcYce',
    protocol => 2,
    keytype  => 'dsa',
  },
);

# Test all key types, without comment or options
for my $key_type ( keys %test_keys ) {
  eval {
    my $ak_entry =
      Config::OpenSSH::Authkey::Entry->new( $test_keys{$key_type}->{key} );

    isa_ok( $ak_entry, 'Config::OpenSSH::Authkey::Entry' );

    is(
      $ak_entry->protocol,
      $test_keys{$key_type}->{protocol},
      "protocol correct for $key_type"
    );
    is(
      $ak_entry->keytype,
      $test_keys{$key_type}->{keytype},
      "keytype correct for $key_type"
    );
    is(
      $ak_entry->key,
      $test_keys{$key_type}->{key},
      "$key_type key unchanged after parsing"
    );
    # no comments or options, so as_string output must match the
    # key itself
    is(
      $ak_entry->as_string,
      $test_keys{$key_type}->{key},
      "$key_type string unchanged after parsing"
    );

    is( $ak_entry->comment, '', "comment not set for $key_type" );
    is( $ak_entry->options, '', "options not set for $key_type" );

    my $comment = 'user@host.local';
    my $options = 'command="hostname"';

    is( $ak_entry->comment($comment), $comment, "set comment for $key_type" );
    is( $ak_entry->options($options), $options, "set options for $key_type" );

    is(
      $ak_entry->as_string,
      join( q{ }, $options, $test_keys{$key_type}->{key}, $comment ),
      "$key_type with comment and options set"
    );

    # Undo the comment, options, confirm no wacky sideeffects...
    $ak_entry->unset_comment;
    is( $ak_entry->comment, '', 'comment unset properly' );

    $ak_entry->unset_options;
    is( $ak_entry->options, '', 'options unset properly' );

    is(
      $ak_entry->as_string,
      $test_keys{$key_type}->{key},
      "$key_type string unchanged after unset options, comment"
    );
  };
  if ($@) {
    chomp $@;
    diag("Unexpected error for $key_type: $@");
  }
}

# Test all key types with options or comment or both set in the input
for my $key_type ( keys %test_keys ) {
  eval {
    my ( $ak_entry, $ak_string );

    my $comment = 'some comment';
    # Tricky (yet valid) options with whitespace and quoted "
    my $options = 'environment="FOO=\"bar\"",command="who am i",no-pty';

    $ak_string = $test_keys{$key_type}->{key} . q{ } . $comment;

    # Test key() method of supplying the key (and etc.) material
    $ak_entry = Config::OpenSSH::Authkey::Entry->new;
    $ak_entry->key($ak_string);

    is( $ak_entry->comment,   $comment,   "check comment for $key_type" );
    is( $ak_entry->options,   '',         "options not set for $key_type" );
    is( $ak_entry->as_string, $ak_string, "$key_type stringifies properly" );

    $ak_string = $options . q{ } . $test_keys{$key_type}->{key};
    $ak_entry  = Config::OpenSSH::Authkey::Entry->new($ak_string);

    is( $ak_entry->options,   $options,   "check options for $key_type" );
    is( $ak_entry->comment,   '',         "comment not set for $key_type" );
    is( $ak_entry->as_string, $ak_string, "$key_type stringifies properly" );

    $ak_string =
      $options . q{ } . $test_keys{$key_type}->{key} . q{ } . $comment;
    $ak_entry = Config::OpenSSH::Authkey::Entry->new->parse($ak_string);

    is( $ak_entry->comment,   $comment,   "check comment for $key_type" );
    is( $ak_entry->options,   $options,   "check options for $key_type" );
    is( $ak_entry->as_string, $ak_string, "$key_type stringifies properly" );
  };
  if ($@) {
    chomp $@;
    diag("Unexpected error for $key_type non-plain: $@");
  }
}

# named option method tests
{
  my $ak_entry;
  eval {
    $ak_entry =
      Config::OpenSSH::Authkey::Entry->new( $test_keys{ssh_rsa_key}->{key} );

    is( $ak_entry->options, '', 'check options() for no output' );

    my @response = $ak_entry->get_option('no-pty');
    ok( @response == 0, 'lookup unset option - list context' );
    is( scalar $ak_entry->get_option('no-pty'),
      '', 'lookup unset option - scalar context' );

    $ak_entry->set_option('no-agent-forwarding');

    @response = $ak_entry->get_option('no-agent-forwarding');
    is( $response[0], 'no-agent-forwarding', 'get boolean option' );
    ok( @response == 1, 'check that only one value returned' );

    is( $ak_entry->options, 'no-agent-forwarding', 'check options() output' );

    $ak_entry->set_option( 'from', '127.0.0.1' );

    @response = $ak_entry->get_option('from');
    is( $response[0], '127.0.0.1', 'get from option' );
    ok( @response == 1, 'check that only one value returned' );

    # DWIW demands wantarray() in get_option...
    is( $ak_entry->get_option('no-agent-forwarding'),
      'no-agent-forwarding', 'make get_option DWIW in scalar context' );

    is(
      $ak_entry->options,
      'no-agent-forwarding,from="127.0.0.1"',
      'check options() output again'
    );

    is(
      $ak_entry->as_string,
      'no-agent-forwarding,from="127.0.0.1" '
        . $test_keys{ssh_rsa_key}->{key},
      'check as_string for manually set options'
    );

    # Now see if things hold up while striking down options...
    $ak_entry->set_option('no-pty');
    $ak_entry->unset_option('from');

    is( $ak_entry->options, 'no-agent-forwarding,no-pty',
      'check options() output yet again' );

    # Totally clear the options
    $ak_entry->unset_option($_) for qw/no-agent-forwarding no-pty/;
    is( $ak_entry->options, '', 'check options() for no output again' );

    # Duplicate option handling
    $ak_entry->options('from="127.0.0.1",no-pty,from="localhost"');

    is(
      $ak_entry->options,
      'from="127.0.0.1",no-pty,from="localhost"',
      'check options() for duplicate entries'
    );

    $ak_entry->set_option( 'from', '::1' );

    is( $ak_entry->options, 'from="::1",no-pty',
      'check options() for de-duplicated entries' );

    is( $ak_entry->duplicate_of, 0, 'check default for duplicate_of' );
    $ak_entry->duplicate_of(1);
    is( $ak_entry->duplicate_of, 1, 'check that duplicate_of accpets value' );

    $ak_entry->unset_duplicate;
    ok( !$ak_entry->duplicate_of, 'check that duplicate cleared' );

  };
  if ($@) {
    chomp $@;
    diag("Unexpected error during get|set_option tests: $@");
  }
}

exit 0;
