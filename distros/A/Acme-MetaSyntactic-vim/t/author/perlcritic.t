#!perl

use Test::Perl::Critic (-severity => 1, -profile => 't/author/perlcriticrc' );
use Module::Build;
use File::Spec::Functions;


my $build;

BEGIN {
    $build = Module::Build->current();
} # end BEGIN

all_critic_ok(
    map { catfile($build->base_dir(), $_) } qw{ lib script examples }
);

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=0 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
