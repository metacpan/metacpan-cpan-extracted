package TestFunctions;

use warnings;
use strict;

use App::SCM::Digest::Utils qw(system_ad);

use base qw(Exporter);
our @EXPORT_OK = qw(initialise_git_repository initialise_git_clone);

sub initialise_git_repository
{
    system_ad("git init-db");
    initialise_git_clone();
}

sub initialise_git_clone
{
    system_ad('git config user.name "App::SCM::Digest"');
    system_ad('git config user.email "user@example.org"');
}

1;
