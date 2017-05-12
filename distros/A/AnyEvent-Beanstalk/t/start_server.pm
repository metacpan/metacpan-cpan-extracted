use strict;
use warnings;
package t::start_server;

use Test::Builder;
use AnyEvent::Beanstalk;

our @ISA = qw(Exporter);
our @EXPORT = qw(get_client);

my $exe  = $ENV{BEANSTALKD_EXE};
my $port = $ENV{BEANSTALKD_PORT} || 11300;

sub get_client { AnyEvent::Beanstalk->new(server => "localhost:$port"); }

my $builder = Test::Builder->new();

unless ($exe) {
  ($exe) = grep { -x $_ } qw(/opt/local/bin/beanstalkd /usr/local/bin/beanstalkd /usr/bin/beanstalkd);
}

unless ($exe && -x $exe) {
  $builder->plan(skip_all => 'Set environment variable BEANSTALKD_EXE & BEANSTALKD_PORT to run live tests');
}

$SIG{CHLD} = 'IGNORE';
if (my $pid = fork()) {
  END { kill 9, $pid if $pid }
  sleep(2);
  $builder->plan(skip_all => "Cannot start server: $!")
    unless kill 0, $pid;
  $builder->note('Started test beanstalkd server');
}
elsif (defined $pid) {
  exec($exe, '-p', $port);
  die("Cannot exec $exe: $!\n");
}
else {
  $builder->plan(skip_all => "Cannot fork: $!");
}
1;
