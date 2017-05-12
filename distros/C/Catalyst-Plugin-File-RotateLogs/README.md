# NAME

Catalyst::Plugin::File::RotateLogs - Catalyst Plugin for File::RotateLogs

# SYNOPSIS

    # plugin is loaded
    use Catalyst qw/ 
        ConfigLoader
        Static::Simple
        File::RotateLogs
    /;

    $c->log->info("hello catalyst"); 

    # Catalyst configuration by default (e. g. in YAML format):
    File::RotateLogs:
        logfile: '/[absolute path]/root/error.log.%Y%m%d%H' 
        linkname: '/[absolute path]/root/error.log'
        rotationtime: 86400
        maxage: 86400 * 3
        autodump: 0

# DESCRIPTION

This module allows you to initialize File::RotateLogs within the application's configuration. File::RotateLogs is utility for file logger and very simple logfile rotation. I wanted easier catalyst log rotation.

# SEE ALSO

- [Catalyst::Log](https://metacpan.org/pod/Catalyst::Log)
- [File::RotateLogs](https://metacpan.org/pod/File::RotateLogs)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

masakyst <masakyst.public@gmail.com>
