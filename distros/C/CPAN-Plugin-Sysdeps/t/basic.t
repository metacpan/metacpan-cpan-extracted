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
is_deeply $p->{_mapper_ran}, {}, 'mapper did not yet ran';

{
    my $cpandist = CPAN::Distribution->new(
	ID => 'X/XX/XXX/Cairo-1.0.tar.gz',
	CONTAINSMODS => { Cairo => undef },
    );
    $p->post_get($cpandist);
    ok $p->{_mapper_ran}{"X/XX/XXX/Cairo-1.0.tar.gz"}, 'mapper ran for Cairo-1.0';
    is $p->_dist_get_base_id($cpandist), 'Cairo-1.0', '_get_base_id call';
}

{
    my $cpandist = CPAN::Distribution->new(
	ID => 'X/XX/XXX/Pango-1.0.tar.gz',
	CONTAINSMODS => { Pango => undef },
    );
    $p->post_get($cpandist);
    ok $p->{_mapper_ran}{"X/XX/XXX/Pango-1.0.tar.gz"}, 'mapper ran for Pango-1.0';
    is $p->_dist_get_base_id($cpandist), 'Pango-1.0', '_get_base_id call for 2nd module';
}
