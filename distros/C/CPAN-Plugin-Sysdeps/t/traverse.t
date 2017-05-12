use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";
use TestUtil;

use Test::More 'no_plan';
use CPAN::Plugin::Sysdeps ();
require_CPAN_Distribution;

my $cpandist = CPAN::Distribution->new(
				       ID => 'X/XX/XXX/DummyDoesNotExist-1.0.tar.gz',
				       CONTAINSMODS => { DummyDoesNotExist => undef },
				      );

{
    my $p = CPAN::Plugin::Sysdeps->new('apt-get', 'batch', 'dryrun');
    local $CPAN::Plugin::Sysdeps::TRAVERSE_ONLY = 1;
    $p->post_get($cpandist);
    pass 'traverse only did not fail';
}

{
    my $p = CPAN::Plugin::Sysdeps->new('apt-get', 'batch', 'dryrun', "mapping=$FindBin::RealBin/mapping/fail_likelinuxdistro.pl");
    local $CPAN::Plugin::Sysdeps::TRAVERSE_ONLY = 1;
    eval { $p->post_get($cpandist) };
    like $@, qr{'like' matches only for };
}
