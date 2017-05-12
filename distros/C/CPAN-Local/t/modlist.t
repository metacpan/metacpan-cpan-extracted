use strict;
use warnings;

use Test::Most;
use File::Temp qw(tempdir);
use CPAN::Local::Plugin::ModList;

my $repo_root = tempdir;

my $plugin = CPAN::Local::Plugin::ModList->new(
    root => $repo_root,
    distribution_class => 'CPAN::Local::Distribution',
);

isa_ok( $plugin, 'CPAN::Local::Plugin::ModList' );

$plugin->initialise;

my $index = CPAN::Index::API::File::ModList->read_from_repo_path($repo_root);

isa_ok( $index, 'CPAN::Index::API::File::ModList' );

is ( $index->module_count, 0, 'modlist is empty' );

done_testing;
