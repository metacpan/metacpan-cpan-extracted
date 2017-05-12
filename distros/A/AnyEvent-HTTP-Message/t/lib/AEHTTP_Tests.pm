package #
  AEHTTP_Tests;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  have_http_message
  test_http_message
);

my $mod = 'HTTP::Message';
my $have_hm;
sub have_http_message () {
  if( !defined($have_hm) ){
    $have_hm = eval("require $mod") || 0;
  }
  return $have_hm;
}

# ($obj, \&sub) or just (\&sub)
sub test_http_message (;$&) {
  my $sub = pop;
  my $msg = shift;
  ::subtest(http_message => sub {
    ::plan(skip_all => "$mod required for these tests")
      if !have_http_message;

    my @args;
    if( $msg ){
      push @args, $msg->to_http_message;
      ::isa_ok($args[0], $mod);
    }
    $sub->(@args);
  });
}

1;
