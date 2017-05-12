# NAME

Data::PathSimple - Navigate and manipulate data structures using paths

# SYNOPSIS

    use Data::PathSimple qw{
      get
      set
    };
    
    my $data = {
      Languages => {
        Perl   => {
          CurrentVersion => '5.16.1',
          URLs           => [
            'http://www.perl.org',
            'http://www.cpan.org',
          ],
        },
        PHP    => {
          CurrentVersion => '5.4.7',
          URLs           => [
            'http://www.php.net',
            'http://pear.php.net',
          ],
        },
        Python => {
          CurrentVersion => '2.7.3',
          URLs           => [
            'http://www.python.org',
          ],
        },
      },
    };

    my $current_perl = get( $data, '/Languages/Perl/CurrentVersion' );
    my @perl_urls    = @{ get( $data, '/Languages/Perl/URLs' ) || [] };
    
    set( $data, '/Languages/Perl/CurrentVersion', '5.16.2' );
    set( $data, '/Languages/Python/URLs/1/', 'http://pypi.python.org' );

# DESCRIPTION

Data::PathSimple allows you to get and set values deep within a data structure
using simple paths to navigate (think XPATH without the steroids).

Why do this when we already have direct access to the data structure? The
motivation is that the path will come from a user using a command line tool.

# SEE ALSO

The latest version can be found at:

&nbsp;&nbsp;&nbsp;&nbsp;[https://github.com/alfie/Data-PathSimple](https://github.com/alfie/Data-PathSimple)

Watch the repository and keep up with the latest changes:

&nbsp;&nbsp;&nbsp;&nbsp;[https://github.com/alfie/Data-PathSimple/subscription](https://github.com/alfie/Data-PathSimple/subscription)

# SUPPORT

Please report any bugs or feature requests at:

&nbsp;&nbsp;&nbsp;&nbsp;[https://github.com/alfie/Data-PathSimple/issues](https://github.com/alfie/Data-PathSimple/issues)

Feel free to fork the repository and submit pull requests :)

# INSTALLATION

To install this module type the following:

    perl Makefile.PL
    make
    make test
    make install

# DEPENDENCIES

* Perl v5.10.0

# AUTHOR

[Alfie John](https://github.com/alfie) &lt;[alfiej@opera.com](mailto:alfiej@opera.com)&gt;

# WARRANTY

IT COMES WITHOUT WARRANTY OF ANY KIND.

# COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alfie John

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
