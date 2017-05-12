use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";
use TestUtil;

use Test::More;
use CPAN::Plugin::Sysdeps ();
require_CPAN_Distribution;

my $cpandist = CPAN::Distribution->new(
				       ID => 'X/XX/XXX/Cairo-1.0.tar.gz',
				       CONTAINSMODS => { Cairo => undef },
				      );

my $p = eval { CPAN::Plugin::Sysdeps->new('batch', 'dryrun', "mapping=$FindBin::RealBin/mapping/code.pl") };
plan skip_all => "Construction failed: $@", 1 if !$p;
skip_on_darwin_without_homebrew;
plan 'no_plan';

$p->post_get($cpandist);
pass 'traverse only did not fail';
