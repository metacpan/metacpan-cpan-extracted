use strict;
use warnings;
use Test::More tests => 8;
use App::cpanminus::reporter;

package MyReporter;
sub new  { bless {}, 'MyReporter' }
sub send { Test::More::pass 'report sent' }

package MyClient;
sub new   { bless {}, 'MyClient' }
sub grade { Test::More::pass 'client "grade" called'; 1 }
sub email { Test::More::pass 'client "email" called'; 1 }
sub via   { Test::More::pass 'client "via" called'; 1   }

package main;
my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
    force          => 1, # ignore mtime check on build.log
    build_logfile  => $dir . 'build.single.log',
    quiet          => 1,
    'skip-history' => 1,
    'ignore-versions' => 1,
), 'created new reporter object';

is $reporter->quiet, 1, 'reporter is quiet';

{
  no warnings 'redefine';
  local *CPAN::Testers::Common::Client::new = sub { fail 'CTCC called.' };
  local *Test::Reporter::new = sub { fail 'Test::Reporter called' };
  use warnings 'redefine';
  is(
     $reporter->make_report('http://site.org', 'Local-Dist'),
     undef,
     'Local-* dists are ignored'
  );

  is(
      $reporter->make_report('http://site.org/authors/id/L/LO/LOCAL/Some-Dist-1.0.tar.gz', 'Some-Dist'),
      undef,
      'LOCAL user is ignored'
  );

  no warnings 'redefine';
  local *CPAN::Testers::Common::Client::new = *MyClient::new;
  local *Test::Reporter::new = *MyReporter::new;
  use warnings 'redefine';

  # if all went well, this should trigger the extra 'pass' calls
  $reporter->make_report(
      'http://site.net/authors/id/R/RI/RIBASUSHI/local-lib-3.0.tar.gz',
      'local-lib',
  );
};

