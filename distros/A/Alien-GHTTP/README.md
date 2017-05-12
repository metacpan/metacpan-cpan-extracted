# NAME

Alien::GHTTP - (DEPRECATED) Easy installation of the GNOME libghttp library

# SYNOPSIS

    # Build.PL
    use Alien::GHTTP;
    use Module::Build 0.28; # need at least 0.28

    my $builder = Module::Build->new(
      configure_requires => {
        'Alien::GHTTP' => '0.005',
      },
      ...
      extra_compiler_flags => Alien::GHTTP->cflags,
      extra_linker_flags   => Alien::GHTTP->libs,
      ...
    );

    $builder->create_build_script;


    # lib/MyLibrary/GHTTP.pm
    package MyLibrary::GHTTP;

    use Alien::GHTTP; # dynaload libghttp

    ...

# DESCRIPTION

Provides the GNOME libghttp
[http://ftp.gnome.org/pub/gnome/sources/libghttp](http://ftp.gnome.org/pub/gnome/sources/libghttp) (GHTTP) for use by Perl modules, installing it if necessary.
This module relies heavily on the [Alien::Base](https://metacpan.org/pod/Alien::Base) system to do so.

Note that the **end of life** for this particular library was way, way back in 2002.

You have been warned.  Please use some other library.

# SEE ALSO

- [Alien::Base](https://metacpan.org/pod/Alien::Base)

# SOURCE REPOSITORY

[https://github.com/genio/alien-ghttp](https://github.com/genio/alien-ghttp)

# AUTHOR

Chase Whitener, <capoeirab@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2016 by Chase Whitener

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
