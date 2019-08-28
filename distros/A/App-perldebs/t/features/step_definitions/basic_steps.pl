use strict;
use warnings;

use Test::More;
use Test::BDD::Cucumber::StepFile;

use Carp;

my $output;

Given qr{there is a cpanfile} => sub {

    # assert that it's still there
    croak 'cpanfile is missing' unless -f 'cpanfile';
};

When qr{the program is run} => sub {
    $output = `perl -Ilib bin/perldebs`;
};

Then qr{the package names are printed} => sub {
    is $output,
'dh-make-perl libdist-zilla-app-command-cover-perl libdist-zilla-perl libdist-zilla-perl libdist-zilla-perl libdist-zilla-perl libdist-zilla-perl libdist-zilla-perl libdist-zilla-perl libdist-zilla-perl libdist-zilla-perl libdist-zilla-plugin-git-perl libdist-zilla-plugin-installguide-perl libdist-zilla-plugin-podweaver-perl libdist-zilla-plugin-readmefrompod-perl libdist-zilla-plugin-test-notabs-perl libdist-zilla-plugin-test-perl-critic-perl libmodule-cpanfile-perl libmoo-perl libpod-markdown-perl libtest-bdd-cucumber-perl';
};
