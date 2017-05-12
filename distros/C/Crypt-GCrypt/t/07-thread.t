# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 07-thread.t'

#########################

use strict;
use warnings;
use Config;
use Test::More;
use ExtUtils::testlib;
use Crypt::GCrypt;

#########################

my @algos = qw(aes twofish blowfish arcfour cast5 des serpent seed);
my @available_algos;

if ($Config{useithreads} && eval "use threads; use Thread::Queue; 1") {
  # test as many algorithms as we have.
  @available_algos = grep Crypt::GCrypt::cipher_algo_available($_), @algos;
  plan tests => 3 * @available_algos;

} else {
  plan skip_all => "Skipping because your perl is not compiled with thread support";
}

my $str = 'Four Score and Seven years ago, our fore-monkeys created a great blah blah blah';
my $key = 'monkeymonkeymonkey';

sub nonthreadtest {
  my $algo = shift;
  my $enc = Crypt::GCrypt->new(
                               type => 'cipher',
                               algorithm => $algo,
                               #mode => 'cbc',
                               #padding => 'null'
                              );
  $enc->start('encrypting');
  $enc->setkey($key);

  my $dec = Crypt::GCrypt->new(
                               type => 'cipher',
                               algorithm => $algo,
                               #mode => 'cbc',
                               #padding => 'null'
                              );
  $dec->start('decrypting');
  $dec->setkey($key);

  my $out = '';

  my $buf = $enc->encrypt($str);
  $out .= $dec->decrypt($buf) if (length($buf)); # should we need to test this length() ?
  $buf = $enc->finish();
  $out .= $dec->decrypt($buf) if (length($buf)); # should we need to test this length() ?
  $out .= $dec->finish();

  warn sprintf("Non-threaded: Failed to match output with algorithm '%s'\n", $algo) if ($str ne $out);
  return ($str eq $out);
}


sub producer_thread {
  my $q = shift;
  my $algo = shift;
  my $enc = Crypt::GCrypt->new(
                               type => 'cipher',
                               algorithm => $algo,
                               #mode => 'cbc',
                               #padding => 'null'
                              );
  $enc->start('encrypting');
  $enc->setkey($key);
  $q->enqueue($enc->encrypt($str));
  $q->enqueue($enc->finish());
  $q->enqueue(undef);
  return 1;
}

sub consumer_thread {
  my $q = shift;
  my $algo = shift;
  my $dec = Crypt::GCrypt->new(
                               type => 'cipher',
                               algorithm => $algo,
                               #mode => 'cbc',
                               #padding => 'null'
                              );
  $dec->start('decrypting');
  $dec->setkey($key);
  my $buf;
  my $out = '';
  do {
    $buf = $q->dequeue();
    $out .= $dec->decrypt($buf) if (defined $buf);
  } while (defined $buf);
  $out .= $dec->finish();
  warn sprintf("Threaded: failed to match output with algorithm '%s'\n".
         "Wanted: %s\n   Got: %s\n", $algo, unpack('H*', $str),
         unpack('H*', $out)) if ($str ne $out);
  return $str eq $out;
}


sub testalgo {
  my $algo = shift;

  ok(nonthreadtest($algo));

  my $queue = Thread::Queue->new();

  # create in scalar context so that the result is the returned scalar:
  my $con = threads->create('consumer_thread', $queue, $algo);
  my $pro = threads->create('producer_thread', $queue, $algo);
}


testalgo($_) for @available_algos;
ok($_->join()) for threads->list();




