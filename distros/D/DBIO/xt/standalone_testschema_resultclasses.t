use warnings;
use strict;

BEGIN { delete $ENV{DBIO_TEST_VERSION_WARNS_INDISCRIMINATELY} }

use Config;
use DBIO::Util 'sigwarn_silencer';
use if !$Config{d_fork}, 'threads';

use Test::More;
use File::Find;
use Time::HiRes 'sleep';

use lib qw(lib t/lib);

my $worker = sub {
  my $fn = shift;

  if (my @offenders = grep { $_ !~ m{DBIO/(?:Util|_Util|Carp)\.pm} } grep { $_ =~ /(^|\/)DBI/ } keys %INC) {
    die "Wtf - DBI* modules present in %INC: @offenders";
  }

  local $SIG{__WARN__} = sigwarn_silencer( qr/\bdeprecated\b/i );
  require( ( $fn =~ m{ (?:t/lib|lib)/ (.+) }x )[0] ); # untaint and strip lib-part (. is unavailable under -T)

  return 42;
};


find({
  wanted => sub {

    return unless ( -f $_ and $_ =~ /\.pm$/ );

    if (!$Config{d_fork}) {
      # older perls crash if threads are spawned way too quickly, sleep for 100 msecs
      my $t = threads->create(sub { $worker->($_) });
      sleep 0.1;
      is ($t->join, 42, "Thread loading $_ did not finish successfully")
        || diag ($t->can('error') ? $t->error : 'threads.pm too old to retrieve the error :(' );
    }
    else {
      my $pid = fork();
      if (! defined $pid) {
        die "fork failed: $!"
      }
      elsif (!$pid) {
        $worker->($_);
        exit 0;
      }

      is ( waitpid($pid, 0), $pid, "Fork $pid terminated sucessfully");
      my $ex = $? >> 8;
      is ( $ex, 0, "Loading $_ ($pid) exitted with $ex" );
    }
  },

  no_chdir => 1,
}, 'lib/DBIO/Test/Schema/');

done_testing;
