use warnings;
use Test::More;
use Data::Dumper;
use Capture::Tiny qw/capture_stderr/;



BEGIN { 
  use Config;
  plan skip_all => "Perl not compiled with 'useithreads'\n"
    if ( !$Config{'useithreads'} );
  plan skip_all => "no threads available"
    unless( eval 'use threads; 1' );

  use_ok("Bio::Gonzales::Util::Log"); }

my $l = Bio::Gonzales::Util::Log->new();


my $stderr = capture_stderr {
$l->debug("testdebug");
};

like($stderr, qr/^\[\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\] \[DEBUG\] \[t0\] testdebug$/, "log debug test");

done_testing();

