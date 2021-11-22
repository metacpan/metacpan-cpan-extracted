# NAME

API::Mathpix - Use the API of Mathpix

# VERSION

Version 0.01

# SYNOPSIS

    my $mathpix = API::Mathpix->new({
      app_id  => $ENV{MATHPIX_APP_ID},
      app_key => $ENV{MATHPIX_APP_KEY},
    });

    my $response = $mathpix->process({
      src     => 'https://mathpix.com/examples/limit.jpg',
    });

    print $response->text;

# EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

# SUBROUTINES/METHODS

## process

# AUTHOR

Eriam Schaffter, `<eriam at mediavirtuel.com>`

# BUGS & SUPPORT

Please go directly to Github

    https://github.com/eriam/API-Mathpix

# LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Eriam Schaffter.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
