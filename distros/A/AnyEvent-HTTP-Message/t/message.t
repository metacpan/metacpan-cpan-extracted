use strict;
use warnings;
use Test::More 0.88;

my $mod = 'AnyEvent::HTTP::Message';
eval "require $mod" or die $@;

sub test_new;

my $tmod = $mod . '::Test';
eval <<PKG;
{
  package #
    $tmod;
  our \@ISA = '$mod';
  sub body { uc shift->{body} }
  sub parse_args {
    shift;
    return { body => shift, headers => { \@_ } };
  }
  sub from_http_message {
    shift;
    my \$msg = shift;
    return { body => \$msg->body, headers => \$msg->headers };
  }
}
PKG

# enable some tests to work without actually requiring HTTP::Message
my $httpm = 'HTTP::Message';
if( !$INC{"HTTP/Message.pm"} ){
  eval <<PKG
    package #
      $httpm;
    sub new { bless { headers => { \@{ \$_[1] || [] } }, body => \$_[2] }, \$_[0] }
    @{[ map { "sub $_ { shift->{$_} }" } qw(headers body) ]}
PKG
}

foreach my $args (
  ['silly', 'fake-header' => 'fake-value'],
  [{
    body => 'silly',
    headers => { 'fake-header' => 'fake-value' },
  }],
  [ $httpm->new( ['fake-header' => 'fake-value'], 'silly') ],
){
  my $msg = new_ok($tmod, [@$args]);

  is $msg->body,    'SILLY', 'body';
  is $msg->content, 'SILLY', 'content alias';

  is $msg->header('fake_header'), 'fake-value', 'single header';
}

{
  my $line = __LINE__; is eval { $tmod->_error("BOO") }, undef, 'croaked';
  like $@,
    qr/$tmod error: BOO at ${\__FILE__} line $line/,
    'custom error message';
}

{
  test_new [ {foo => 'bar'} ],
    'succeeds with hashref';

  test_new [  foo => 'bar' ], q/parse_args\(\) is not defined/,
    'fails when custom parse_args() not defined';

  # we should be able to test this failure without the real HTTP::Message
  {
    my $msg = $httpm->new();
    test_new [ $msg ], q/from_http_message\(\) is not defined/,
      'failed to create message from HTTP::Message';
  }
}

done_testing;

sub test_new {
  my $args = shift;
  my $desc = pop;
  my $error = shift; # middle arg
  my $exp = $error ? undef : 1;

  is eval { $mod->new( @$args ); 1 }, $exp, "new(): $desc";

  like $@, qr/$mod error: $error/, "error: $desc"
    if $error;
}
