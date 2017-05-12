#!/usr/bin/env perl
use feature ':5.10';
use Test::More;
use lib 'lib';
use File::Path qw(rmtree mkpath);
use Apache::SiteConfig;
use Apache::SiteConfig::Template;
use Apache::SiteConfig::Deploy;

# default template
my $deploy = Apache::SiteConfig::Deploy->new;

$deploy->{args} = {
    name         => 'foo',
    domain       => 'foo.com',
    domain_alias => 'bar.com',
    sites_dir    => 'testing_root',
    git          => 'git://github.com/c9s/c9s.github.com.git',
};
$deploy->deploy();

ok( -e 'testing_root/foo' );
rmtree 'testing_root';


done_testing;
