# $Id: 05_custom.t,v 1.3 2004/06/11 20:32:07 claes Exp $

use Test::More tests => 2;

BEGIN { use_ok('Array::Stream::Transactional::Matcher', qw(mkrule)); }
use Array::Stream::Transactional;

package MyRule;
our @ISA = qw(Array::Stream::Transactional::Matcher::Rule);

sub match {
  my ($class, $stream) = @_;
  
  $stream->commit;

  my $obj = $stream->current;
  if(ref $obj eq 'TestObject') {
    if(exists $obj->{description} && $obj->{description} =~ /Foo/) {
      $stream->regret;
      return 1;
    }
  }
  
  $stream->rollback;
  return 0;
}

package main;

my $stream = Array::Stream::Transactional->new([bless({description => "This is not a test"}, "TestObject"),
						bless({description => "Foo me!"}, "TestObject"),
						bless({text => "Foo you!"},"TestObject"),
						bless({description => "This shouldn't match"}, "NotTestObject"),
						bless({description => "Foo Bar Baz"},"TestObject")]);

{
  $stream->reset;
  my $ok_2 = 0;
  my $matcher = Array::Stream::Transactional::Matcher->new(rules => [["MyRule", sub { $ok_2++; }]]);
  $matcher->match($stream);
  ok($ok_2 == 2);
}
