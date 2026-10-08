use strict;
use warnings;

use Test::More;
use Test::Differences;

use CPAN::FindDependencies 'finddeps';

my $private_repo = 't/mirrors/privatemirror';
my $cachedir     = 't/cache/multi';
my($private_repo_url, $cachedir_url) = map { URI::file->new_abs($_) }
    ($private_repo, $cachedir);

# just in case they're cached from a previous test run that crashed
unlink(map { "t/cache/multi/$_" } qw(Brewery-1.0.meta Fruit-1.0.meta Fruit-Role-Fermentable-1.0.meta));

sub multi_repo_find {
    eq_or_diff(
        [
            map {
                $_->name() => [$_->depth(), $_->distribution(), $_->warning()?1:0]
            } finddeps(
                'Brewery',
                mirror   => $private_repo,
                mirror   => 'DEFAULT,t/cache/multi/02packages.details.txt.gz',
                perl     => '5.28.0',
                cachedir => $cachedir
            )
        ],
        [
            Brewery         => [0, 'F/FR/FRUITCO/Brewery-1.0.tar.gz', 0],
            'Fruit'         => [1, 'F/FR/FRUITCO/Fruit-1.0.tar.bz2', 0],
            'Capture::Tiny' => [2, 'D/DA/DAGOLDEN/Capture-Tiny-0.48.tar.gz', 0],
            'File::Temp'    => [2, 'E/ET/ETHER/File-Temp-0.2311.tar.gz', 0],
            'Fruit::Role::Fermentable' => [1, 'F/FR/FRUITCO/Fruit-Role-Fermentable-1.0.zip', 0]
        ],
        "Fetch deps from both a private repo $private_repo and a public one"
    );
}

multi_repo_find();
eq_or_diff(
    \@CPAN::FindDependencies::net_log,
    [
        $private_repo_url.'/modules/02packages.details.txt.gz',
        $cachedir_url.'/02packages.details.txt.gz',
        $private_repo_url.'/authors/id/F/FR/FRUITCO/Brewery-1.0.meta',
        $private_repo_url.'/authors/id/F/FR/FRUITCO/Brewery-1.0.tar.gz',
        $private_repo_url.'/authors/id/F/FR/FRUITCO/Fruit-1.0.meta',
        $private_repo_url.'/authors/id/F/FR/FRUITCO/Fruit-1.0.tar.bz2',
        $private_repo_url.'/authors/id/F/FR/FRUITCO/Fruit-Role-Fermentable-1.0.meta',
        $private_repo_url.'/authors/id/F/FR/FRUITCO/Fruit-Role-Fermentable-1.0.zip'
    ],
    "network traffic was as expected when the private repo isn't already cached"
);

multi_repo_find();
eq_or_diff(
    \@CPAN::FindDependencies::net_log,
    [],
    "less network traffic when the private repo is cached (and so is 02packages)"
);

# so they don't confuse matters
unlink(map { "t/cache/multi/$_" } qw(Brewery-1.0.meta Fruit-1.0.meta Fruit-Role-Fermentable-1.0.meta));

done_testing;
