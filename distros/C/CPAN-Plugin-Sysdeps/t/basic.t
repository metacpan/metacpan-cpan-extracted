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
				       ID => 'X/XX/XXX/Cairo-1.0.tar.gz',
				       CONTAINSMODS => { Cairo => undef },
				      );
ok !$p->{_mapper_ran}, 'mapper did not yet ran';
$p->post_get($cpandist);
ok $p->{_mapper_ran}, 'mapper ran';
is $p->_dist_get_base_id($cpandist), 'Cairo-1.0', '_get_base_id call';
