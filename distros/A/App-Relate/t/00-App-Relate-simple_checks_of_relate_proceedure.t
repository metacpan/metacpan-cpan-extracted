# A perl test file, which can be run like so:
#   `perl 00-App-Relate-simple_checks_of_relate_proceedure.t'
#         doom@kzsu.stanford.edu     2010/03/15 20:27:48

# Tests App::Relate directly, doesn't try to use the 'relate' script.
# uses the test_data feature to suppress calls to an external 'locate'

use warnings;
use strict;
$|=1;
my $DEBUG = 1;             # TODO set to 0 before ship
use Data::Dumper;

use Test::More;
BEGIN { plan tests => 6 }; # TODO revise test count

use FindBin qw( $Bin );
use lib "$Bin/../lib";

my $module;
BEGIN {
  $module = 'App::Relate';
  use_ok( $module, ':all' );
}

my $skipdull = ['~$', '/\#', '\.\#', ',v$', '/RCS$', '/CVS/', '/CVS$', '\.elc$' ];

{
  my $test_name = "Testing relate single search term, plus filter.";
   my $results =
      relate( [ 'whun' ], $skipdull,
        { test_data => [ '/tmp/whun',
                        '/tmp/tew',
                        '/tmp/thruee',
                        '/etc/whun',
                        '/etc/RCS/whun,v',
                     ],
          } );

  my $expected = ['/etc/whun', '/tmp/whun'];

  my $results_sorted  = [ sort( @{ $results } ) ];
  my $expected_sorted = [ sort( @{ $expected } ) ];

  is_deeply( $results_sorted, $expected_sorted, $test_name );
}

{
  my $test_name = "Testing relate double search term, plus filter.";
   my $results =
      relate( [ 'whun', 'etc' ], $skipdull,
        { test_data => [ '/tmp/whun',
                        '/tmp/tew',
                        '/tmp/thruee',
                        '/etc/whun',
                        '/etc/RCS/whun,v',
                     ],
          } );

  my $expected = ['/etc/whun'];

  my $results_sorted  = [ sort( @{ $results } ) ];
  my $expected_sorted = [ sort( @{ $expected } ) ];

  is_deeply( $results_sorted, $expected_sorted, $test_name );
}


{
  my $test_name =
    "Testing relate with negated search term, plus filter.";
   my $results =
      relate( [ 'whun', '-tmp' ], $skipdull,
        { test_data => [ '/tmp/whun',
                        '/tmp/tew',
                        '/tmp/thruee',
                        '/etc/whun',
                        '/etc/RCS/whun,v',
                     ],
          } );

  my $expected = ['/etc/whun'];

  my $results_sorted  = [ sort( @{ $results } ) ];
  my $expected_sorted = [ sort( @{ $expected } ) ];

  is_deeply( $results_sorted, $expected_sorted, $test_name );
}

{
  my $test_name =
    "Testing relate with a regexp search term.";
  my $data = load_data_aref();
   my $results =
      relate( [ 'apache', 'apache2\b' ], [],
        { test_data => $data,
          } );

  my $expected = [
     '/usr/src/apache2/httpd.spec',
     '/usr/src/apache2/docs/manual/bind.html',
     '/usr/sbin/apache2',
  ];

  my $results_sorted  = [ sort( @{ $results } ) ];
  my $expected_sorted = [ sort( @{ $expected } ) ];

  is_deeply( $results_sorted, $expected_sorted, $test_name );
}

{
  my $test_name =
    "Testing relate with a dwim upcaret search term.";
  my $data = load_data_aref();
   my $results =
      relate( [ 'apache', '^bin' ], [],
        { test_data => $data,
          } );

  my $expected = [
     '/usr/src/apache2/docs/manual/bind.html',
  ];

  my $results_sorted  = [ sort( @{ $results } ) ];
  my $expected_sorted = [ sort( @{ $expected } ) ];

  is_deeply( $results_sorted, $expected_sorted, $test_name );
}



# end main, into the subs

sub load_data_aref {

  my $data =
    [
     '/usr/src/apache2/httpd.spec',
     '/usr/src/apache2/docs/manual/bind.html',
     '/usr/sbin/apache2',
     '/usr/sbin/apache2ctl',
     '/var/www/html/index.html',
     '/var/www/html/usage/index.html',
     '/usr/share/texmf-texlive/tex/latex/authorindex',
    ];

  return $data;
}
