use strict;
use Test::More;
use Time::HiRes ();
use App::Prove;

plan skip_all => 'ualarm is not implementeed on MSWin32' if $^O eq 'MSWin32';
plan skip_all => 'Need *nix' unless -x 'script/prowess' and $ENV{PATH};

my $prove;
*App::Prove::new = sub { $prove = shift->TAP::Object::new(@_) };
*App::Prove::run = sub { diag 'sleep 0'; return 1 };

my $prowess = do 'script/prowess' or die $@;

$SIG{ALRM} = sub {
  my $curr = (stat __FILE__)[9];
  my $time = $curr + 5 - int rand 10;
  $time-- if $time == $curr;
  diag "utime $time, $time, $0";
  utime $time, $time, __FILE__;
};

$ENV{PROWESS_ONCE} = 1;
Time::HiRes::ualarm(300e3);
is $prowess->run(qw( -w t -l )), 0, 'run once';
ok $prove->lib, 'prove -l';
ok !$prove->verbose, 'prove -l';

Time::HiRes::ualarm(300e3);
*App::Prove::run = sub { diag 'sleep 3'; sleep 3; return 42 };
is $prowess->run(qw( -w t -vl )), 0, 'kill running test';
ok $prove->lib,     'prove -vl';
ok $prove->verbose, 'prove -vl';

done_testing;
