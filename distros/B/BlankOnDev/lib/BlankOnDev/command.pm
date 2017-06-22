package BlankOnDev::command;
use strict;
use warnings FATAL => 'all';

# Import :
use Term::ReadKey;
use BlankOnDev::Rilis;

# Version :
our $VERSION = '0.1005';

# Subroutine for bazaar command :
# ------------------------------------------------------------------------
sub bzr {
    my %data = ();

    # Bzr Command :
    $data{'bzr'} = {
        'branch'          => => 'bzr branch',
        'bzr-export'      => 'bzr fast-export',
        'bzr-fast-import' => 'git fast-import'
    };
    return \%data;
}
# Subroutine for github command :
# ------------------------------------------------------------------------
sub github {
    my %data = ();

    # Git Command :
    $data{'git'} = {
        'cfg-name' => 'git config --global user.name',
        'cfg-email' => 'git config --global user.email',
        'cfg-credential-cache' => 'git config --global credential.helper cache',
        'cfg-creden-cache-clear' => 'git config --global --unset credential.helper',
        'cfg-list' => 'git config --list',
        'cfg-list' => 'git config --list',
        'init' => 'git init',
        'add' => 'git add',
        'commit' => 'git commit -m',
        'reset-head' => 'git reset HEAD',
        'remote' => 'git remote add origin',
        'push' => 'git push -u origin master',
        'push-force' => 'git push origin master --force',
        'push-repo' => 'git push -u origin',
        'checkout' => 'git checkout -b',
        'fetch' => 'git fetch origin',
        'merge' => 'git merge origin origin/master',
        'pull' => 'git pull origin',
        'branch' => 'git branch',
    };
    return \%data;
}
1;