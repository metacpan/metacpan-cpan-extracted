package My::Build;

use strict;
use base qw(Module::Build);
use Config;
use File::Spec;

our @ISA;
$main::NO_INIT = $main::NO_INIT; # no warnings...

sub awx_get_package {
    local $_ = $Config{osname};

    # Win32
    /MSWin32/ and return 'Win32';
    # MacOS X is slightly different...
    /darwin/ and return 'MacOSX_wx_config';
    # default
    return 'Any_wx_config';
}

BEGIN {
    my $package = 'My::Build';

    # iterate until fixed point
    for( ; !$main::NO_INIT; ) {
        my $full_package = 'My::Build::' . $package->awx_get_package;
        last if $package eq $full_package;

        my $file = $full_package . '.pm'; $file =~ s{::}{/}g;

        require $file;
        @ISA = ( $full_package );
        $package = $full_package;
    }
}

1;
