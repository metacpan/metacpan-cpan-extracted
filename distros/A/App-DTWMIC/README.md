# NAME

dtwmic - disable touchpad when a mouse is connected

# INSTALL

    curl -L https://cpanmin.us | perl - App::DTWMIC

Note: you may wish to install a package like libffi-platypus-perl on your distro
to fast installation

# SYNOPSIS

    dtwmic [OPTIONS]
    dtwmic f | config-file=CUSTOM_CONFIG_FILE_PATH
    
    h | help    - show help
    v | version - show dtwmic version
    l | list    - list mouse/touchpad devices

# DESCRIPTION

Add dtwmic to your X window manager autostart.

A default configuration file is created on the first run in
~/.config/dtwmic/config.yml (if not exists).

You need synclient or xinput by default otherwise edit the config.

# BUGS

Please report any bugs through the web interface at
[https://github.com/Ilya33/App-DTWMIC/issues](https://github.com/Ilya33/App-DTWMIC/issues). Patches are always welcome.

# AUTHOR

Ilya Pavlov <ilux@cpan.org>

# COPYRIGHT

Copyright 2019- Ilya Pavlov

# LICENSE

GNU Lesser General Public License v2.1
