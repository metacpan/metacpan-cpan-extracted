#!/usr/bin/perl

use strict;
use warnings;

use Devel::Cover;
use File::HomeDir qw{ my_home };
use File::Temp;
use Pod::Coverage;
use Test::Exception;
use Test::MockObject::Extends;
use Test::More;
use Test::Pod::Coverage;
#use Test::TestCoverage;
use Test::Trap;

#test_coverage( 'App::OATH' );
#test_coverage( 'App::OATH::Crypt' );
#test_coverage( 'App::OATH::Crypt::Rijndael' );
#test_coverage( 'App::OATH::Crypt::CBC' );

use_ok( 'App::OATH' );
use_ok( 'App::OATH::Crypt' );
use_ok( 'App::OATH::Crypt::Rijndael' );
use_ok( 'App::OATH::Crypt::CBC' );

my $app = App::OATH->new();

subtest 'Instantiate' => sub {
  isa_ok( $app, 'App::OATH' );
};

subtest 'Usage' => sub {
  my @usage = trap{ $app->usage(); };
  is( $trap->exit, 0, 'Exits with 0' );
  like( $trap->stdout, qr/usage: /, 'Looks like usage' );
};

subtest 'Search accessors' => sub {
  is( $app->get_search(), undef, 'Default undef' );
  my $search = 'lorem ipsum';
  $app->set_search( $search );
  is( $app->get_search(), $search, 'Value set/get' );
};

my $filename;
{
    my $tmp_file = File::Temp->new(
        'TEMPLATE' => 'app-oath-unit-tests-XXXXXXXX',
        'UNLINK'   => 0,
    );
    $filename = $tmp_file->filename();
    unlink $filename;
    END{ unlink $filename; };
}

my $filename2;
{
    my $tmp_file = File::Temp->new(
        'TEMPLATE' => 'app-oath-unit-tests-XXXXXXXX',
        'UNLINK'   => 0,
    );
    $filename2 = $tmp_file->filename();
    unlink $filename2;
    END{ unlink $filename2; };
}

subtest 'Filename accessors' => sub {
  is( $app->get_filename(), my_home() . '/.oath.json', 'Default undef' );
  $app->set_filename( $filename );
  is( $app->get_filename(), $filename, 'Value set/get' );
};

subtest 'Dies on file does not exist' => sub {
  dies_ok( sub{ $app->list_keys() }, 'List Keys' );
  dies_ok( sub{ $app->display_codes() }, 'Display Codes' );
  dies_ok( sub{ $app->add_entry() }, 'Add Entry' );
  dies_ok( sub{ $app->load_data() }, 'Load Data' );
  dies_ok( sub{ $app->save_data() }, 'Save Data' );
  dies_ok( sub{ $app->get_plaintext() }, 'Get Plaintext' );
  dies_ok( sub{ $app->get_encrypted() }, 'Get Encrypted' );
  dies_ok( sub{ $app->encrypt_data() }, 'Encrypt Data' );
  dies_ok( sub{ $app->decrypt_data() }, 'Decrypt Data' );
};

subtest 'Password accessors' => sub {
  # Add test for stdin
  my $newapp = Test::MockObject::Extends->new( $app );
  isa_ok( $newapp, 'T::MO::E::a' );
  $newapp->mock( '_read_password_stdin', sub{ return 'secure'; } );
  $newapp->{'password'} = 'secret';
  is( $newapp->get_password(), 'secret', 'Get password' );

  $newapp->drop_password();
  is ( $newapp->{'password'}, undef, 'Drop password' );

  is( $newapp->get_password(), 'secure', 'Get password from STDIN' );
  $app->{'password'} = 'secret';

};

subtest 'Init new file' => sub {
  $app->init();
  is( -e $filename, 1, 'File created' );
  is_deeply( $app->get_plaintext, {}, 'Plaintext' );
  is_deeply( $app->get_encrypted, {}, 'Encrypted' );
};

subtest 'Init existing file' => sub {
  my @init = trap{ $app->init(); };
  is( $trap->exit, 1, 'Exits with 1' );
  is( $trap->stdout, "Error: file already exists\n", 'Gives error message' );
};

subtest 'Add entry' => sub {
  my @a;

  subtest 'By URL' => sub {
    @a = trap{ $app->add_entry( 'otpauth://totp/alice@google.com?secret=JBSWY3DPEHPK3PXP' ); };
    is( $trap->exit, undef, 'New key succeeds' );
    is( $trap->stdout, "Adding OTP for alice\@google.com\n", 'Gives success message' );
    @a = trap{ $app->add_entry( 'otpauth://totp/alice@google.com?secret=JBSWY3DPEHPK3PXP' ); };
    is( $trap->exit, 1, 'Duplicate exits with 1' );
    is( $trap->stdout, "Error: Key already exists\n", 'Gives error message' );
  };
  
  subtest 'By String' => sub {
    @a = trap{ $app->add_entry( 'alice:JBSWY3DPEHPK3PXP' ); };
    is( $trap->exit, undef, 'New key succeeds' );
    is( $trap->stdout, "Adding OTP for alice\n", 'Gives success message' );
    @a = trap{ $app->add_entry( 'alice:JBSWY3DPEHPK3PXP' ); };
    is( $trap->exit, 1, 'Duplicate exits with 1' );
    is( $trap->stdout, "Error: Key already exists\n", 'Gives error message' );
  };

  subtest 'Invalid string' => sub {
    @a = trap{ $app->add_entry( 'alice=JBSWY3DPEHPK3PXP' ); };
    is( $trap->exit, 1, 'Exits with 1' );
    is( $trap->stdout, "Error: Unknown format\n", 'Gives error message' );
  };

};

subtest 'List keys' => sub {
  delete $app->{'search'};
  my @a;
  @a = trap{ $app->list_keys(); };
  is( $trap->stdout, "alice\nalice\@google.com\n\n", 'Keys listed' );
  $app->set_search( 'google' );
  @a = trap{ $app->list_keys(); };
  is( $trap->stdout, "alice\@google.com\n\n", 'Keys searched' );
};

subtest 'Data Access' => sub {

  my $data = $app->get_plaintext();
  my $expected = {
      'alice' => 'JBSWY3DPEHPK3PXP',
      'alice@google.com' => 'JBSWY3DPEHPK3PXP'
  };
  is_deeply( $data, $expected, 'Get plaintext' );

  my $encrypted = $app->get_encrypted();
  is_deeply( [ sort keys %$encrypted ], [ 'alice', 'alice@google.com' ], 'Get encrypted (keys exist)' );

  is( $encrypted->{'alice'} ne $encrypted->{'alice@google.com'}, 1, 'Payloads are not the same' );
    
  my $encrypted_entry;
  use_ok( 'Convert::Base32' );
  my ( $type, $ctext ) = split ':', $encrypted->{'alice'};
  lives_ok( sub{ $encrypted_entry = decode_base32( $ctext ) }, 'Valid Base32');
  dies_ok(  sub{ my $dummy = decode_base32( 'This is totally bogus' ) }, 'Dies on invalid Base32');


};

subtest 'Crypt object' => sub {

  my $crypt = App::OATH::Crypt->new( 'password' );
  isa_ok( $crypt, 'App::OATH::Crypt' );

  foreach my $t ( @{ $crypt->get_workers_list() } ) {

    subtest 'Crypt type ' . $t => sub {

      $crypt->set_worker( $t );

      my $ptext = 'thisIsATest';
      my $ctext = $crypt->encrypt( $ptext );
      isnt( $ctext, $ptext, 'Text was encrypted' );

      my $dtext = $crypt->decrypt( $ctext );
      is( $dtext, $ptext, 'Text decrypts ok' );

      my ( $worker ) = split ':', $ctext;
      $crypt->{'check'} = 'bogus';
      $dtext = $crypt->decrypt( $ctext );
      is( $dtext, undef, 'Text decrypts ok but check fails' );
      $crypt->{'check'} = 'oath';

      dies_ok(  sub{ my $dummy = $crypt->decrypt( 'This is totally bogus' ); }, 'Dies on invalid decrypt' );
    };

  }

  $crypt->set_worker( q{} );
  my $ptext = 'thisIsATest';
  my $ctexta = $crypt->encrypt( $ptext );
  my ( $ctype, $ctext ) = split ':', $ctexta;
  is( $ctype, 'cbcrijndael', 'Default encryption type cbcrijndael' );

  $crypt->set_worker( 'rijndael' );
  $ptext = 'thisIsATest';
  $ctext = $crypt->encrypt( $ptext );
  ( $ctype, $ctext ) = split ':', $ctext;
  is( $ctype, 'rijndael', 'Specified encryption type rijndael' );
  $crypt->set_worker( '' );
  my $dtext = $crypt->decrypt( $ctext );
  is( $dtext, $ptext, 'Default decryption type rijndael' );

  dies_ok( sub{ $crypt->set_worker( 'NoSuchWorker' ); }, 'Dies on set invalid worker' );

  dies_ok( sub{ $crypt->decrypt( 'NoSuchWorker:Gibberish' ); }, 'Dies on decrypt invalid worker' );

  my $bad_crypt = 'cbcrijndael:' . $crypt->{'workers'}->{'cbcrijndael'}->encrypt('bogus');
  my $bad_decrypt = $crypt->decrypt( $bad_crypt );
  is( $bad_decrypt, undef, 'Bad check returns undef' );

};

subtest 'New instance decrypt' => sub {
  my $app2 = App::OATH->new();
  $app2->{'password'} = 'secret';
  $app2->set_filename( $filename );
  
  my $data = $app2->get_plaintext();
  my $expected = {
      'alice' => 'JBSWY3DPEHPK3PXP',
      'alice@google.com' => 'JBSWY3DPEHPK3PXP'
  };
  is_deeply( $data, $expected, 'Get plaintext' );
};

subtest 'New instance decrypt invalid password' => sub {
  my $app2 = App::OATH->new();
  $app2->{'password'} = 'bogus';
  $app2->set_filename( $filename );
  
  my $data;
  my @a = trap{ $data = $app2->get_plaintext() };
  is( $trap->exit, 1, 'Exits with 1' );
  is( $trap->stdout, "Invalid password\n", 'Gives error message' );
};

subtest 'Counter' => sub {
  my $baseline = int( time() / 30 );
  my $counter = $app->get_counter();
  # Crazy logic is beetter for testing
  is( ( $counter >= $baseline     ), 1, 'Counter returns proper value low check' );
  is( ( $counter <= $baseline + 1 ), 1, 'Counter returns proper value high check' );
};

subtest 'Gives correct data' => sub {
  my $timestamp = 48058835;

  is( $app->oath_auth( 'JBSWY3DPEHPK3PXP', $timestamp ), '205414', 'Decodes properly' );

  my $app2 = App::OATH->new();
  $app2->{'password'} = 'secret';
  $app2->set_filename( $filename );
  my $newapp = Test::MockObject::Extends->new( $app2 );
  isa_ok( $newapp, 'T::MO::E::b' );
  $newapp->mock( 'get_counter', sub{ return 48058835; } );
  my $counter = $newapp->get_counter();
  is( $counter, $timestamp, 'Mocked get counter' );

  my @a;

  @a = trap{ $app2->display_codes() };
  my $expected = "\n           alice : 205414\nalice\@google.com : 205414\n\n";
  is( $trap->stdout, $expected, 'Shows correct codes' );
  
  $newapp->set_search( 'google' );
  @a = trap{ $app2->display_codes() };
  $expected = "\nalice\@google.com : 205414\n\n";
  is( $trap->stdout, $expected, 'Shows correct codes with search' );
};

subtest 'Set newpass' => sub {
  my $app2 = App::OATH->new();
  my $newapp = Test::MockObject::Extends->new( $app );
  isa_ok( $newapp, 'T::MO::E::c' );
  $newapp->mock( '_read_password_stdin', sub{ return 'secure'; } );
  $app2->{'password'} = 'secret';
  $app2->set_filename( $filename );
  $newapp->set_newpass( 1 );
  $newapp->encrypt_data();
  $newapp->save_data();
  is( $newapp->get_password(), 'secure', 'New password set' );
};

subtest 'Gives correct data with new password' => sub {
  my $timestamp = 48058835;

  is( $app->oath_auth( 'JBSWY3DPEHPK3PXP', $timestamp ), '205414', 'Decodes properly' );

  my $app2 = App::OATH->new();
  $app2->{'password'} = 'secure';
  $app2->set_filename( $filename );
  my $newapp = Test::MockObject::Extends->new( $app2 );
  isa_ok( $newapp, 'T::MO::E::d' );
  $newapp->mock( 'get_counter', sub{ return 48058835; } );
  my $counter = $newapp->get_counter();
  is( $counter, $timestamp, 'Mocked get counter' );

  my @a;

  @a = trap{ $app2->display_codes() };
  my $expected = "\n           alice : 205414\nalice\@google.com : 205414\n\n";
  is( $trap->stdout, $expected, 'Shows correct codes' );
};

subtest 'Key sort and length' => sub {
  $app->{'password'} = 'secret';
  delete $app->{'search'};
  $app->set_filename( $filename2 );
  $app->init();

  my @a;

  @a = trap{ $app->add_entry( 'alice:JBSWY3DPEHPK3PXP' ); };
  is( $trap->exit, undef, 'New key succeeds' );
  is( $trap->stdout, "Adding OTP for alice\n", 'Gives success message' );

  @a = trap{ $app->add_entry( 'bob:JBSWY3DPEHPK3PXP' ); };
  is( $trap->exit, undef, 'New key succeeds' );
  is( $trap->stdout, "Adding OTP for bob\n", 'Gives success message' );

  @a = trap{ $app->add_entry( 'catriona:JBSWY3DPEHPK3PXP' ); };
  is( $trap->exit, undef, 'New key succeeds' );
  is( $trap->stdout, "Adding OTP for catriona\n", 'Gives success message' );

  my $timestamp = 48058835;

  my $newapp = Test::MockObject::Extends->new( $app );
  isa_ok( $newapp, 'T::MO::E::e' );
  $newapp->mock( 'get_counter', sub{ return 48058835; } );
  my $counter = $newapp->get_counter();
  is( $counter, $timestamp, 'Mocked get counter' );

  @a = trap{ $app->display_codes() };
  my $expected = "\n   alice : 205414\n     bob : 205414\ncatriona : 205414\n\n";
  is( $trap->stdout, $expected, 'Shows correct codes properly sorted and justified' );

  $app->set_filename( $filename );

};

subtest 'Locking' => sub {
    my $lock1 = $app->get_lock();
    is( $lock1, 1, 'Could lock' );
    my $lock2 = $app->get_lock();
    is( $lock2, 0, 'Already locked' );
    $app->set_filename( $filename2 );
    my $lock3 = $app->get_lock();
    is( $lock3, 1, 'Could lock after file change' );
    my $lock4 = $app->get_lock();
    is( $lock4, 0, 'Already locked' );
    $app->set_filename( $filename2 );
    my $lock5 = $app->get_lock();
    is( $lock5, 0, 'Still locked after false name change' );
    $app->drop_lock();
};

subtest 'Invalid Filename' => sub {
    my $invalid_filename = $filename . '/invalid';
    $app->set_filename( $invalid_filename );
    dies_ok( sub{ $app->save_data(); }, 'Dies on invalid filename save' );
    $app->set_filename( $filename );
};

subtest 'Pod Coverage' => sub {
    pod_coverage_ok( 'App::OATH' );
    pod_coverage_ok( 'App::OATH::Crypt' );
    pod_coverage_ok( 'App::OATH::Crypt::Rijndael' );
    pod_coverage_ok( 'App::OATH::Crypt::CBC' );
};

#subtest 'Coverage' => sub {
#    ok_test_coverage( 'App::OATH' );
#    ok_test_coverage( 'App::OATH::Crypt' );
#    ok_test_coverage( 'App::OATH::Crypt::CBC' );
#    ok_test_coverage( 'App::OATH::Crypt::Rijndael' );
#};

done_testing();

