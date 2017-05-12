
use IO::Handle;

eval "use Test::WWW::Mechanize";
if($@) {
  plan skip_all => 'Test::WWW::Mechanize not installed';
  exit;
}

sub start_proggie {
  my ($filename) = @_;
  *STDERR = *STDOUT;
  my $kid_pid = open(my $kid_out, '-|');
  die "Unable to fork!" unless defined($kid_pid);
  if($kid_pid) {
    $kid_out->autoflush;
    return ($kid_out, $kid_pid);
  } else {
    if(-e $filename) {
      do $filename or die "Unable to eval $filename! $@";
    } else {
      die "I can't find '$filename'!";
    }
    exit;
  }
}

sub get_proggie_server_ok {
  my ($kid_out) = @_;
  my $server = <$kid_out>;
  chomp $server;
  if($server =~ /^Please contact me at: http:\/\/[^:]+:(\d+)/) {
    $server = "http://localhost:$1/";
    pass("Server started");
  } else {
    fail("Server started");
    die;
  }
  return $server;
}

1;

