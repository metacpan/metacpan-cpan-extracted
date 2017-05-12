#!perl

use strict;
use warnings;
use Test::More qw( no_plan );
use Test::Exception;
use Test::Deep;
use App::Smolder::Report;
use File::Temp;

my $sr = App::Smolder::Report->new;
ok($sr);
ok(!defined($sr->dry_run));
ok(!defined($sr->username));
ok(!defined($sr->password));
ok(!defined($sr->project_id));
ok(!defined($sr->server));
ok(!defined($sr->run_as_api));

my @incr_tests = (
  {
    add_to_cfg => {},
    re => qr/Required 'server' setting is empty or missing/,
  },
  
  {
    add_to_cfg => { server => 'server.example.com' },
    re => qr/Required 'project_id' setting is empty or missing/,
  },

  {
    add_to_cfg => { project_id => 1 },
    re => qr/Required 'username' setting is empty or missing/,
  },
  
  {
    add_to_cfg => { username => 'user1' },
    re => qr/Required 'password' setting is empty or missing/,
  },
  
  {
    add_to_cfg => { password => 'pass1' },
    re => qr/You must provide at least one report to upload/,
  },
);

foreach my $t (@incr_tests) {
  $sr->_merge_cfg_hash($t->{add_to_cfg});
  throws_ok sub { $sr->report }, $t->{re};
}

my $url;
lives_ok sub { $url = $sr->report('Makefile.PL') };
is($url, 'http://server.example.com/redirected/to/me');
cmp_deeply($LWP::UserAgent::last_post, [
  'http://server.example.com/app/developer_projects/process_add_report/1',
  'Content-Type' => 'form-data',
  'Content'      => [
    username => 'user1',
    password => 'pass1',
    tags     => '',
    report_file => ['Makefile.PL'],
  ],
]);

$sr->_merge_cfg_hash({ server => 'https://secure' });
lives_ok sub { $url = $sr->report('Makefile.PL') };
is($url, 'https://secure/redirected/to/me');
cmp_deeply($LWP::UserAgent::last_post, [
  'https://secure/app/developer_projects/process_add_report/1',
  'Content-Type' => 'form-data',
  'Content'      => [
    username => 'user1',
    password => 'pass1',
    tags     => '',
    report_file => ['Makefile.PL'],
  ],
]);

lives_ok sub { $url = $sr->report('Makefile.PL', 'MANIFEST') };
is($url, 'https://secure/redirected/to/me');
cmp_deeply($LWP::UserAgent::last_post, [
  'https://secure/app/developer_projects/process_add_report/1',
  'Content-Type' => 'form-data',
  'Content'      => [
    username => 'user1',
    password => 'pass1',
    tags     => '',
    report_file => ['MANIFEST'],
  ],
]);

throws_ok sub {
  $url = $sr->report('Makefile.PL', 'MANIFEST', 'NoSuchFile')
}, qr/FATAL: Could not read report file 'NoSuchFile'/;

my $tmp = File::Temp->new( CLEANUP => 1);
$sr->_merge_cfg_hash({ delete => 1 });
lives_ok sub { $url = $sr->report($tmp->filename) };
ok(! -e $tmp->filename);

$tmp = File::Temp->new( CLEANUP => 1);
$sr->_merge_cfg_hash({ delete => 1 });
lives_ok sub { $url = $sr->run($tmp->filename) };
cmp_deeply($LWP::UserAgent::last_post, [
  'https://secure/app/developer_projects/process_add_report/1',
  'Content-Type' => 'form-data',
  'Content'      => [
    username => 'user1',
    password => 'pass1',
    tags     => '',
    report_file => [$tmp->filename],
  ],
]);
ok(! -e $tmp->filename);


$LWP::UserAgent::error = [401, 'bad password'];
$url = undef;
throws_ok sub {
  $url = $sr->report('Makefile.PL')
}, qr/HTTP Code: 401.+bad password/s;
ok(!defined($url), 'no redirect');


$LWP::UserAgent::last_post = undef;
$sr->{dry_run} = 1;
lives_ok sub { $url = $sr->report('Makefile.PL') };
ok(!defined($url));
ok(!defined($LWP::UserAgent::last_post), 'Dry run does not post');


package LWP::UserAgent;

use strict;
no warnings;

our $last_post;
our $error;

sub new { return bless {}, $_[0] }

sub post {
  my $self = shift;
  $last_post = [@_];

  my ($rc, $msg) = (302, 'Okydoky');
  if ($error) {
    ($rc, $msg) = @$error;
    $error = undef;
  }
  
  return HTTP::Response->new(
    $rc, $msg,
    [ Location => '/redirected/to/me' ],
  );
}

1;
