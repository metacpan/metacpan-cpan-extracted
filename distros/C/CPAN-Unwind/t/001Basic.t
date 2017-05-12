######################################################################
# Test suite for CPAN::Unwind
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More qw(no_plan);
BEGIN { use_ok('CPAN::Unwind') };

#use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({layout => "%F{1}:%L %m%n", level => $DEBUG});

use Cache::FileCache;
use File::Temp qw(tempdir);

my $dirname = tempdir(CLEANUP => 1);

my $cache = Cache::FileCache->new(
{
    cache_root          => $dirname,
    namespace           => "cpan_depend",
    default_expires_in  => 3600*24*30,
});

my $agent = CPAN::Unwind->new(
    cache => $cache,
);
    
my $resp = $agent->lookup("Acme::Prereq::A");
die $resp->message() unless $resp->is_success();
    
my $deps = $resp->dependent_versions();
    
ok(exists $deps->{"Acme::Prereq::B"}, "Acme::Prereq::A dependency");

eval { $resp->schedule() };

like($@, qr/determine schedule/, "Circular dependency");

#############################
# Module without dependencies
#############################
$agent = CPAN::Unwind->new(
    cache => $cache,
);
    
my $wanted = "File::Basename";

$resp = $agent->lookup("$wanted");
ok($resp->is_success, "$wanted");
    
$deps = $resp->dependent_versions();
    
is(join(' ', keys %$deps), "", "$wanted dependencies (none)");

my @sched = $resp->schedule();

  # Empty schedule, because File::Basename comes with perl core
is("@sched", "", "$wanted Schedule");
