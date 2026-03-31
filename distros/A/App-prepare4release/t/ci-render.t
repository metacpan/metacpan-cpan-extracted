#!perl
use strict;
use warnings;
use Test2::V1;
use Test2::Tools::Basic qw(done_testing);
use Test2::Tools::Compare qw(like);

use App::prepare4release;

local $ENV{PREPARE4RELEASE_PERL_MAX} = '5.16';

my $gh = App::prepare4release->render_github_ci_yml(
	[qw( 5.10 5.12 )],
	[qw( libssl-dev )]
);
like( $gh, qr/shogo82148\/actions-setup-perl/, 'GitHub workflow uses actions-setup-perl' );
like( $gh, qr/libssl-dev/,              'apt packages in GitHub YAML' );
like( $gh, qr/perl-version:/, 'matrix perl-version key' );
like( $gh, qr/perl Makefile\.PL/, 'GitHub workflow runs Makefile.PL before installdeps' );
like( $gh, qr/Test2::Suite/,       'GitHub workflow installs Test2::Suite explicitly' );

my $gl = App::prepare4release->render_gitlab_ci_yml(
	[qw( 5.10 5.12 )],
	[] );
like( $gl, qr/parallel:/,     'GitLab parallel' );
like( $gl, qr/PERL_VERSION:/, 'GitLab matrix var' );
like( $gl, qr{image:\s*perl:\$\{PERL_VERSION\}}, 'GitLab perl image' );
like( $gl, qr/Test2::Suite/, 'GitLab installs Test2::Suite explicitly' );

done_testing;
