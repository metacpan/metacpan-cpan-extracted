package My::ModuleBuild;
use parent 'Alien::Base::ModuleBuild';

sub alien_check_installed_version {
    return 0;
}

sub alien_check_built_version { '1.0.27' }

1;
