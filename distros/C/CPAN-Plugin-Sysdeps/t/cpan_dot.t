# emulate "cpan ." operation

use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";
use TestUtil;

use Test::More;
use CPAN::Plugin::Sysdeps ();
require_CPAN_Distribution;

my $p = eval { CPAN::Plugin::Sysdeps->new('batch', 'dryrun') };
plan skip_all => "Construction failed: $@", 1 if !$p;
skip_on_darwin_without_homebrew;
plan 'no_plan';

isa_ok $p, 'CPAN::Plugin::Sysdeps';
my $cpandist = CPAN::Distribution->new(
    "CALLED_FOR" => "/home/user/src/CPAN/XML-Parser/.",
    "CONTAINSMODS" => {},
    "ID" => "/home/user/src/CPAN/XML-Parser/.",
    "archived" => "local_directory",
    "build_dir" => "/home/user/src/CPAN/XML-Parser/.",
    "incommandcolor" => 1,
    "mandatory" => !!1,
    "negative_prefs_cache" => 0,
    "prefs" => {},
    "reqtype" => "c",
    "unwrapped" => bless( {
	"COMMANDID" => 0,
	"FAILED" => !!0,
	"TEXT" => "YES -- local_directory",
	"TIME" => 1777023381
    }, 'CPAN::Distrostatus'),
);
ok !$p->{_mapper_ran}, 'mapper did not yet ran';
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    $p->pre_make($cpandist);
    like "@warnings", qr{\QWARNING: running in local directory '/home/user/src/CPAN/XML-Parser/.'}, 'found warning about local directory';
    like "@warnings", qr{\QCPAN_PLUGIN_SYSDEPS_MODULE}, 'found environment variable in warning message';
    is $p->_dist_get_base_id($cpandist), '.', '_dist_get_base_id indicates local directory';
    is_deeply [$p->_dist_containsmods($cpandist)], [], 'no containsmods found';
}
ok $p->{_mapper_ran}, 'mapper ran';
undef $p;

{
    my $p2 = CPAN::Plugin::Sysdeps->new('batch', 'dryrun');
    ok !$p2->{_mapper_ran}, 'mapper did not yet ran';
    local $ENV{CPAN_PLUGIN_SYSDEPS_MODULE} = 'XML::Parser';
    {
	my @warnings;
	local $SIG{__WARN__} = sub {
	    push @warnings, grep { !/DRYRUN:/ } @_; # ignore the possible message about installing libexpat
	};
	$p2->pre_make($cpandist);
	is_deeply \@warnings, [], 'no warnings if env var is defined';
	is $p2->_dist_get_base_id($cpandist), '.', '_dist_get_base_id still indicates local directory'; # may change if something like CPAN_PLUGIN_SYSDEPS_DIST_ID or so was implemented and used
	is_deeply [$p2->_dist_containsmods($cpandist)], ['XML::Parser'], 'found injected module in containsmods';
    }
    ok $p2->{_mapper_ran}, 'mapper ran';
}
