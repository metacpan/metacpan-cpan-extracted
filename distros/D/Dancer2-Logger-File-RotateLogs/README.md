# NAME

Dancer2::Logger::File::RotateLogs - an automated logrotate.

# SYNOPSIS

    # development.yml or production.yml
    logger: "File::RotateLogs"

    # options (It's possible to omit)
    engines:
      logger:
        File::RotateLogs:
          logfile: '/[absolute path]/logs/error.log.%Y%m%d%H'
          linkname: '/[absolute path]/logs/error.log'  
          rotationtime: 86400
          maxage: 86400 * 7 
        

# DESCRIPTION

This module allows you to initialize File::RotateLogs within the application's configuration. 
File::RotateLogs is utility for file logger and very simple logfile rotation. 

# SEE ALSO

- [File::RotateLogs](https://metacpan.org/pod/File::RotateLogs)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masaaki Saito <masakyst.public@gmail.com>
