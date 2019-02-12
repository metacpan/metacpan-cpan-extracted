package App::DTWMIC;


use strict;
use warnings;

use utf8;

use 5.008_005;

our $VERSION = '0.002';



1;



__END__

=encoding utf-8

=head1 NAME

dtwmic - disable touchpad when a mouse is connected

=head1 INSTALL

    curl -L https://cpanmin.us | perl - App::DTWMIC

Note: you may wish to install a package like libffi-platypus-perl on your distro
to fast installation

=head1 SYNOPSIS

    dtwmic [OPTIONS]
    dtwmic f | config-file=CUSTOM_CONFIG_FILE_PATH
    
    h | help    - show help
    v | version - show dtwmic version
    l | list    - list mouse/touchpad devices

=head1 DESCRIPTION

Add dtwmic to your X window manager autostart.

A default configuration file is created on the first run in
~/.config/dtwmic/config.yml (if not exists).

You need synclient or xinput by default otherwise edit the config.

=head1 BUGS

Please report any bugs through the web interface at
L<https://github.com/Ilya33/App-DTWMIC/issues>. Patches are always welcome.

=head1 AUTHOR

Ilya Pavlov E<lt>ilux@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Ilya Pavlov

=head1 LICENSE

GNU Lesser General Public License v2.1

=cut