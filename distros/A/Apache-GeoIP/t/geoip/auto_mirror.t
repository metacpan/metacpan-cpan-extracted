use strict;
use warnings FATAL => 'all';
use File::Spec::Functions;
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'GET';
my $atv = $Apache::Test::VERSION + 0;

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
t_debug("connecting to $hostport");

Apache::TestRequest::user_agent(reset => 1,
                                requests_redirectable => 0);
my $file = 'my/silly/file.txt';
my $number = 8;
plan tests => 2 * 3 * $number + 2 * 2;

# test basic mirror redirection
my %mirrors;
my $mirror_file = catfile Apache::Test::vars('t_dir'),
    'conf', 'auto_mirror.txt';
open(my $fh, $mirror_file) or die "Cannot open $mirror_file: $!";
while (<$fh>) {
    my ($host, $cn) = split ' ', $_, 2;
    $mirrors{$host}++;
}
close $fh;

for (1 .. $number) {
  my $received = GET "/mirror/$file";
  ok t_cmp(
           $received->code,
           302,
           'testing redirect',
          );
  my $content = $received->content;
  my $loc = '';
  if ($content =~ m{href="([^"]+)}i) {
      $loc = $1;
  }
  if ($atv < 1.12) {
    ok t_cmp(
             qr/$file/,
             $loc,
             "testing presence of '$file'",
             );
  }
  else {
    ok t_cmp(
             $loc,
             qr/$file/,
             "testing presence of '$file'",
             );
  }

  (my $host = $loc) =~ s{/$file}{};
  my $present = exists $mirrors{$host} ? 1 : 0;
  ok t_cmp(
           $present,
           1,
           'testing redirect to known host',
          );
}

# test mirror redirection with freshness
%mirrors = ();
$mirror_file = catfile Apache::Test::vars('t_dir'),
    'conf', 'auto_mirror_fresh.txt';
open($fh, $mirror_file) or die "Cannot open $mirror_file: $!";
while (<$fh>) {
    my ($host, $cn, $fresh) = split ' ', $_, 3;
    $mirrors{$host}++ if ($fresh >= 2);
}
close $fh;

for (1 .. $number) {
  my $received = GET "/mirror_fresh/$file";
  ok t_cmp(
           $received->code,
           302,
           'testing redirect',
          );
  my $content = $received->content;
  my $loc = '';
  if ($content =~ m{href="([^"]+)}i) {
      $loc = $1;
  }
  if ($atv < 1.12) {
    ok t_cmp(
             qr/$file/,
             $loc,
             "testing presence of '$file'",
             );
  }
  else {
    ok t_cmp(
             $loc,
             qr/$file/,
             "testing presence of '$file'",
             );
  }

  (my $host = $loc) =~ s{/$file}{};
  my $present = exists $mirrors{$host} ? 1 : 0;
  ok t_cmp(
           $present,
           1,
           'testing redirect to known host',
          );
}

# test default robot

my $received = GET "/mirror_robot_default/robots.txt";
ok t_cmp(
        $received->code,
        200,
        'testing robots.txt',
        );
my $content = $received->content;
my $expected = << "END";
User-agent: *
Disallow: /
END
$content =~ s/\r?\n//g;
$expected =~ s/\r?\n//g;
ok t_cmp(
        $content,
        $expected,
        'testing contents of default robots.txt',
        );

# test user-supplied robots.txt
my $robots_txt_file = $mirror_file = catfile Apache::Test::vars('t_dir'),
    'conf', 'robots.txt';
open($fh, $robots_txt_file) or die "Cannot open $robots_txt_file: $!";
my @lines = <$fh>;
close $fh;
$expected = join "\n", @lines;
$received = GET "/mirror_robot/robots.txt";
ok t_cmp(
        $received->code,
        200,
        'testing robots.txt',
        );
$content = $received->content;
$content =~ s/\r?\n//g;
$expected =~ s/\r?\n//g;
ok t_cmp(
        $content,
        $expected,
        'testing contents of user-supplied robots.txt',
        );
