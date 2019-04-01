use strict;
use warnings;
use utf8;
use v5.10;

use Test::More;
use Test::MockTime qw(set_fixed_time);
use Test::SetupTeardown;

use File::Path qw(remove_tree);
use YAML::Tiny;
use JSON;

my $test_user = getpwuid($>);
my $random_element = int(rand(1000000)) + 1000000;

my $root_path = "/tmp/app_spoor_test_root";

sub setup {
  mkdir("$root_path", 0744);
  mkdir("$root_path/var", 0744);
  mkdir("$root_path/var/lib", 0744);
  mkdir("$root_path/var/lib/spoor", 0744);
  mkdir("$root_path/var/lib/spoor/parsed", 0744);
}

sub teardown {
  remove_tree($root_path);
}

sub file_contents {
  my $filepath = shift;
  my $json = do {
    local $/;
    open my $fh, '<:raw', $filepath;
    <$fh>;
  };

  JSON->new->decode($json);
}
my $parsed_entries_path = "$root_path/var/lib/spoor/parsed";

my $current_time = time;
set_fixed_time($current_time);

my %contents = (
  type => 'foo',
  event => 'forward_added',
);

my %unrecognised_contents = (
  type => 'foo',
  event  => 'unrecognised'
);
my %config = (
  parsed_entries_path => $parsed_entries_path,
);

BEGIN {
  use_ok('App::Spoor::ParsedEntryWriter') || print "Could not load App::Spoor::AccessEntryParser\n";
}

ok(
  defined(&App::Spoor::ParsedEntryWriter::write_parsed_entry),
  'App::Spoor::ParsedEntryWriter::write_parsed_entry is not defined'
);

my $environment = Test::SetupTeardown->new(setup => \&setup, teardown => \&teardown);

my %successful_mailbox_login_contents = (
  type => 'login',
  event => 'login',
  context => 'mailbox',
  status => 'success'
);

my %unsuccessful_mailbox_login_contents = (
  type => 'login',
  event => 'login',
  context => 'mailbox',
  status => 'anything but success'
);

my %successful_non_mailbox_login_contents = (
  type => 'login',
  event => 'login',
  context => 'iamnotamailbox',
  status => 'success'
);

my %successful_mailbox_forward_added_partial_ip_contents = (
  type => 'notsignificant',
  event => 'forward_added_partial_ip',
  context => 'mailbox',
  status => 'success'
);

my %unsuccessful_mailbox_forward_added_partial_ip_contents = (
  type => 'notsignificant',
  event => 'forward_added_partial_ip',
  context => 'mailbox',
  status => 'anythingbutsuccess'
);

my %successful_non_mailbox_forward_added_partial_ip_contents = (
  type => 'notsignificant',
  event => 'forward_added_partial_ip',
  context => 'iamnotamailbox',
  status => 'success'
);

my %forward_added_partial_recipient_contents = (
  type => 'notsignificant',
  event => 'forward_added_partial_recipient',
  context => 'mailbox',
  forward_type => 'email',
  status => 'success'
);

my %unsuccessful_forward_added_partial_recipient_contents = (
  type => 'notsignificant',
  event => 'forward_added_partial_recipient',
  context => 'mailbox',
  forward_type => 'email',
  status => 'notasuccess'
);

my %non_email_forward_forward_added_partial_recipient_contents = (
  type => 'notsignificant',
  event => 'forward_added_partial_recipient',
  context => 'mailbox',
  forward_type => 'notemail',
  status => 'success'
);

my %non_mailbox_context_forward_added_partial_recipient_contents = (
  type => 'notsignificant',
  event => 'forward_added_partial_recipient',
  context => 'domain',
  forward_type => 'email',
  status => 'success'
);

my %successful_mailbox_level_forward_removal = (
  type => 'notsignificant',
  event => 'forward_removed',
  context => 'mailbox',
  status => 'success'
);

my %unsuccessful_mailbox_level_forward_removal = (
  type => 'notsignificant',
  event => 'forward_removed',
  context => 'mailbox',
  status => 'notsuccess'
);

my %successful_non_mailbox_level_forward_removal = (
  type => 'notsignificant',
  event => 'forward_removed',
  context => 'notamailbox',
  status => 'success'
);

$environment->run_test('Writes the parsed successful mailbox login', sub {
    my $created_filepath = App::Spoor::ParsedEntryWriter::write_parsed_entry(
      \%successful_mailbox_login_contents, \%config
    );
    ok(
      $created_filepath =~ m|$parsed_entries_path/login\.$current_time\.\d{7}\.json|,
      'Correct file path for successful mailbox login'
    );
    ok((-e $created_filepath), 'File has been created for successful mailbox login');

    is((stat($created_filepath))[2] & 07777, 0600, 'Created file has correct permissions');

    is_deeply(
      \%successful_mailbox_login_contents,
      file_contents($created_filepath),
      'Persisted contents match successful mailbox login contents'
    );
  });

$environment->run_test('Does not write an unsuccessful mailbox login', sub {
    is(
      App::Spoor::ParsedEntryWriter::write_parsed_entry(\%unsuccessful_mailbox_login_contents, \%config),
      undef,
      'Did not return undef for the path for an unsuccesful mailbox login'
    );

    opendir(my $dh, $parsed_entries_path);
    my @actual_dir_contents = sort readdir($dh);
    closedir($dh);
    is_deeply(\@actual_dir_contents, ['.', '..'], 'Directory is empty for an unsuccessful mailbox login');
  });

$environment->run_test('Does not write a successful non-mailbox login', sub {
    is(
      App::Spoor::ParsedEntryWriter::write_parsed_entry(\%successful_non_mailbox_login_contents, \%config),
      undef,
      'Did not return undef for the path for a successful non-mailbox login'
    );

    opendir(my $dh, $parsed_entries_path);
    my @actual_dir_contents = sort readdir($dh);
    closedir($dh);
    is_deeply(\@actual_dir_contents, ['.', '..'], 'Directory is empty for a successful non-mailbox login');
  });

$environment->run_test('Writes the successful forward_added_partial ip entry for a mailbox', sub {
    my $created_filepath = App::Spoor::ParsedEntryWriter::write_parsed_entry(
      \%successful_mailbox_forward_added_partial_ip_contents, \%config
    );
    ok(
      $created_filepath =~ m|$parsed_entries_path/notsignificant\.$current_time\.\d{7}\.json|,
      'Correct file path for successful mailbox added forward partial ip entry'
    );
    ok((-e $created_filepath), 'File has been created for successful mailbox added forward partial ip entry');

    is((stat($created_filepath))[2] & 07777, 0600, 'Created file has correct permissions');

    is_deeply(
      \%successful_mailbox_forward_added_partial_ip_contents,
      file_contents($created_filepath),
      'Persisted contents match successful mailbox added forward partial ip contents'
    );
  });

$environment->run_test('Does not write an unsuccessful mailbox added forward partial ip entry', sub {
    is(
      App::Spoor::ParsedEntryWriter::write_parsed_entry(
        \%unsuccessful_mailbox_forward_added_partial_ip_contents, 
        \%config
      ),
      undef,
      'Did not return undef for the path for an unsuccesful mailbox added forward partial ip entry'
    );

    opendir(my $dh, $parsed_entries_path);
    my @actual_dir_contents = sort readdir($dh);
    closedir($dh);
    is_deeply(
      \@actual_dir_contents,
      ['.', '..'],
      'Directory is empty for an unsuccessful mailbox added forward partial ip entry'
    );
  });

$environment->run_test('Does not write a successful non-mailbox added forward partial ip entry', sub {
    is(
      App::Spoor::ParsedEntryWriter::write_parsed_entry(
        \%successful_non_mailbox_forward_added_partial_ip_contents, 
        \%config
      ),
      undef,
      'Did not return undef for the path for a succesful non-mailbox forward added partial ip entry'
    );

    opendir(my $dh, $parsed_entries_path);
    my @actual_dir_contents = sort readdir($dh);
    closedir($dh);
    is_deeply(
      \@actual_dir_contents,
      ['.', '..'],
      'Directory is empty for a successful non-mailbox forward added partial ip entry'
    );
  });

$environment->run_test('Writes the successful forward_added_partial recipient entry for a mailbox', sub {
    my $created_filepath = App::Spoor::ParsedEntryWriter::write_parsed_entry(
      \%forward_added_partial_recipient_contents, \%config
    );
    ok(
      $created_filepath =~ m|$parsed_entries_path/notsignificant\.$current_time\.\d{7}\.json|,
      'Correct file path for successful mailbox added forward partial recipient entry'
    );
    ok((-e $created_filepath), 'File has been created for successful mailbox added forward partial recipient entry');

    is((stat($created_filepath))[2] & 07777, 0600, 'Created file has correct permissions');

    is_deeply(
      \%forward_added_partial_recipient_contents,
      file_contents($created_filepath),
      'Persisted contents match successful mailbox added forward partial recipient contents'
    );
  });

$environment->run_test('Does not write an unsuccessful added forward partial recipient entry', sub {
    is(
      App::Spoor::ParsedEntryWriter::write_parsed_entry(
        \%unsuccessful_forward_added_partial_recipient_contents, 
        \%config
      ),
      undef,
      'Did not return undef for the path for an unsuccesful mailbox added forward partial recipient entry'
    );

    opendir(my $dh, $parsed_entries_path);
    my @actual_dir_contents = sort readdir($dh);
    closedir($dh);
    is_deeply(
      \@actual_dir_contents,
      ['.', '..'],
      'Directory is empty for an unsuccessful mailbox added forward partial recipient entry'
    );
  });

$environment->run_test('Does not write an added forward partial recipient where the recipient is not an email', sub {
    is(
      App::Spoor::ParsedEntryWriter::write_parsed_entry(
        \%non_email_forward_forward_added_partial_recipient_contents, 
        \%config
      ),
      undef,
      'Did not return undef for the path for a partial recipient that does not forward to an email'
    );

    opendir(my $dh, $parsed_entries_path);
    my @actual_dir_contents = sort readdir($dh);
    closedir($dh);
    is_deeply(
      \@actual_dir_contents,
      ['.', '..'],
      'Directory is empty for a partial recipient that does not forward to an email'
    );
  });

$environment->run_test('Does not write when the partial recipient is not in the mailbox context', sub {
    is(
      App::Spoor::ParsedEntryWriter::write_parsed_entry(
        \%non_mailbox_context_forward_added_partial_recipient_contents, 
        \%config
      ),
      undef,
      'Did not return undef for the path for a non-mailbox partial recipient entry'
    );

    opendir(my $dh, $parsed_entries_path);
    my @actual_dir_contents = sort readdir($dh);
    closedir($dh);
    is_deeply(
      \@actual_dir_contents,
      ['.', '..'],
      'Directory is empty for a non-mailbox partial recipient entry'
    );
  });

$environment->run_test('Does not write an unrecognised entry', sub {
    is(
      App::Spoor::ParsedEntryWriter::write_parsed_entry(\%unrecognised_contents, \%config),
      undef,
      'Did not return undef'
    );

    opendir(my $dh, $parsed_entries_path);
    my @actual_dir_contents = sort readdir($dh);
    closedir($dh);
    is_deeply(\@actual_dir_contents, ['.', '..'], 'Directory is not empty');
  });

$environment->run_test('Writes the successful mailbox-level forward removal', sub {
    my $created_filepath = App::Spoor::ParsedEntryWriter::write_parsed_entry(
      \%successful_mailbox_level_forward_removal, \%config
    );
    ok(
      $created_filepath =~ m|$parsed_entries_path/notsignificant\.$current_time\.\d{7}\.json|,
      'Correct file path for successful mailbox forward removal'
    );
    ok((-e $created_filepath), 'File has been created for successful mailbox forward removal');

    is((stat($created_filepath))[2] & 07777, 0600, 'Created file has correct permissions');

    is_deeply(
      \%successful_mailbox_level_forward_removal,
      file_contents($created_filepath),
      'Persisted contents match successful mailbox forward removal contents'
    );
  });

$environment->run_test('Does not write an unsuccessful mailbox forward removal', sub {
    is(
      App::Spoor::ParsedEntryWriter::write_parsed_entry(\%unsuccessful_mailbox_level_forward_removal, \%config),
      undef,
      'Did not return undef for the path for an unsuccesful mailbox forward removal'
    );

    opendir(my $dh, $parsed_entries_path);
    my @actual_dir_contents = sort readdir($dh);
    closedir($dh);
    is_deeply(
      \@actual_dir_contents,
      ['.', '..'],
      'Directory is empty for an unsuccessful mailbox forward removal'
    );
  });

$environment->run_test('Does not write an successful non-mailbox forward removal', sub {
    is(
      App::Spoor::ParsedEntryWriter::write_parsed_entry(\%successful_non_mailbox_level_forward_removal, \%config),
      undef,
      'Did not return undef for the path for an successful non-mailbox forward removal'
    );

    opendir(my $dh, $parsed_entries_path);
    my @actual_dir_contents = sort readdir($dh);
    closedir($dh);
    is_deeply(
      \@actual_dir_contents,
      ['.', '..'],
      'Directory is empty for an successful non-mailbox forward removal'
    );
  });

done_testing();
